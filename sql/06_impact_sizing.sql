/* =====================================================================
   06_impact_sizing.sql
   Question : How many extra purchases would each fix be worth?
   Output   : (A) Desktop catching up to Mobile, by stage;
              (B) restoring March-April to January-February performance.
   Notes    : - Each scenario applies a benchmark rate to actual volume.
              - Multiplication happens before division so rounding
                doesn't creep into intermediate results.
              - Scenarios overlap, so their gains must NOT be added up.
              - Results are in purchases, not money: the dataset has no
                order value. Multiply by an average order value for revenue.
   ===================================================================== */

USE sales_analysis;

/* ---- 6A. Desktop catches up to Mobile ------------------------------ */
WITH d AS (
    SELECT device,
           SUM(reached_search)       AS s,
           SUM(reached_payment)      AS p,
           SUM(reached_confirmation) AS c
    FROM vw_funnel_master
    GROUP BY device
),
m AS (SELECT s, p, c FROM d WHERE device = 'Mobile'),
x AS (SELECT s, p, c FROM d WHERE device = 'Desktop')
SELECT 'Current Desktop purchases'                      AS scenario,
       x.c                                              AS desktop_purchases,
       0                                                AS gain
FROM x
UNION ALL
SELECT 'Search -> Payment matches Mobile',
       ROUND(x.s * m.p / m.s * x.c / x.p, 0),
       ROUND(x.s * m.p / m.s * x.c / x.p, 0) - x.c
FROM m, x
UNION ALL
SELECT 'Payment -> Confirmation matches Mobile',
       ROUND(x.p * m.c / m.p, 0),
       ROUND(x.p * m.c / m.p, 0) - x.c
FROM m, x
UNION ALL
SELECT 'Both stages match Mobile',
       ROUND(x.s * m.p / m.s * m.c / m.p, 0),
       ROUND(x.s * m.p / m.s * m.c / m.p, 0) - x.c
FROM m, x;

/* ---- 6B. Restore March-April to January-February conversion -------- */
WITH per AS (
    SELECT
        device,
        SUM(IF(cohort_month <= '2015-02', reached_confirmation, 0)) AS jf_purchases,
        SUM(IF(cohort_month <= '2015-02', 1, 0))                    AS jf_users,
        SUM(IF(cohort_month >= '2015-03', reached_confirmation, 0)) AS ma_purchases,
        SUM(IF(cohort_month >= '2015-03', 1, 0))                    AS ma_users
    FROM vw_funnel_master
    GROUP BY device
)
SELECT device,
       jf_purchases,
       ma_purchases,
       ROUND(ma_users * jf_purchases / jf_users, 0)                 AS ma_at_jf_rate,
       ROUND(ma_users * jf_purchases / jf_users, 0) - ma_purchases  AS gain
FROM per
UNION ALL
SELECT 'All devices',
       SUM(jf_purchases),
       SUM(ma_purchases),
       SUM(ROUND(ma_users * jf_purchases / jf_users, 0)),
       SUM(ROUND(ma_users * jf_purchases / jf_users, 0) - ma_purchases)
FROM per;