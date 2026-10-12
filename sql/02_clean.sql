-- =========================================================
-- 02_clean.sql: clean transactions, members and user logs
-- =========================================================

-- Transactions -------------------------------------------
CREATE OR REPLACE TABLE tx_clean AS
WITH dedup AS (
    SELECT DISTINCT * FROM raw_tx                         -- rule: remove exact duplicates
),
typed AS (
    SELECT msno, payment_method_id, payment_plan_days,
           plan_list_price, actual_amount_paid, is_auto_renew, is_cancel,
           strptime(CAST(transaction_date AS VARCHAR), '%Y%m%d')::DATE       AS tx_date,
           strptime(CAST(membership_expire_date AS VARCHAR), '%Y%m%d')::DATE AS expire_date
    FROM dedup
)
SELECT *,
       (actual_amount_paid = 0)                                       AS is_free,
       (actual_amount_paid > 0 AND actual_amount_paid < plan_list_price) AS is_discounted,
       CASE WHEN payment_plan_days = 0   THEN 'no plan (0 days)'
            WHEN payment_plan_days <= 10 THEN 'short (1-10 days)'
            WHEN payment_plan_days <= 31 THEN 'monthly (11-31 days)'
            ELSE 'long (>31 days)' END                                AS plan_group
FROM typed
WHERE is_cancel = 1                    -- rule: keep all cancellations
   OR expire_date >= tx_date;          -- rule: drop payments whose expiry is before the payment date

-- Members ------------------------------------------------
CREATE OR REPLACE TABLE members_clean AS
SELECT msno, city, registered_via,
       CASE WHEN bd BETWEEN 10 AND 90 THEN bd END                 AS age,   -- rule: implausible age -> NULL
       CASE WHEN bd BETWEEN 10 AND 24 THEN '10-24'
            WHEN bd BETWEEN 25 AND 34 THEN '25-34'
            WHEN bd BETWEEN 35 AND 44 THEN '35-44'
            WHEN bd BETWEEN 45 AND 90 THEN '45+'
            ELSE 'Unknown' END                                    AS age_group,
       COALESCE(gender, 'unknown')                                AS gender,  -- rule: missing gender -> 'unknown'
       strptime(CAST(registration_init_time AS VARCHAR), '%Y%m%d')::DATE AS registration_date
FROM raw_members;

-- User logs ----------------------------------------------
CREATE OR REPLACE TABLE logs_clean AS
SELECT msno,
       strptime(CAST(date AS VARCHAR), '%Y%m%d')::DATE   AS log_date,
       SUM(num_25 + num_50 + num_75 + num_985 + num_100)  AS songs_played,
       SUM(num_100)                                       AS songs_completed,
       SUM(num_unq)                                       AS unique_songs,
       LEAST(SUM(GREATEST(total_secs, 0)), 86400)         AS secs   -- rules: negatives -> 0, cap at 24 h
FROM raw_logs
GROUP BY ALL;                                             -- rule: one row per user per day