# SQL Cheatsheet — Reusable Patterns from UK Crime Analytics

14 patterns I used across this project. Each one is generic enough to reuse on any dataset.

---

## 1. Percentage of Total (Window Function)

**Use when:** You want each row's share of the grand total without a subquery.

```sql
SELECT
    city,
    SUM(crime_count) AS total,
    ROUND(SUM(crime_count) * 100.0
          / SUM(SUM(crime_count)) OVER (), 1) AS pct_of_total
FROM table
GROUP BY city
ORDER BY total DESC;
```

**Logic:** `SUM(SUM(x)) OVER ()` computes the grand total across all groups. The inner SUM is the GROUP BY aggregate, the outer SUM OVER () is the window function running on top of it.

---

## 2. RANK / DENSE_RANK — Ranking with Ties

**Use when:** You need ordinal rankings but want ties handled properly.

```sql
SELECT
    city,
    unsolved_rate,
    RANK() OVER (ORDER BY unsolved_rate DESC) AS rank_worst
FROM (
    SELECT city,
           SUM(unsolved) * 100.0 / NULLIF(SUM(total), 0) AS unsolved_rate
    FROM table
    GROUP BY city
    HAVING SUM(total) > 100
) sub;
```

**RANK vs DENSE_RANK vs ROW_NUMBER:**
- `RANK()` — 1, 2, 2, 4 (skips after tie)
- `DENSE_RANK()` — 1, 2, 2, 3 (no skip)
- `ROW_NUMBER()` — 1, 2, 3, 4 (no ties, arbitrary order within tie)

---

## 3. Top-1-Per-Group (ROW_NUMBER + CTE)

**Use when:** You need the single best/worst/largest item within each group.

```sql
WITH ranked AS (
    SELECT
        city,
        category,
        SUM(count) AS total,
        ROW_NUMBER() OVER (
            PARTITION BY city
            ORDER BY SUM(count) DESC
        ) AS rn
    FROM table
    GROUP BY city, category
)
SELECT city, category, total
FROM ranked
WHERE rn = 1;
```

**Swap `rn = 1` for `rn <= 3` to get top-N per group.**

---

## 4. Top-N-Per-Group

**Use when:** Top 3 streets per city, top 5 products per category, etc.

```sql
WITH ranked AS (
    SELECT
        city,
        street_name,
        SUM(incidents) AS total,
        ROW_NUMBER() OVER (
            PARTITION BY city
            ORDER BY SUM(incidents) DESC
        ) AS rn
    FROM table
    GROUP BY city, street_name
)
SELECT * FROM ranked WHERE rn <= 3;
```

---

## 5. LAG — Month-over-Month Change

**Use when:** Comparing current row to the previous row (time series).

```sql
SELECT
    month,
    total,
    LAG(total) OVER (ORDER BY month) AS prev_month,
    total - LAG(total) OVER (ORDER BY month) AS abs_change,
    ROUND((total - LAG(total) OVER (ORDER BY month)) * 100.0
          / NULLIF(LAG(total) OVER (ORDER BY month), 0), 1) AS pct_change
FROM monthly_totals;
```

**Always wrap LAG in NULLIF to avoid division by zero on the first row.**

---

## 6. LEAD — Next Period Comparison

**Use when:** Looking forward instead of backward (forecasting spikes).

```sql
SELECT
    city,
    month,
    total_crimes,
    LEAD(total_crimes) OVER (PARTITION BY city ORDER BY month) AS next_month,
    LEAD(total_crimes) OVER (PARTITION BY city ORDER BY month) - total_crimes AS spike
FROM monthly_data;
```

---

## 7. Running Total (Cumulative SUM)

**Use when:** Tracking cumulative progress over time.

```sql
SELECT
    city,
    month,
    total_crimes,
    SUM(total_crimes) OVER (
        PARTITION BY city
        ORDER BY month
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative
FROM monthly_data;
```

**`ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW` is the default but being explicit is clearer.**

---

## 8. FILTER Clause — Conditional Aggregation (PostgreSQL)

**Use when:** You need COUNT/SUM with different WHERE conditions in the same query.

```sql
SELECT
    category,
    COUNT(*) AS total,
    COUNT(*) FILTER (WHERE month BETWEEN '2024-05' AND '2024-07') AS summer,
    COUNT(*) FILTER (WHERE month BETWEEN '2024-08' AND '2024-10') AS autumn,
    COUNT(*) FILTER (WHERE outcome IS NULL) AS no_outcome
FROM crimes
GROUP BY category;
```

**MySQL/SQL Server equivalent:** Use `SUM(CASE WHEN condition THEN 1 ELSE 0 END)`

---

## 9. Self-Join for First vs Last Period Comparison

**Use when:** Comparing the same entity across two different time points.

```sql
WITH first_period AS (
    SELECT city, metric FROM table WHERE month = (SELECT MIN(month) FROM table)
),
last_period AS (
    SELECT city, metric FROM table WHERE month = (SELECT MAX(month) FROM table)
)
SELECT
    f.city,
    f.metric AS first_value,
    l.metric AS last_value,
    l.metric - f.metric AS change,
    CASE
        WHEN l.metric < f.metric THEN 'Improved'
        WHEN l.metric > f.metric THEN 'Worsened'
        ELSE 'Stable'
    END AS trend
FROM first_period f
JOIN last_period l ON f.city = l.city;
```

---

## 10. CASE WHEN — Flag/Categorise Rows

**Use when:** Creating categorical labels from numeric data.

```sql
SELECT
    city,
    violent_pct,
    CASE
        WHEN violent_pct > 30 THEN 'Above average'
        WHEN violent_pct > 20 THEN 'Average'
        ELSE 'Below average'
    END AS flag
FROM city_stats;
```

---

## 11. CTE Join Pattern — Multiple Aggregations Combined

**Use when:** You need to join two different aggregations of the same table.

```sql
WITH city_totals AS (
    SELECT city, SUM(count) AS total FROM table GROUP BY city
),
category_subset AS (
    SELECT city, SUM(count) AS subset_total
    FROM table WHERE category = 'violent-crime' GROUP BY city
)
SELECT
    ct.city,
    ct.total,
    COALESCE(cs.subset_total, 0) AS subset,
    ROUND(COALESCE(cs.subset_total, 0) * 100.0 / ct.total, 1) AS pct
FROM city_totals ct
LEFT JOIN category_subset cs ON ct.city = cs.city;
```

**Use LEFT JOIN + COALESCE to handle cities with zero in the subset.**

---

## 12. Subquery in WHERE — Filter by Aggregated Condition

**Use when:** You want to filter rows based on an aggregate threshold computed separately.

```sql
SELECT category, COUNT(*) AS total
FROM crimes
WHERE category IN (
    SELECT category FROM crimes GROUP BY category HAVING COUNT(*) > 200
)
GROUP BY category;
```

---

## 13. STRING_AGG — Concatenate Values into One Cell

**Use when:** You want a comma-separated list within each group.

```sql
SELECT
    city,
    street_name,
    COUNT(DISTINCT category) AS num_categories,
    STRING_AGG(
        category || ' (' || incident_count || ')',
        ', ' ORDER BY incident_count DESC
    ) AS breakdown
FROM hotspots
GROUP BY city, street_name
HAVING COUNT(DISTINCT category) >= 3;
```

**MySQL equivalent:** `GROUP_CONCAT(category ORDER BY count DESC SEPARATOR ', ')`

---

## 14. Concentration Ratio — Is One Category Dominant?

**Use when:** Measuring whether a location/entity is dominated by one type or diversified.

```sql
WITH totals AS (
    SELECT city, street, SUM(count) AS total, COUNT(DISTINCT category) AS n_types
    FROM table GROUP BY city, street HAVING SUM(count) > 50
),
top AS (
    SELECT city, street, category, count,
           ROW_NUMBER() OVER (PARTITION BY city, street ORDER BY count DESC) AS rn
    FROM table
)
SELECT
    t.city, t.street, t.total, t.n_types,
    top.category AS dominant,
    ROUND(top.count * 100.0 / t.total, 1) AS dominant_pct
FROM totals t
JOIN top ON t.city = top.city AND t.street = top.street AND top.rn = 1;
```

**If dominant_pct > 70% = concentrated. If < 40% = diversified.**

---

## Quick Reference Table

| Pattern | Function | Use Case |
|---|---|---|
| % of total | `SUM() OVER ()` | Market share, contribution |
| Ranking | `RANK() / DENSE_RANK()` | Leaderboards, worst/best |
| Top-1 per group | `ROW_NUMBER() + WHERE rn=1` | Best seller per category |
| Top-N per group | `ROW_NUMBER() + WHERE rn<=N` | Top 3 per region |
| Previous row | `LAG()` | MoM change, YoY comparison |
| Next row | `LEAD()` | Spike detection, forecasting |
| Running total | `SUM() OVER (ORDER BY)` | Cumulative revenue |
| Conditional count | `FILTER (WHERE ...)` | Split counts in one query |
| Period comparison | Self-join CTEs | First vs last month |
| Categorise | `CASE WHEN` | Flag outliers, create buckets |
| Multiple aggregations | CTE + JOIN | Compare subset to total |
| Threshold filter | Subquery in WHERE | Only categories with 200+ rows |
| Concatenate | `STRING_AGG()` | Comma-separated breakdown |
| Dominance check | ROW_NUMBER + ratio | Is one type > 70%? |

---

## NULLIF — Prevent Division by Zero

Always use when dividing:
```sql
ROUND(x * 100.0 / NULLIF(y, 0), 1)
```
Returns NULL instead of crashing if y = 0.

## COALESCE — Default for Missing Values

```sql
COALESCE(nullable_column, 0)        -- numeric default
COALESCE(nullable_column, 'N/A')    -- text default
```
