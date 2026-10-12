-- =========================================================
-- 03_spells.sql: build subscription spells from transactions
-- =========================================================

-- 1. Input: exclude placeholder and far-future expiry dates
CREATE OR REPLACE TABLE tx_for_spells AS
SELECT *
FROM tx_clean
WHERE expire_date <> DATE '1970-01-01'
  AND expire_date <= tx_date + INTERVAL 450 DAY;

-- 2. Spells (gaps and islands)
CREATE OR REPLACE TABLE spells AS
WITH ordered AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY msno ORDER BY tx_date, expire_date) AS rn,
           MAX(expire_date) OVER (
               PARTITION BY msno ORDER BY tx_date, expire_date
               ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING)               AS prev_max_expire
    FROM tx_for_spells
),
flagged AS (
    SELECT *,
           CASE WHEN prev_max_expire IS NULL
                  OR tx_date > prev_max_expire + INTERVAL 30 DAY
                THEN 1 ELSE 0 END AS is_new_spell
    FROM ordered
),
numbered AS (
    SELECT *,
           SUM(is_new_spell) OVER (PARTITION BY msno ORDER BY rn
                                   ROWS UNBOUNDED PRECEDING) AS spell_id
    FROM flagged
)
SELECT msno, spell_id,
       MIN(tx_date)                          AS spell_start,
       arg_max(expire_date, rn)              AS spell_end,
       COUNT(*)                              AS n_transactions,
       COUNT(*) FILTER (WHERE is_cancel = 0) AS n_payments,
       SUM(actual_amount_paid)               AS revenue,
       arg_min(payment_plan_days, rn)        AS first_plan_days,
       arg_min(plan_group, rn)               AS first_plan_group,
       arg_min(is_auto_renew, rn)            AS first_auto_renew,
       arg_min(payment_method_id, rn)        AS first_payment_method,
       arg_min(is_free, rn)                  AS started_free,
       bool_or(is_discounted)                AS had_discount,
       MAX(is_cancel)                        AS ever_cancelled
FROM numbered
GROUP BY msno, spell_id;

-- 3. Outcome, censoring and duration
CREATE OR REPLACE TABLE spells_final AS
SELECT *,
       (spell_end + INTERVAL 30 DAY <= DATE '2017-03-31')                AS churned,
       datediff('day', spell_start, LEAST(spell_end, DATE '2017-03-31')) AS duration_days,
       (spell_start < DATE '2015-02-01')                                 AS left_truncated,
       (spell_id > 1)                                                    AS is_reactivation
FROM spells;