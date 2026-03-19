-- =============================================================
-- Resolution Analysis
-- How effectively are crimes being resolved?
-- Which categories and cities have the worst outcomes?
-- =============================================================


-- Q9: What is the resolution breakdown by crime category?
-- Technique: FILTER clause for conditional aggregation

SELECT
    category,
    COUNT(*)                                                     AS total,
    COUNT(*) FILTER (WHERE outcome_status IS NOT NULL
                       AND outcome_status <> 'Under investigation')
                                                                 AS resolved,
    COUNT(*) FILTER (WHERE outcome_status IS NULL)               AS no_outcome,
    COUNT(*) FILTER (WHERE outcome_status = 'Under investigation')
                                                                 AS under_investigation,
    ROUND(
        COUNT(*) FILTER (WHERE outcome_status IS NOT NULL
                           AND outcome_status <> 'Under investigation')
        * 100.0 / COUNT(*), 1
    )                                                            AS resolution_rate_pct
FROM raw.crimes
GROUP BY category
ORDER BY resolution_rate_pct ASC;


-- Q10: Has resolution improved or worsened between the first and last month per city?
-- Technique: Self-join between first/last months, CASE WHEN

WITH first_month AS (
    SELECT city,
           ROUND(SUM(unsolved_count) * 100.0
                 / NULLIF(SUM(crime_count), 0), 1) AS unsolved_pct
    FROM analytics.fct_crimes_by_city
    WHERE month = (SELECT MIN(month) FROM analytics.fct_crimes_by_city)
    GROUP BY city
),
last_month AS (
    SELECT city,
           ROUND(SUM(unsolved_count) * 100.0
                 / NULLIF(SUM(crime_count), 0), 1) AS unsolved_pct
    FROM analytics.fct_crimes_by_city
    WHERE month = (SELECT MAX(month) FROM analytics.fct_crimes_by_city)
    GROUP BY city
)
SELECT
    f.city,
    f.unsolved_pct                                              AS first_month_unsolved,
    l.unsolved_pct                                              AS last_month_unsolved,
    l.unsolved_pct - f.unsolved_pct                             AS change_pp,
    CASE
        WHEN l.unsolved_pct < f.unsolved_pct THEN 'Improved'
        WHEN l.unsolved_pct > f.unsolved_pct THEN 'Worsened'
        ELSE 'Stable'
    END                                                         AS trend
FROM first_month f
JOIN last_month l ON f.city = l.city
ORDER BY change_pp;


-- Q11: Which crime categories most frequently end with no suspect identified?
-- Technique: Subquery for filtering, FILTER clause

SELECT
    category,
    COUNT(*)                                                     AS total_crimes,
    COUNT(*) FILTER (
        WHERE outcome_status = 'Investigation complete; no suspect identified'
    )                                                            AS no_suspect,
    ROUND(
        COUNT(*) FILTER (
            WHERE outcome_status = 'Investigation complete; no suspect identified'
        ) * 100.0 / COUNT(*), 1
    )                                                            AS no_suspect_pct
FROM raw.crimes
WHERE category IN (
    SELECT category
    FROM raw.crimes
    GROUP BY category
    HAVING COUNT(*) > 200
)
GROUP BY category
ORDER BY no_suspect_pct DESC;
