/* =====================================================================
   03_funnel_metrics.sql
   Overall funnel: users per stage, step conversion, step drop-off,
   cumulative conversion, users lost and each stage's share of all loss.
   Source: vw_funnel_master (one row per user, 0/1 stage flags)
   ===================================================================== */

USE sales_analysis;

WITH stage_counts AS (
    -- One row per funnel stage. SUM(flag) counts users who reached it.
    SELECT 1 AS stage_no, 'Home Page'            AS stage_name, SUM(reached_home)         AS users FROM vw_funnel_master
    UNION ALL
    SELECT 2, 'Search Page',                                     SUM(reached_search)       FROM vw_funnel_master
    UNION ALL
    SELECT 3, 'Payment Page',                                    SUM(reached_payment)      FROM vw_funnel_master
    UNION ALL
    SELECT 4, 'Payment Confirmation',                            SUM(reached_confirmation) FROM vw_funnel_master
),
with_prev AS (
    -- Window functions: previous stage's users and the top of the funnel.
    SELECT stage_no, stage_name, users,
           LAG(users)         OVER (ORDER BY stage_no) AS prev_users,
           FIRST_VALUE(users) OVER (ORDER BY stage_no) AS top_of_funnel
    FROM stage_counts
),
metrics AS (
    SELECT stage_no, stage_name, users, top_of_funnel,
           prev_users - users AS users_lost
    FROM with_prev
)
SELECT
    m.stage_no,
    m.stage_name,
    m.users,
    m.users_lost,
    ROUND(100.0 * m.users / NULLIF(w.prev_users, 0), 2)         AS step_conversion_pct,
    ROUND(100.0 - 100.0 * m.users / NULLIF(w.prev_users, 0), 2) AS step_dropoff_pct,
    ROUND(100.0 * m.users / m.top_of_funnel, 2)                 AS cumulative_conversion_pct,
    ROUND(m.top_of_funnel / m.users, 1)                         AS one_in_n_visitors,
    ROUND(100.0 * m.users_lost / SUM(m.users_lost) OVER (), 2)  AS share_of_total_loss_pct
FROM metrics m
JOIN with_prev w ON w.stage_no = m.stage_no
ORDER BY m.stage_no;