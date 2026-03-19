-- =============================================================
-- Hotspot Analysis
-- Where are crimes concentrated? Are hotspot streets dominated
-- by one crime type or spread across many?
-- =============================================================


-- Q12: Top 3 highest-crime streets in each city
-- Technique: ROW_NUMBER() for top-N-per-group

WITH ranked_streets AS (
    SELECT
        city,
        street_name,
        SUM(incident_count)                                     AS total_incidents,
        ROW_NUMBER() OVER (
            PARTITION BY city
            ORDER BY SUM(incident_count) DESC
        )                                                       AS street_rank
    FROM analytics.fct_crime_hotspots
    GROUP BY city, street_name
)
SELECT city, street_rank, street_name, total_incidents
FROM ranked_streets
WHERE street_rank <= 3
ORDER BY city, street_rank;


-- Q13: Are hotspot streets dominated by one crime type or spread across many?
-- Technique: Multi-CTE join, concentration ratio

WITH street_totals AS (
    SELECT
        city,
        street_name,
        SUM(incident_count) AS total_incidents,
        COUNT(DISTINCT category) AS distinct_categories
    FROM analytics.fct_crime_hotspots
    GROUP BY city, street_name
    HAVING SUM(incident_count) > 50
),
top_category AS (
    SELECT
        city,
        street_name,
        category,
        incident_count,
        ROW_NUMBER() OVER (
            PARTITION BY city, street_name
            ORDER BY incident_count DESC
        ) AS rn
    FROM analytics.fct_crime_hotspots
)
SELECT
    st.city,
    st.street_name,
    st.total_incidents,
    st.distinct_categories,
    tc.category                                                 AS dominant_category,
    ROUND(tc.incident_count * 100.0
          / st.total_incidents, 1)                              AS dominant_pct
FROM street_totals st
JOIN top_category tc
    ON st.city = tc.city
   AND st.street_name = tc.street_name
   AND tc.rn = 1
ORDER BY st.total_incidents DESC
LIMIT 15;


-- Q14: Streets that are hotspots for 3+ different crime categories
-- Technique: STRING_AGG, HAVING for multi-category filtering

SELECT
    h.city,
    h.street_name,
    COUNT(DISTINCT h.category)                                  AS hotspot_categories,
    SUM(h.incident_count)                                       AS total_incidents,
    STRING_AGG(
        h.category || ' (' || h.incident_count || ')',
        ', ' ORDER BY h.incident_count DESC
    )                                                           AS category_breakdown
FROM analytics.fct_crime_hotspots h
WHERE h.incident_count >= 10
GROUP BY h.city, h.street_name
HAVING COUNT(DISTINCT h.category) >= 3
ORDER BY hotspot_categories DESC, total_incidents DESC;
