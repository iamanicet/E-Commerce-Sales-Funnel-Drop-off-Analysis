USE sales_analysis;

-- A. Row counts: rows vs distinct users (each pair must be identical)
SELECT 'user_table' AS tbl, COUNT(*) AS row_n, COUNT(DISTINCT user_id) AS distinct_n FROM user_table
UNION ALL SELECT 'home_page',    COUNT(*), COUNT(DISTINCT user_id) FROM home_page_table
UNION ALL SELECT 'search_page',  COUNT(*), COUNT(DISTINCT user_id) FROM search_page_table
UNION ALL SELECT 'payment_page', COUNT(*), COUNT(DISTINCT user_id) FROM payment_page_table
UNION ALL SELECT 'confirmation', COUNT(*), COUNT(DISTINCT user_id) FROM payment_confirmation_table;
-- expect 90400 / 90400 / 45200 / 6030 / 452

-- B. View integrity
SELECT COUNT(*) AS view_rows, COUNT(DISTINCT user_id) AS view_users FROM vw_funnel_master;
-- expect 90400 / 90400

-- C. Known-truth segment checks
SELECT device, COUNT(*) AS users, SUM(reached_confirmation) AS purchases
FROM vw_funnel_master GROUP BY device;
-- expect Desktop 60200 / 150, Mobile 30200 / 302

SELECT gender, COUNT(*) AS users, SUM(reached_confirmation) AS purchases
FROM vw_funnel_master GROUP BY gender;
-- expect Female 45075 / 241, Male 45325 / 211

SELECT cohort_month, COUNT(*) AS users, SUM(reached_confirmation) AS purchases
FROM vw_funnel_master GROUP BY cohort_month ORDER BY cohort_month;
-- expect 22600 users per month; purchases 189 / 173 / 44 / 46