/* =====================================================================
   04_segmentation.sql
   Question : Does the funnel behave differently by device and gender?
   Output   : users, stage counts, step conversion %, overall conversion %
              and each segment's share of traffic and of purchases.
   Notes    : - Same pattern for every segment: SUM(flag) per stage,
                divided by the previous stage's SUM(flag).
              - NULLIF(x, 0) prevents divide-by-zero errors.
              - SUM(SUM(x)) OVER () is a window function on top of a
                GROUP BY: it adds up the group totals so each group's
                share of the whole can be shown in the same query.
              - All rates use ROUND(..., 2) so results match across queries.
   ===================================================================== */

USE sales_analysis;

/* ---- 4A. By device ------------------------------------------------- */
SELECT
    device,
    COUNT(*)                                                                      AS users,
    SUM(reached_search)                                                           AS search_users,
    SUM(reached_payment)                                                          AS payment_users,
    SUM(reached_confirmation)                                                     AS purchases,
    ROUND(100.0 * SUM(reached_search)       / NULLIF(SUM(reached_home), 0), 2)    AS home_to_search_pct,
    ROUND(100.0 * SUM(reached_payment)      / NULLIF(SUM(reached_search), 0), 2)  AS search_to_payment_pct,
    ROUND(100.0 * SUM(reached_confirmation) / NULLIF(SUM(reached_payment), 0), 2) AS payment_to_confirm_pct,
    ROUND(100.0 * SUM(reached_confirmation) / NULLIF(COUNT(*), 0), 2)             AS overall_conversion_pct,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2)                            AS traffic_share_pct,
    ROUND(100.0 * SUM(reached_confirmation)
          / SUM(SUM(reached_confirmation)) OVER (), 2)                            AS purchase_share_pct
FROM vw_funnel_master
GROUP BY device
ORDER BY overall_conversion_pct DESC;

/* ---- 4B. By gender ------------------------------------------------- */
SELECT
    gender,
    COUNT(*)                                                                      AS users,
    SUM(reached_search)                                                           AS search_users,
    SUM(reached_payment)                                                          AS payment_users,
    SUM(reached_confirmation)                                                     AS purchases,
    ROUND(100.0 * SUM(reached_search)       / NULLIF(SUM(reached_home), 0), 2)    AS home_to_search_pct,
    ROUND(100.0 * SUM(reached_payment)      / NULLIF(SUM(reached_search), 0), 2)  AS search_to_payment_pct,
    ROUND(100.0 * SUM(reached_confirmation) / NULLIF(SUM(reached_payment), 0), 2) AS payment_to_confirm_pct,
    ROUND(100.0 * SUM(reached_confirmation) / NULLIF(COUNT(*), 0), 2)             AS overall_conversion_pct,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2)                            AS traffic_share_pct,
    ROUND(100.0 * SUM(reached_confirmation)
          / SUM(SUM(reached_confirmation)) OVER (), 2)                            AS purchase_share_pct
FROM vw_funnel_master
GROUP BY gender
ORDER BY overall_conversion_pct DESC;

/* ---- 4C. Device x gender grid -------------------------------------- */
SELECT
    device,
    gender,
    COUNT(*)                                                                      AS users,
    SUM(reached_search)                                                           AS search_users,
    SUM(reached_payment)                                                          AS payment_users,
    SUM(reached_confirmation)                                                     AS purchases,
    ROUND(100.0 * SUM(reached_search)       / NULLIF(SUM(reached_home), 0), 2)    AS home_to_search_pct,
    ROUND(100.0 * SUM(reached_payment)      / NULLIF(SUM(reached_search), 0), 2)  AS search_to_payment_pct,
    ROUND(100.0 * SUM(reached_confirmation) / NULLIF(SUM(reached_payment), 0), 2) AS payment_to_confirm_pct,
    ROUND(100.0 * SUM(reached_confirmation) / NULLIF(COUNT(*), 0), 2)             AS overall_conversion_pct
FROM vw_funnel_master
GROUP BY device, gender
ORDER BY device, gender;