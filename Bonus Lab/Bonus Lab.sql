-- Task 1
CREATE OR REPLACE FUNCTION process_transfer(
    from_account_number TEXT,
    to_account_number TEXT,
    transfer_amount NUMERIC,
    transfer_currency TEXT,
    transfer_description TEXT
)
RETURNS TEXT AS $$
DECLARE
    from_account_id INT;
    to_account_id INT;
    from_balance NUMERIC;
    to_balance NUMERIC;
    from_customer_status TEXT;
    daily_limit NUMERIC;
    exchange_rate NUMERIC;
    amount_in_kzt NUMERIC;
BEGIN

    SELECT account_id, customer_id, balance, is_active
    INTO from_account_id, from_balance, from_customer_status
    FROM accounts
    WHERE account_number = from_account_number AND is_active = TRUE;

    IF NOT FOUND THEN
        RETURN 'Sender account not found or inactive';
    END IF;

    SELECT account_id, balance, is_active
    INTO to_account_id, to_balance
    FROM accounts
    WHERE account_number = to_account_number AND is_active = TRUE;

    IF NOT FOUND THEN
        RETURN 'Recipient account not found or inactive';
    END IF;


    SELECT status INTO from_customer_status
    FROM customers
    WHERE customer_id = (SELECT customer_id FROM accounts WHERE account_id = from_account_id);

    IF from_customer_status != 'active' THEN
        RETURN 'Sender account is not active';
    END IF;


    SELECT daily_limit_kzt INTO daily_limit
    FROM customers
    WHERE customer_id = (SELECT customer_id FROM accounts WHERE account_id = from_account_id);


    DECLARE
        daily_total NUMERIC;
    BEGIN
        SELECT SUM(amount_kzt) INTO daily_total
        FROM transactions
        WHERE from_account_id = from_account_id AND created_at::DATE = CURRENT_DATE;

        IF (daily_total + transfer_amount) > daily_limit THEN
            RETURN 'Exceeds daily transaction limit';
        END IF;
    END;


    IF transfer_currency != 'KZT' THEN
        SELECT rate INTO exchange_rate
        FROM exchange_rates
        WHERE from_currency = transfer_currency AND to_currency = 'KZT' AND valid_from <= CURRENT_DATE AND valid_to >= CURRENT_DATE
        LIMIT 1;

        IF NOT FOUND THEN
            RETURN 'Exchange rate not available for conversion';
        END IF;

        amount_in_kzt := transfer_amount * exchange_rate;
    ELSE
        amount_in_kzt := transfer_amount;
    END IF;


    BEGIN
        SELECT * FROM accounts WHERE account_id = from_account_id FOR UPDATE;
        SELECT * FROM accounts WHERE account_id = to_account_id FOR UPDATE;


        IF from_balance < amount_in_kzt THEN
            RETURN 'Insufficient balance';
        END IF;


        INSERT INTO transactions (from_account_id, to_account_id, amount, currency, exchange_rate, amount_kzt, type, status, created_at, description)
        VALUES (from_account_id, to_account_id, transfer_amount, transfer_currency, exchange_rate, amount_in_kzt, 'transfer', 'pending', CURRENT_TIMESTAMP, transfer_description);


        UPDATE accounts SET balance = balance - amount_in_kzt WHERE account_id = from_account_id;
        UPDATE accounts SET balance = balance + amount_in_kzt WHERE account_id = to_account_id;


        COMMIT;


        INSERT INTO audit_log (table_name, record_id, action, new_values, changed_by, changed_at, ip_address)
        VALUES ('transactions', currval('transactions_transaction_id_seq'), 'INSERT', '{"from_account_id": ' || from_account_id || ', "to_account_id": ' || to_account_id || ', "amount": ' || transfer_amount || '}', 'System', CURRENT_TIMESTAMP, '192.168.1.1');

        RETURN 'Transfer completed successfully';
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RETURN 'Transaction failed: ' || SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- Task 2: customer_balance_summary view
CREATE VIEW customer_balance_summary AS
SELECT
    c.customer_id,
    c.full_name,
    a.account_number,
    a.currency,
    a.balance,
    a.balance * COALESCE(er.rate, 1) AS balance_in_kzt,
    c.daily_limit_kzt,
    ROUND((a.balance * COALESCE(er.rate, 1)) / c.daily_limit_kzt * 100, 2) AS daily_limit_utilization_percentage
FROM
    customers c
JOIN
    accounts a ON c.customer_id = a.customer_id
LEFT JOIN
    exchange_rates er ON a.currency = er.from_currency AND er.to_currency = 'KZT' AND er.valid_from <= CURRENT_DATE AND er.valid_to >= CURRENT_DATE;

-- Task 2: daily_transaction_report view
CREATE VIEW daily_transaction_report AS
SELECT
    created_at::DATE AS transaction_date,
    type,
    COUNT(*) AS transaction_count,
    SUM(amount_kzt) AS total_volume,
    AVG(amount_kzt) AS average_amount,
    SUM(amount_kzt) OVER (ORDER BY created_at::DATE) AS running_total,
    LAG(SUM(amount_kzt)) OVER (ORDER BY created_at::DATE) AS previous_day_total,
    (SUM(amount_kzt) - LAG(SUM(amount_kzt)) OVER (ORDER BY created_at::DATE)) / LAG(SUM(amount_kzt)) OVER (ORDER BY created_at::DATE) * 100 AS day_over_day_growth
FROM
    transactions
WHERE
    created_at::DATE = CURRENT_DATE
GROUP BY
    created_at::DATE, type;

-- Task 2: suspicious_activity_view with security barrier
CREATE VIEW suspicious_activity_view
WITH (security_barrier = true) AS
SELECT
    t.transaction_id,
    t.from_account_id,
    t.to_account_id,
    t.amount_kzt,
    t.created_at,
    CASE
        WHEN t.amount_kzt > 5000000 THEN 'Large Transfer'
        WHEN COUNT(*) OVER (PARTITION BY t.from_account_id ORDER BY t.created_at) > 10 THEN 'Too Many Transactions'
        WHEN EXISTS (SELECT 1 FROM transactions t2 WHERE t2.from_account_id = t.from_account_id AND t2.created_at BETWEEN t.created_at - INTERVAL '1 minute' AND t.created_at) THEN 'Rapid Sequential Transfers'
        ELSE 'Normal'
    END AS transaction_flag
FROM
    transactions t;

-- Task 3: Indexes for Performance Optimization

-- B-tree Index (default for most use cases):
CREATE INDEX idx_accounts_customer_id ON accounts(customer_id);

-- Hash Index (for fast lookups on account numbers):
CREATE INDEX idx_accounts_account_number_hash ON accounts USING HASH(account_number);

-- GIN Index (for JSONB data in audit_log):
CREATE INDEX idx_audit_log_old_values_gin ON audit_log USING GIN(old_values);

-- Partial Index (for active accounts only):
CREATE INDEX idx_active_accounts ON accounts(customer_id) WHERE is_active = TRUE;

-- Expression Index (case-insensitive email search):
CREATE INDEX idx_customers_email_lower ON customers (LOWER(email));

-- Task 4: process_salary_batch stored procedure
CREATE OR REPLACE FUNCTION process_salary_batch(
    company_account_number TEXT,
    payments JSONB
)
RETURNS JSONB AS $$
DECLARE
    company_account_balance NUMERIC;
    payment_record JSONB;
    payment_iin TEXT;
    payment_amount NUMERIC;
    payment_description TEXT;
    successful_count INT := 0;
    failed_count INT := 0;
    failed_details JSONB := '[]'::JSONB;
BEGIN

    SELECT balance INTO company_account_balance
    FROM accounts
    WHERE account_number = company_account_number;


    DECLARE
        total_batch_amount NUMERIC := 0;
    BEGIN
        FOR payment_record IN SELECT * FROM jsonb_array_elements(payments)
        LOOP
            total_batch_amount := total_batch_amount + (payment_record->>'amount')::NUMERIC;
        END LOOP;

        IF total_batch_amount > company_account_balance THEN
            RAISE EXCEPTION 'Batch total exceeds company account balance';
        END IF;
    END;


    FOR payment_record IN SELECT * FROM jsonb_array_elements(payments)
    LOOP
        payment_iin := payment_record->>'iin';
        payment_amount := (payment_record->>'amount')::NUMERIC;
        payment_description := payment_record->>'description';

        BEGIN
            successful_count := successful_count + 1;
        EXCEPTION
            WHEN OTHERS THEN
                failed_count := failed_count + 1;
                failed_details := failed_details || jsonb_build_object('iin', payment_iin, 'error', SQLERRM);
        END;
    END;

    RETURN jsonb_build_object(
        'successful_count', successful_count,
        'failed_count', failed_count,
        'failed_details', failed_details
    );
END;
$$ LANGUAGE plpgsql;