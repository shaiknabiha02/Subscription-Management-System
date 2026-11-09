/*
===============================================================================
PROJECT: SUBSCRIPTION MANAGEMENT SYSTEM
RDBMS  : MySQL 8.0.16+ (CHECK constraints are enforced from 8.0.16)
IDE    : MySQL Workbench

PURPOSE:
Manage customers, subscription plans, subscription periods/renewals,
payment attempts, and subscription status history.


TABLES:
1. customers
2. plans
3. subscriptions
4. subscription_periods
5. payments
6. subscription_history

NOTE:
All sample dates are fixed so that query results are reproducible.
===============================================================================
*/

-- ============================================================================
-- PART 1: DATABASE AND TABLE CREATION (SCHEMA)
-- ============================================================================

DROP DATABASE IF EXISTS subscription_management_system;
CREATE DATABASE subscription_management_system;
USE subscription_management_system;

-- 1. CUSTOMERS: one row per registered customer.
CREATE TABLE customers (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    phone VARCHAR(20),
    registration_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 2. PLANS: the plans offered by the subscription service.
CREATE TABLE plans (
    plan_id INT AUTO_INCREMENT PRIMARY KEY,
    plan_name VARCHAR(50) NOT NULL UNIQUE,
    duration_months INT NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    description VARCHAR(255),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT chk_plan_duration CHECK (duration_months > 0),
    CONSTRAINT chk_plan_price CHECK (price >= 0)
);

-- 3. SUBSCRIPTIONS: connects a customer to a selected plan.
-- current_period_start/end represent the latest/current billing period.
-- subscription_periods preserves every individual period, including renewals.
CREATE TABLE subscriptions (
    subscription_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    plan_id INT NOT NULL,
    start_date DATE NOT NULL,
    current_period_start DATE,
    current_period_end DATE,
    status ENUM('PENDING','ACTIVE','EXPIRED','CANCELLED')
        NOT NULL DEFAULT 'PENDING',
    auto_renew BOOLEAN NOT NULL DEFAULT FALSE,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_sub_customer
        FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    CONSTRAINT fk_sub_plan
        FOREIGN KEY (plan_id) REFERENCES plans(plan_id),
    CONSTRAINT chk_subscription_dates
        CHECK (
            current_period_start IS NULL
            OR current_period_end IS NULL
            OR current_period_end >= current_period_start
        )
);

-- 4. SUBSCRIPTION_PERIODS: one row for the initial period and each renewal.
CREATE TABLE subscription_periods (
    period_id INT AUTO_INCREMENT PRIMARY KEY,
    subscription_id INT NOT NULL,
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    amount_due DECIMAL(10,2) NOT NULL,
    period_status ENUM('PENDING','PAID','FAILED','WAIVED')
        NOT NULL DEFAULT 'PENDING',

    CONSTRAINT fk_period_subscription
        FOREIGN KEY (subscription_id)
        REFERENCES subscriptions(subscription_id),
    CONSTRAINT uq_subscription_period_start
        UNIQUE (subscription_id, period_start),
    CONSTRAINT chk_period_dates CHECK (period_end >= period_start),
    CONSTRAINT chk_period_amount CHECK (amount_due >= 0)
);

-- 5. PAYMENTS: every payment attempt is stored separately.
-- A failed attempt is never overwritten by a later successful attempt.
CREATE TABLE payments (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    period_id INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    payment_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    payment_method ENUM('UPI','CARD','NET_BANKING','WALLET','CASH')
        NOT NULL,
    payment_status ENUM('PENDING','SUCCESS','FAILED','REFUNDED')
        NOT NULL DEFAULT 'PENDING',
    transaction_reference VARCHAR(100) UNIQUE,

    CONSTRAINT fk_payment_period
        FOREIGN KEY (period_id) REFERENCES subscription_periods(period_id),
    CONSTRAINT chk_payment_amount CHECK (amount > 0)
);

-- 6. SUBSCRIPTION_HISTORY: audit trail of subscription status changes.
CREATE TABLE subscription_history (
    history_id INT AUTO_INCREMENT PRIMARY KEY,
    subscription_id INT NOT NULL,
    old_status ENUM('PENDING','ACTIVE','EXPIRED','CANCELLED'),
    new_status ENUM('PENDING','ACTIVE','EXPIRED','CANCELLED') NOT NULL,
    changed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    remarks VARCHAR(255),

    CONSTRAINT fk_history_subscription
        FOREIGN KEY (subscription_id) REFERENCES subscriptions(subscription_id)
);

-- ============================================================================
-- PART 2: SAMPLE DATA (INSERT STATEMENTS)
-- ============================================================================

INSERT INTO customers (full_name, email, phone, registration_date) VALUES
('Ayesha Khan',  'ayesha.khan@example.com',  '9876501001', '2026-01-05 10:00:00'),
('Rahul Sharma', 'rahul.sharma@example.com', '9876501002', '2026-02-10 11:30:00'),
('Meera Reddy',  'meera.reddy@example.com',  '9876501003', '2026-03-15 09:15:00'),
('Arjun Rao',    'arjun.rao@example.com',    '9876501004', '2026-04-20 14:00:00'),
('Sara Ali',     'sara.ali@example.com',     '9876501005', '2026-05-25 16:45:00'),
('Vikram Das',   'vikram.das@example.com',   '9876501006', '2026-06-02 12:00:00'),
('Nisha Paul',   'nisha.paul@example.com',   '9876501007', '2026-07-12 08:20:00');

INSERT INTO plans (plan_name, duration_months, price, description, is_active) VALUES
('Monthly',   1,  199.00, 'Access for one month', TRUE),
('Quarterly', 3,  499.00, 'Access for three months', TRUE),
('Yearly',   12, 1799.00, 'Access for twelve months', TRUE);

-- IDs are predictable here because this is a freshly created database.
INSERT INTO subscriptions
(customer_id, plan_id, start_date, current_period_start, current_period_end, status, auto_renew, created_at)
VALUES
(1, 1, '2026-10-01', '2026-11-01', '2026-11-30', 'ACTIVE', TRUE,  '2026-10-01 09:00:00'),
(2, 2, '2026-09-01', '2026-09-01', '2026-11-30', 'ACTIVE', FALSE, '2026-09-01 10:00:00'),
(3, 3, '2025-10-01', '2025-10-01', '2026-09-30', 'EXPIRED', FALSE,'2025-10-01 11:00:00'),
(4, 1, '2026-10-15', '2026-10-15', '2026-11-14', 'ACTIVE', FALSE, '2026-10-15 12:00:00'),
(5, 2, '2026-11-01', '2026-11-01', '2027-01-31', 'PENDING', TRUE,  '2026-11-01 13:00:00'),
(6, 1, '2026-08-01', '2026-08-01', '2026-08-31', 'CANCELLED', FALSE,'2026-08-01 14:00:00'),
(7, 3, '2026-07-01', '2026-07-01', '2027-06-30', 'ACTIVE', TRUE,  '2026-07-01 15:00:00');

INSERT INTO subscription_periods
(subscription_id, period_start, period_end, amount_due, period_status)
VALUES
(1, '2026-10-01', '2026-10-31', 199.00, 'PAID'),
(1, '2026-11-01', '2026-11-30', 199.00, 'PAID'),
(2, '2026-09-01', '2026-11-30', 499.00, 'PAID'),
(3, '2025-10-01', '2026-09-30', 1799.00, 'PAID'),
(4, '2026-10-15', '2026-11-14', 199.00, 'PAID'),
(5, '2026-11-01', '2027-01-31', 499.00, 'PENDING'),
(6, '2026-08-01', '2026-08-31', 199.00, 'PAID'),
(7, '2026-07-01', '2027-06-30', 1799.00, 'PAID');

INSERT INTO payments
(period_id, amount, payment_date, payment_method, payment_status, transaction_reference)
VALUES
(1, 199.00, '2026-10-01 09:05:00', 'UPI', 'SUCCESS', 'TXN-10001'),
(2, 199.00, '2026-11-01 09:05:00', 'UPI', 'SUCCESS', 'TXN-10002'),
(3, 499.00, '2026-09-01 10:05:00', 'CARD', 'SUCCESS', 'TXN-10003'),
(4, 1799.00,'2025-10-01 11:05:00', 'NET_BANKING', 'SUCCESS', 'TXN-10004'),
(5, 199.00, '2026-10-15 12:05:00', 'WALLET', 'FAILED', 'TXN-10005-F'),
(5, 199.00, '2026-10-15 12:10:00', 'UPI', 'SUCCESS', 'TXN-10005-S'),
(6, 499.00, '2026-11-01 13:05:00', 'CARD', 'FAILED', 'TXN-10006-F'),
(7, 199.00, '2026-08-01 14:05:00', 'UPI', 'SUCCESS', 'TXN-10007'),
(8, 1799.00,'2026-07-01 15:05:00', 'CARD', 'SUCCESS', 'TXN-10008');

-- Initial history records. Later status changes will be recorded by a trigger.
INSERT INTO subscription_history
(subscription_id, old_status, new_status, changed_at, remarks)
VALUES
(1, 'PENDING', 'ACTIVE', '2026-10-01 09:06:00', 'Initial payment successful'),
(2, 'PENDING', 'ACTIVE', '2026-09-01 10:06:00', 'Initial payment successful'),
(3, 'PENDING', 'ACTIVE', '2025-10-01 11:06:00', 'Initial payment successful'),
(3, 'ACTIVE', 'EXPIRED', '2026-10-01 00:00:00', 'Subscription period ended'),
(4, 'PENDING', 'ACTIVE', '2026-10-15 12:11:00', 'Payment successful'),
(6, 'ACTIVE', 'CANCELLED', '2026-08-20 10:00:00', 'Customer requested cancellation'),
(7, 'PENDING', 'ACTIVE', '2026-07-01 15:06:00', 'Initial payment successful');

-- ============================================================================
-- PART 3: INDEXES AND QUERY PERFORMANCE
-- ============================================================================

-- Primary keys and UNIQUE constraints already create indexes automatically.
-- These additional indexes support common filtering and joining patterns.
CREATE INDEX idx_subscriptions_customer ON subscriptions(customer_id);
CREATE INDEX idx_subscriptions_plan ON subscriptions(plan_id);
CREATE INDEX idx_subscriptions_status_end ON subscriptions(status, current_period_end);
CREATE INDEX idx_periods_subscription_dates ON subscription_periods(subscription_id, period_start, period_end);
CREATE INDEX idx_periods_status ON subscription_periods(period_status);
CREATE INDEX idx_payments_date_status ON payments(payment_date, payment_status);
CREATE INDEX idx_payments_period ON payments(period_id);
CREATE INDEX idx_history_subscription_date ON subscription_history(subscription_id, changed_at);

-- Compare the query plan. The optimizer may still choose a table scan for a
-- tiny sample table; indexes become more useful as the data grows.
EXPLAIN
SELECT *
FROM subscriptions
WHERE customer_id = 1;

EXPLAIN
SELECT *
FROM payments
WHERE payment_status = 'SUCCESS'
  AND payment_date >= '2026-10-01';

-- ============================================================================
-- PART 4: VIEWS
-- ============================================================================

-- View 1: currently active subscriptions.
CREATE VIEW vw_active_subscriptions AS
SELECT
    s.subscription_id,
    c.customer_id,
    c.full_name,
    c.email,
    p.plan_name,
    s.start_date,
    s.current_period_start,
    s.current_period_end,
    s.auto_renew,
    s.status
FROM subscriptions s
JOIN customers c ON s.customer_id = c.customer_id
JOIN plans p ON s.plan_id = p.plan_id
WHERE s.status = 'ACTIVE';

-- View 2: customer subscription and period history.
CREATE VIEW vw_customer_subscription_history AS
SELECT
    c.customer_id,
    c.full_name,
    s.subscription_id,
    p.plan_name,
    sp.period_id,
    sp.period_start,
    sp.period_end,
    sp.amount_due,
    sp.period_status,
    s.status AS subscription_status
FROM customers c
JOIN subscriptions s ON c.customer_id = s.customer_id
JOIN plans p ON s.plan_id = p.plan_id
LEFT JOIN subscription_periods sp ON s.subscription_id = sp.subscription_id;

-- View 3: monthly successful payment revenue.
CREATE VIEW vw_monthly_revenue AS
SELECT
    DATE_FORMAT(payment_date, '%Y-%m') AS revenue_month,
    COUNT(*) AS successful_payment_count,
    SUM(amount) AS total_revenue
FROM payments
WHERE payment_status = 'SUCCESS'
GROUP BY DATE_FORMAT(payment_date, '%Y-%m');

-- View 4: expired subscriptions.
CREATE VIEW vw_expired_subscriptions AS
SELECT
    s.subscription_id,
    c.full_name,
    c.email,
    p.plan_name,
    s.current_period_end,
    s.status
FROM subscriptions s
JOIN customers c ON s.customer_id = c.customer_id
JOIN plans p ON s.plan_id = p.plan_id
WHERE s.status = 'EXPIRED';

-- View 5: payment failures.
CREATE VIEW vw_failed_payments AS
SELECT
    pay.payment_id,
    c.full_name,
    s.subscription_id,
    sp.period_id,
    pay.amount,
    pay.payment_date,
    pay.payment_method,
    pay.transaction_reference
FROM payments pay
JOIN subscription_periods sp ON pay.period_id = sp.period_id
JOIN subscriptions s ON sp.subscription_id = s.subscription_id
JOIN customers c ON s.customer_id = c.customer_id
WHERE pay.payment_status = 'FAILED';

-- ============================================================================
-- PART 5: STORED PROCEDURES
-- ============================================================================

DELIMITER $$

-- Procedure 1: register a new customer.
CREATE PROCEDURE sp_register_customer(
    IN p_full_name VARCHAR(100),
    IN p_email VARCHAR(150),
    IN p_phone VARCHAR(20)
)
BEGIN
    INSERT INTO customers(full_name, email, phone)
    VALUES(p_full_name, p_email, p_phone);

    SELECT LAST_INSERT_ID() AS new_customer_id;
END$$

-- Procedure 2: create a subscription and its first billing period.
-- The subscription remains PENDING until a successful payment is inserted.
CREATE PROCEDURE sp_create_subscription(
    IN p_customer_id INT,
    IN p_plan_id INT,
    IN p_start_date DATE,
    IN p_auto_renew BOOLEAN,
    OUT p_new_subscription_id INT
)
BEGIN
    DECLARE v_duration INT;
    DECLARE v_price DECIMAL(10,2);
    DECLARE v_plan_active BOOLEAN;

    SELECT duration_months, price, is_active
      INTO v_duration, v_price, v_plan_active
    FROM plans
    WHERE plan_id = p_plan_id;

    IF NOT EXISTS (SELECT 1 FROM customers WHERE customer_id = p_customer_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Customer does not exist';
    END IF;

    IF v_plan_active = FALSE THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Selected plan is inactive';
    END IF;

    INSERT INTO subscriptions
    (customer_id, plan_id, start_date, current_period_start,
     current_period_end, status, auto_renew)
    VALUES
    (p_customer_id, p_plan_id, p_start_date, p_start_date,
     DATE_SUB(DATE_ADD(p_start_date, INTERVAL v_duration MONTH), INTERVAL 1 DAY),
     'PENDING', p_auto_renew);

    SET p_new_subscription_id = LAST_INSERT_ID();

    INSERT INTO subscription_periods
    (subscription_id, period_start, period_end, amount_due, period_status)
    VALUES
    (p_new_subscription_id, p_start_date,
     DATE_SUB(DATE_ADD(p_start_date, INTERVAL v_duration MONTH), INTERVAL 1 DAY),
     v_price, 'PENDING');
END$$

-- Procedure 3: add the next renewal period.
-- This creates a PENDING period; a payment attempt must still be recorded.
CREATE PROCEDURE sp_create_renewal_period(
    IN p_subscription_id INT,
    OUT p_new_period_id INT
)
BEGIN
    DECLARE v_next_start DATE;
    DECLARE v_duration INT;
    DECLARE v_price DECIMAL(10,2);
    DECLARE v_plan_id INT;
    DECLARE v_status VARCHAR(20);

    SELECT plan_id, status
      INTO v_plan_id, v_status
    FROM subscriptions
    WHERE subscription_id = p_subscription_id;

    IF v_status = 'CANCELLED' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cancelled subscription cannot be renewed';
    END IF;

    SELECT duration_months, price
      INTO v_duration, v_price
    FROM plans
    WHERE plan_id = v_plan_id;

    SELECT DATE_ADD(MAX(period_end), INTERVAL 1 DAY)
      INTO v_next_start
    FROM subscription_periods
    WHERE subscription_id = p_subscription_id;

    IF v_next_start IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No previous billing period found';
    END IF;

    INSERT INTO subscription_periods
    (subscription_id, period_start, period_end, amount_due, period_status)
    VALUES
    (p_subscription_id, v_next_start,
     DATE_SUB(DATE_ADD(v_next_start, INTERVAL v_duration MONTH), INTERVAL 1 DAY),
     v_price, 'PENDING');

    SET p_new_period_id = LAST_INSERT_ID();
END$$

-- Procedure 4: calculate successful revenue in a date range (OUT parameter).
CREATE PROCEDURE sp_calculate_revenue(
    IN p_from_date DATE,
    IN p_to_date DATE,
    OUT p_total_revenue DECIMAL(12,2)
)
BEGIN
    SELECT COALESCE(SUM(amount), 0.00)
      INTO p_total_revenue
    FROM payments
    WHERE payment_status = 'SUCCESS'
      AND payment_date >= p_from_date
      AND payment_date < DATE_ADD(p_to_date, INTERVAL 1 DAY);
END$$

-- Procedure 5: retrieve all subscriptions belonging to a customer.
CREATE PROCEDURE sp_customer_subscription_details(IN p_customer_id INT)
BEGIN
    SELECT
        c.customer_id,
        c.full_name,
        c.email,
        s.subscription_id,
        p.plan_name,
        s.start_date,
        s.current_period_end,
        s.status,
        s.auto_renew
    FROM customers c
    JOIN subscriptions s ON c.customer_id = s.customer_id
    JOIN plans p ON s.plan_id = p.plan_id
    WHERE c.customer_id = p_customer_id
    ORDER BY s.created_at DESC;
END$$

-- Procedure 6: expire active subscriptions whose current period has ended.
CREATE PROCEDURE sp_expire_subscriptions(IN p_as_of_date DATE)
BEGIN
    UPDATE subscriptions
    SET status = 'EXPIRED'
    WHERE status = 'ACTIVE'
      AND current_period_end < p_as_of_date;
END$$

DELIMITER ;

-- ============================================================================
-- PART 6: TRIGGERS WITH AUDIT / SUPPORTING LOGIC
-- ============================================================================

DELIMITER $$

-- Trigger 1: validate that a payment does not exceed the period amount due.
-- This simple academic rule assumes one period is paid in one full payment.
CREATE TRIGGER trg_before_payment_insert
BEFORE INSERT ON payments
FOR EACH ROW
BEGIN
    DECLARE v_amount_due DECIMAL(10,2);

    SELECT amount_due INTO v_amount_due
    FROM subscription_periods
    WHERE period_id = NEW.period_id;

    IF NEW.amount > v_amount_due THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Payment amount cannot exceed period amount due';
    END IF;

    IF NEW.payment_status = 'SUCCESS' AND NEW.amount <> v_amount_due THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'A successful payment must match the full period amount due';
    END IF;
END$$

-- Trigger 2: after a payment attempt, update the period and activate the
-- subscription only when the payment status is SUCCESS.
CREATE TRIGGER trg_after_payment_insert
AFTER INSERT ON payments
FOR EACH ROW
BEGIN
    DECLARE v_subscription_id INT;

    SELECT subscription_id INTO v_subscription_id
    FROM subscription_periods
    WHERE period_id = NEW.period_id;

    IF NEW.payment_status = 'SUCCESS' THEN
        UPDATE subscription_periods
        SET period_status = 'PAID'
        WHERE period_id = NEW.period_id;

        UPDATE subscriptions
        SET status = 'ACTIVE',
            current_period_start = (
                SELECT period_start FROM subscription_periods
                WHERE period_id = NEW.period_id
            ),
            current_period_end = (
                SELECT period_end FROM subscription_periods
                WHERE period_id = NEW.period_id
            )
        WHERE subscription_id = v_subscription_id
          AND status <> 'CANCELLED';
    ELSEIF NEW.payment_status = 'FAILED' THEN
        UPDATE subscription_periods
        SET period_status = 'FAILED'
        WHERE period_id = NEW.period_id
          AND period_status <> 'PAID';
    END IF;
END$$

-- Trigger 3: record every actual subscription status change.
CREATE TRIGGER trg_after_subscription_status_update
AFTER UPDATE ON subscriptions
FOR EACH ROW
BEGIN
    IF OLD.status <> NEW.status THEN
        INSERT INTO subscription_history
        (subscription_id, old_status, new_status, changed_at, remarks)
        VALUES
        (NEW.subscription_id, OLD.status, NEW.status, CURRENT_TIMESTAMP,
         'Status changed by database operation');
    END IF;
END$$

DELIMITER ;

-- ============================================================================
-- PART 7: BASIC QUERIES AND AGGREGATE FUNCTIONS
-- ============================================================================

-- 1. Display all customers.
SELECT * FROM customers;

-- 2. Display all available plans.
SELECT * FROM plans WHERE is_active = TRUE;

-- 3. Find customers registered after 01-Apr-2026.
SELECT *
FROM customers
WHERE registration_date >= '2026-04-01';

-- 4. Display plans from highest to lowest price.
SELECT plan_name, duration_months, price
FROM plans
ORDER BY price DESC;

-- 5. Count the total number of customers.
SELECT COUNT(*) AS total_customers
FROM customers;

-- 6. Find the average plan price.
SELECT AVG(price) AS average_plan_price
FROM plans;

-- 7. Find the highest and lowest plan prices.
SELECT MAX(price) AS highest_price, MIN(price) AS lowest_price
FROM plans;

-- 8. Count subscriptions by status.
SELECT status, COUNT(*) AS subscription_count
FROM subscriptions
GROUP BY status;

-- 9. Find total successful payment revenue.
SELECT SUM(amount) AS total_successful_revenue
FROM payments
WHERE payment_status = 'SUCCESS';

-- 10. Find customers whose names begin with A.
SELECT *
FROM customers
WHERE full_name LIKE 'A%';

-- ============================================================================
-- PART 8: JOINS AND JOINS WITH CLAUSES
-- ============================================================================

-- 11. Display customer names with their subscription plans.
SELECT c.full_name, p.plan_name, s.status
FROM customers c
INNER JOIN subscriptions s ON c.customer_id = s.customer_id
INNER JOIN plans p ON s.plan_id = p.plan_id;

-- 12. Display all customers and any subscriptions they have.
SELECT c.customer_id, c.full_name, s.subscription_id, s.status
FROM customers c
LEFT JOIN subscriptions s ON c.customer_id = s.customer_id;

-- 13. Display payment details with customer and plan information.
SELECT c.full_name, p.plan_name, pay.amount, pay.payment_status, pay.payment_date
FROM payments pay
JOIN subscription_periods sp ON pay.period_id = sp.period_id
JOIN subscriptions s ON sp.subscription_id = s.subscription_id
JOIN customers c ON s.customer_id = c.customer_id
JOIN plans p ON s.plan_id = p.plan_id;

-- 14. Find total successful revenue per customer.
SELECT c.customer_id, c.full_name, COALESCE(SUM(pay.amount),0) AS revenue
FROM customers c
LEFT JOIN subscriptions s ON c.customer_id = s.customer_id
LEFT JOIN subscription_periods sp ON s.subscription_id = sp.subscription_id
LEFT JOIN payments pay
    ON sp.period_id = pay.period_id AND pay.payment_status = 'SUCCESS'
GROUP BY c.customer_id, c.full_name
ORDER BY revenue DESC;

-- 15. Find plans with more than one subscription.
SELECT p.plan_name, COUNT(s.subscription_id) AS subscription_count
FROM plans p
LEFT JOIN subscriptions s ON p.plan_id = s.plan_id
GROUP BY p.plan_id, p.plan_name
HAVING COUNT(s.subscription_id) > 1;

-- ============================================================================
-- PART 9: SUBQUERIES, CASE, DATE AND STRING FUNCTIONS
-- ============================================================================

-- 16. Find customers who have at least one active subscription.
SELECT customer_id, full_name
FROM customers
WHERE customer_id IN (
    SELECT customer_id
    FROM subscriptions
    WHERE status = 'ACTIVE'
);

-- 17. Find plans priced above the average plan price.
SELECT plan_name, price
FROM plans
WHERE price > (SELECT AVG(price) FROM plans);

-- 18. Classify subscriptions using CASE.
SELECT
    subscription_id,
    status,
    CASE
        WHEN status = 'ACTIVE' THEN 'Currently active'
        WHEN status = 'PENDING' THEN 'Awaiting successful payment'
        WHEN status = 'EXPIRED' THEN 'Period has ended'
        WHEN status = 'CANCELLED' THEN 'Cancelled by customer'
        ELSE 'Other'
    END AS status_description
FROM subscriptions;

-- 19. Display the number of days remaining in each active subscription.
SELECT
    subscription_id,
    current_period_end,
    DATEDIFF(current_period_end, CURDATE()) AS days_remaining
FROM subscriptions
WHERE status = 'ACTIVE';

-- 20. Display customer names in uppercase and email domains.
SELECT
    UPPER(full_name) AS customer_name,
    SUBSTRING_INDEX(email, '@', -1) AS email_domain
FROM customers;

-- 21. Find customers with more than one subscription (correlated subquery).
SELECT c.customer_id, c.full_name
FROM customers c
WHERE (
    SELECT COUNT(*)
    FROM subscriptions s
    WHERE s.customer_id = c.customer_id
) > 1;

-- ============================================================================
-- PART 10: ADVANCED QUERIES — CTEs AND WINDOW FUNCTIONS
-- ============================================================================

-- 22. Rank customers by successful payment revenue.
WITH customer_revenue AS (
    SELECT
        c.customer_id,
        c.full_name,
        COALESCE(SUM(
            CASE WHEN pay.payment_status = 'SUCCESS' THEN pay.amount ELSE 0 END
        ),0) AS total_revenue
    FROM customers c
    LEFT JOIN subscriptions s ON c.customer_id = s.customer_id
    LEFT JOIN subscription_periods sp ON s.subscription_id = sp.subscription_id
    LEFT JOIN payments pay ON sp.period_id = pay.period_id
    GROUP BY c.customer_id, c.full_name
)
SELECT
    customer_id,
    full_name,
    total_revenue,
    DENSE_RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
FROM customer_revenue;

-- 23. Find the latest payment attempt for each billing period.
WITH ranked_payments AS (
    SELECT
        payment_id,
        period_id,
        amount,
        payment_status,
        payment_date,
        ROW_NUMBER() OVER (
            PARTITION BY period_id
            ORDER BY payment_date DESC, payment_id DESC
        ) AS rn
    FROM payments
)
SELECT *
FROM ranked_payments
WHERE rn = 1;

-- 24. Calculate running monthly revenue.
WITH monthly AS (
    SELECT
        DATE_FORMAT(payment_date, '%Y-%m') AS revenue_month,
        SUM(amount) AS monthly_revenue
    FROM payments
    WHERE payment_status = 'SUCCESS'
    GROUP BY DATE_FORMAT(payment_date, '%Y-%m')
)
SELECT
    revenue_month,
    monthly_revenue,
    SUM(monthly_revenue) OVER (ORDER BY revenue_month) AS running_revenue
FROM monthly;

-- 25. Identify customers with a failed payment and no successful payment
-- for the same billing period.
SELECT DISTINCT c.customer_id, c.full_name, sp.period_id
FROM customers c
JOIN subscriptions s ON c.customer_id = s.customer_id
JOIN subscription_periods sp ON s.subscription_id = sp.subscription_id
JOIN payments failed
    ON sp.period_id = failed.period_id AND failed.payment_status = 'FAILED'
WHERE NOT EXISTS (
    SELECT 1
    FROM payments success
    WHERE success.period_id = sp.period_id
      AND success.payment_status = 'SUCCESS'
);

-- 26. Find active subscriptions that will expire within the next 30 days.
SELECT
    s.subscription_id,
    c.full_name,
    s.current_period_end
FROM subscriptions s
JOIN customers c ON s.customer_id = c.customer_id
WHERE s.status = 'ACTIVE'
  AND s.current_period_end BETWEEN CURDATE()
                               AND DATE_ADD(CURDATE(), INTERVAL 30 DAY);

-- ============================================================================
-- PART 11: QUERY BANK — 30 QUESTIONS (EASY TO HARD)
-- Write your own SQL below each question. The questions intentionally have
-- no solutions here so that you can practise.
-- ============================================================================

/*
EASY (Q01-Q10)
Q01. Display all customer records.
Q02. Display the names and prices of all subscription plans.
Q03. Find customers who registered after 01-June-2026.
Q04. Display all plans in descending order of price.
Q05. Count the total number of registered customers.
Q06. Find the average price of all plans.
Q07. Display the highest-priced and lowest-priced plans.
Q08. Count subscriptions in each status.
Q09. Find the total amount collected from successful payments.
Q10. Find customers whose names contain the letter 'a'.

MEDIUM (Q11-Q20)
Q11. Display each customer's name along with their selected plan.
Q12. Display all customers, including customers who have no subscription.
Q13. Display payment ID, customer name, plan name, amount and payment status.
Q14. Calculate successful payment revenue for each customer.
Q15. Find plans selected by more than one subscription.
Q16. Find customers who have at least one active subscription.
Q17. Find plans whose price is greater than the average plan price.
Q18. Display subscriptions with a readable status description using CASE.
Q19. Display the number of days remaining for every active subscription.
Q20. Display customer names in uppercase and extract their email domains.

HARD (Q21-Q30)
Q21. Find customers who have purchased more than one subscription.
Q22. Rank customers based on their total successful payment revenue.
Q23. Find the latest payment attempt for every billing period using ROW_NUMBER().
Q24. Calculate monthly revenue and a running cumulative revenue using a window function.
Q25. Identify billing periods that have a failed payment but no successful payment.
Q26. Find active subscriptions expiring within the next 30 days.
Q27. Find customers who have never made a successful payment.
Q28. Find the plan generating the highest successful revenue.
Q29. Calculate the percentage of billing periods paid successfully.
Q30. Find customers whose successful payment revenue is above the average customer revenue.
*/


-- Validation: inspect all tables.
SELECT * FROM customers;
SELECT * FROM plans;
SELECT * FROM subscriptions;
SELECT * FROM subscription_periods;
SELECT * FROM payments;
SELECT * FROM subscription_history;

-- Validation: inspect views.
SELECT * FROM vw_active_subscriptions;
SELECT * FROM vw_customer_subscription_history;
SELECT * FROM vw_monthly_revenue;
SELECT * FROM vw_expired_subscriptions;
SELECT * FROM vw_failed_payments;

-- Validation: inspect indexes, procedures, triggers and views.
SHOW INDEX FROM subscriptions;
SHOW PROCEDURE STATUS WHERE Db = 'subscription_management_system';
SHOW TRIGGERS FROM subscription_management_system;
SHOW FULL TABLES IN subscription_management_system WHERE TABLE_TYPE = 'VIEW';

-- END OF PROJECT SCRIPT
