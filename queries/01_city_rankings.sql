-- =============================================================
-- City Rankings
-- Which cities have the most crime, the worst resolution rates,
-- and the most unusual crime profiles?
-- =============================================================


-- Q1: Which cities account for the largest share of total recorded crime?
-- Technique: SUM() OVER() window function for percentage of total

SELECT
    city,
    SUM(crime_count)                                          AS total_crimes,
    ROUND(SUM(crime_count) * 100.0
          / SUM(SUM(crime_count)) OVER (), 1)                 AS pct_of_total
FROM analytics.fct_crimes_by_city
GROUP BY city
ORDER BY total_crimes DESC;


-- Q2: Rank cities by their unsolved crime rate (highest = worst resolution)
-- Technique: RANK() window function, HAVING filter

SELECT
    city,
    SUM(crime_count)                                           AS total_crimes,
    SUM(unsolved_count)                                        AS total_unsolved,
    ROUND(SUM(unsolved_count) * 100.0
          / NULLIF(SUM(crime_count), 0), 1)                    AS unsolved_rate,
    RANK() OVER (
        ORDER BY SUM(unsolved_count) * 1.0
                 / NULLIF(SUM(crime_count), 0) DESC
    )                                                          AS rank_worst_resolution
FROM analytics.fct_crimes_by_city
GROUP BY city
HAVING SUM(crime_count) > 100
ORDER BY rank_worst_resolution;


-- Q3: What is the dominant crime type in each city?
-- Technique: ROW_NUMBER() for top-1-per-group, CTE

WITH ranked AS (
    SELECT
        city,
        category,
        SUM(crime_count) AS category_total,
        ROW_NUMBER() OVER (
            PARTITION BY city
            ORDER BY SUM(crime_count) DESC
        ) AS rn
    FROM analytics.fct_crimes_by_city
    GROUP BY city, category
)
SELECT city, category, category_total
FROM ranked
WHERE rn = 1
ORDER BY category_total DESC;


-- Q4: Which cities have a disproportionately high share of violent crime?
-- Technique: CTE join pattern, CASE WHEN for flagging outliers

WITH city_totals AS (
    SELECT city, SUM(crime_count) AS total_crimes
    FROM analytics.fct_crimes_by_city
    GROUP BY city
),
violent AS (
    SELECT city, SUM(crime_count) AS violent_crimes
    FROM analytics.fct_crimes_by_city
    WHERE category = 'violent-crime'
    GROUP BY city
)
SELECT
    ct.city,
    ct.total_crimes,
    COALESCE(v.violent_crimes, 0)                                AS violent_crimes,
    ROUND(COALESCE(v.violent_crimes, 0) * 100.0
          / ct.total_crimes, 1)                                  AS violent_pct,
    CASE
        WHEN COALESCE(v.violent_crimes, 0) * 100.0
             / ct.total_crimes > 30 THEN 'Above average'
        ELSE 'Within range'
    END                                                          AS flag
FROM city_totals ct
LEFT JOIN violent v ON ct.city = v.city
ORDER BY violent_pct DESC;
