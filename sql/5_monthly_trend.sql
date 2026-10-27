/* =====================================================================
   05_monthly_trend.sql
   Question : Did the funnel change over time, and when?
   Output   : monthly funnel, monthly funnel by device, and a daily view
              around the break point.
   Notes    : - cohort_month comes from the user's first-visit date, so
                months are visit cohorts, not purchase dates.
              - Month-over-month change uses LAG() on the UNROUNDED rate,
                then rounds at the end. Using already-rounded rates would
                shift some changes by 0.01.
              - Changes are in percentage points (pp), the right unit
                when comparing rates.
   ===================================================================== */

USE sales_analysis;

/* ---- 5A. Monthly funnel with month-over-month change --------------- */
WITH monthly AS (
    SELECT
        cohort_month,
        COUNT(*)                                                            AS users,
        SUM(reached_search)                                                 AS search_users,
        SUM(reached_payment)                                                AS payment_users,
        SUM(reached_confirmation)                                           AS purchases,
        100.0 * SUM(reached_search)       / COUNT(*)                        AS h2s,
        100.0 * SUM(reached_payment)      / NULLIF(SUM(reached_search), 0)  AS s2p,
        100.0 * SUM(reached_confirmation) / NULLIF(SUM(reached_payment), 0) AS p2c,
        100.0 * SUM(reached_confirmation) / COUNT(*)                        AS overall
    FROM vw_funnel_master
    GROUP BY cohort_month
)
SELECT
    cohort_month,
    users, search_users, payment_users, purchases,
    ROUND(h2s, 2)     AS home_to_search_pct,
    ROUND(s2p, 2)     AS search_to_payment_pct,
    ROUND(p2c, 2)     AS payment_to_confirm_pct,
    ROUND(overall, 2) AS overall_conversion_pct,
    ROUND(overall - LAG(overall) OVER (ORDER BY cohort_month), 2) AS mom_change_pp
FROM monthly
ORDER BY cohort_month;

/* ---- 5B. Monthly funnel by device ---------------------------------- */
SELECT
    cohort_month,
    device,
    COUNT(*)                                                                      AS users,
    SUM(reached_search)                                                           AS search_users,
    SUM(reached_payment)                                                          AS payment_users,
    SUM(reached_confirmation)                                                     AS purchases,
    ROUND(100.0 * SUM(reached_search)       / COUNT(*), 2)                        AS home_to_search_pct,
    ROUND(100.0 * SUM(reached_payment)      / NULLIF(SUM(reached_search), 0), 2)  AS search_to_payment_pct,
    ROUND(100.0 * SUM(reached_confirmation) / NULLIF(SUM(reached_payment), 0), 2) AS payment_to_confirm_pct
FROM vw_funnel_master
GROUP BY cohort_month, device
ORDER BY cohort_month, device;

/* ---- 5C. Daily view around the break (pins down the exact date) ---- */
SELECT
    visit_date,
    COUNT(*)                                                                 AS users,
    ROUND(100.0 * SUM(reached_search)  / COUNT(*), 1)                        AS home_to_search_pct,
    ROUND(100.0 * SUM(reached_payment) / NULLIF(SUM(reached_search), 0), 1)  AS search_to_payment_pct
FROM vw_funnel_master
WHERE visit_date BETWEEN '2015-02-24' AND '2015-03-07'
GROUP BY visit_date
ORDER BY visit_date;