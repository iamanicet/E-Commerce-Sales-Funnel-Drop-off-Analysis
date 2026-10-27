/* =====================================================================
   02_funnel_view.sql
   Master funnel view: one row per user with demographics, a cohort
   month and a 0/1 flag for each funnel stage reached.
   Run after 00_load_data.sql. Every later analysis reads from this view
   so all metrics share one definition.
   ===================================================================== */

USE sales_analysis;

CREATE OR REPLACE VIEW vw_funnel_master AS
SELECT
    u.user_id,
    u.date                          AS visit_date,      -- first visit date
    DATE_FORMAT(u.date, '%Y-%m')    AS cohort_month,    -- e.g. '2015-03'
    u.device,                                           -- 'Desktop' | 'Mobile'
    u.sex                           AS gender,          -- 'Male' | 'Female'

    -- Stage flags: 1 = user reached the stage, 0 = did not.
    -- LEFT JOIN keeps every user; no match means a NULL, which becomes 0.
    IF(h.user_id IS NOT NULL, 1, 0) AS reached_home,
    IF(s.user_id IS NOT NULL, 1, 0) AS reached_search,
    IF(p.user_id IS NOT NULL, 1, 0) AS reached_payment,
    IF(c.user_id IS NOT NULL, 1, 0) AS reached_confirmation
FROM user_table u
LEFT JOIN home_page_table            h ON u.user_id = h.user_id
LEFT JOIN search_page_table          s ON u.user_id = s.user_id
LEFT JOIN payment_page_table         p ON u.user_id = p.user_id
LEFT JOIN payment_confirmation_table c ON u.user_id = c.user_id;

-- Sanity check: expect 90400 rows and 90400 distinct users
SELECT COUNT(*) AS view_rows, COUNT(DISTINCT user_id) AS view_users FROM vw_funnel_master;