# UK Crime SQL Analytics

14 SQL queries analysing 99,673 police-recorded crimes across 10 UK cities (May — October 2024). Demonstrates window functions, CTEs, conditional aggregation, and analytical problem-solving.

## Data

| | |
|---|---|
| **Source** | [Police UK API](https://data.police.uk) |
| **Records** | 99,673 crime incidents |
| **Coverage** | 10 cities, 6 months (May — Oct 2024) |
| **Database** | PostgreSQL 15 |
| **Schema** | [schema.md](schema.md) |
| **Pipeline** | [uk-crime-pipeline](https://github.com/Pawansingh3889/uk-crime-pipeline) |

---

## Queries

### City Rankings ([01_city_rankings.sql](queries/01_city_rankings.sql))

| # | Question | Technique |
|---|---|---|
| 1 | Which cities account for the largest share of total crime? | `SUM() OVER()` |
| 2 | Rank cities by unsolved crime rate | `RANK()`, `HAVING` |
| 3 | What is the dominant crime type per city? | `ROW_NUMBER()`, CTE |
| 4 | Which cities have disproportionately high violent crime? | CTE join, `CASE WHEN` |

### Temporal Trends ([02_temporal_trends.sql](queries/02_temporal_trends.sql))

| # | Question | Technique |
|---|---|---|
| 5 | Month-over-month change in total crime? | `LAG()` |
| 6 | Cumulative crime per city over 6 months? | Running total `SUM() OVER()` |
| 7 | Which city had the largest single-month spike? | `LEAD()` |
| 8 | Which crime types peak in early vs late summer? | `FILTER` clause |

### Resolution Analysis ([03_resolution_analysis.sql](queries/03_resolution_analysis.sql))

| # | Question | Technique |
|---|---|---|
| 9 | Resolution breakdown by crime category? | `FILTER`, conditional aggregation |
| 10 | Did resolution rates improve or worsen over the period? | Self-join, `CASE WHEN` |
| 11 | Which categories most often end with no suspect? | Subquery, `FILTER` |

### Hotspot Analysis ([04_hotspot_analysis.sql](queries/04_hotspot_analysis.sql))

| # | Question | Technique |
|---|---|---|
| 12 | Top 3 highest-crime streets per city? | `ROW_NUMBER()` top-N-per-group |
| 13 | Are hotspot streets single-crime or diverse? | Multi-CTE join, concentration ratio |
| 14 | Streets that are hotspots for 3+ categories? | `STRING_AGG`, `HAVING` |

---

## SQL Techniques Used

| Technique | Queries |
|---|---|
| `RANK()` | Q2 |
| `ROW_NUMBER()` | Q3, Q12, Q13 |
| `LAG()` | Q5 |
| `LEAD()` | Q7 |
| Running total (`SUM() OVER()`) | Q1, Q6 |
| CTE | Q3, Q4, Q5, Q7, Q10, Q12, Q13 |
| `CASE WHEN` | Q4, Q10 |
| `HAVING` | Q2, Q8, Q11, Q14 |
| Subquery | Q11 |
| Self-join / multi-CTE join | Q4, Q10, Q13 |
| `FILTER` clause | Q8, Q9, Q11 |
| `STRING_AGG` | Q14 |
| `NULLIF` for safe division | Q2, Q5, Q8, Q10 |

---

## Key Findings

- **London accounts for 32.7% of all recorded crime** in the dataset, more than triple any other city. Its dominant category is theft-from-the-person (10,558 incidents), while every other city is dominated by violent crime.
- **October 2024 saw a 13.5% spike** compared to September, the largest month-over-month jump in the dataset. September was the lowest month overall (15,446 incidents).
- **Burglary drops 9.4% from early to late summer**, the sharpest seasonal decline. Theft-from-the-person moves the opposite direction, rising 3.4% into autumn.
- **"On or near Nightclub" in London is the single worst hotspot** with 3,033 incidents across 7 crime categories. Theft-from-the-person alone accounts for 1,247 of those.
- **Anti-social behaviour has a 0% resolution rate** — no outcome is ever recorded for this category. All other categories have outcomes recorded by the Police UK API.

---

## How to Run

Requires PostgreSQL 14+ with the schema from [schema.md](schema.md).

```bash
# Start local Postgres (Docker)
docker run -d --name crime-analytics \
  -e POSTGRES_PASSWORD=analytics123 \
  -e POSTGRES_DB=crime_analytics \
  -p 5433:5432 postgres:15

# Connect and run a query file
psql -h localhost -p 5433 -U postgres -d crime_analytics \
  -f queries/01_city_rankings.sql
```

Data is loaded from the [Police UK API](https://data.police.uk/docs/) using the ingestion script from [uk-crime-pipeline](https://github.com/Pawansingh3889/uk-crime-pipeline).
