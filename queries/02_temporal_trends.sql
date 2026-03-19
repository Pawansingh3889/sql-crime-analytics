-- =============================================================
-- Temporal Trends
-- How does crime change over time? Which months spike?
-- Are there seasonal patterns by crime type?
-- =============================================================


-- Q5: What is the month-over-month change in total crime across all cities?
-- Technique: LAG() window function for period comparison

WITH monthly AS (
    SELECT
        month,
        SUM(total_crimes) AS total
    FROM analytics.fct_monthly_trend
    GROUP BY month
)
SELECT
    month,
    total,
    LAG(total) OVER (ORDER BY month)                           AS prev_month,
    total - LAG(total) OVER (ORDER BY month)                   AS abs_change,
    ROUND((total - LAG(total) OVER (ORDER BY month)) * 100.0
          / NULLIF(LAG(total) OVER (ORDER BY month), 0), 1)   AS pct_change
FROM monthly
ORDER BY month;


-- Q6: Cumulative crime count per city across the reporting period
-- Technique: SUM() OVER(PARTITION BY ... ORDER BY ...) running total

SELECT
    city,
    month,
    total_crimes,
    SUM(total_crimes) OVER (
        PARTITION BY city
        ORDER BY month
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_crimes
FROM analytics.fct_monthly_trend
ORDER BY city, month;


-- Q7: Which city experienced the largest single-month spike?
-- Technique: LEAD() window function

WITH changes AS (
    SELECT
        city,
        month,
        total_crimes,
        LEAD(total_crimes) OVER (
            PARTITION BY city ORDER BY month
        )                                                       AS next_month_crimes,
        LEAD(total_crimes) OVER (
            PARTITION BY city ORDER BY month
        ) - total_crimes                                        AS spike
    FROM analytics.fct_monthly_trend
)
SELECT city, month, total_crimes, next_month_crimes, spike
FROM changes
WHERE spike IS NOT NULL
ORDER BY spike DESC
LIMIT 5;


-- Q8: Which crime categories peak in early summer vs late summer?
-- Technique: FILTER clause (PostgreSQL-specific), HAVING

SELECT
    category,
    COUNT(*) FILTER (WHERE month BETWEEN '2024-05' AND '2024-07') AS may_jul_count,
    COUNT(*) FILTER (WHERE month BETWEEN '2024-08' AND '2024-10') AS aug_oct_count,
    ROUND(
        (COUNT(*) FILTER (WHERE month BETWEEN '2024-05' AND '2024-07')
         - COUNT(*) FILTER (WHERE month BETWEEN '2024-08' AND '2024-10'))
        * 100.0
        / NULLIF(COUNT(*) FILTER (WHERE month BETWEEN '2024-05' AND '2024-07'), 0),
        1
    )                                                             AS pct_change_half
FROM raw.crimes
GROUP BY category
HAVING COUNT(*) > 500
ORDER BY pct_change_half DESC;
