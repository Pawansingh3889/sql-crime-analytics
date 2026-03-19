# Database Schema

PostgreSQL 15, database: `crime_analytics`

## raw.crimes

Source table loaded from Police UK API. 99,673 records.

| Column | Type | Description |
|---|---|---|
| crime_id | TEXT | PK component — Police UK incident ID |
| fetch_month | TEXT | PK component — YYYY-MM format |
| city | TEXT | PK component — one of 10 UK cities |
| category | TEXT | Crime type (e.g. violent-crime, shoplifting, burglary) |
| location_type | TEXT | Location category |
| latitude | TEXT | GPS latitude (stored as text) |
| longitude | TEXT | GPS longitude (stored as text) |
| street_name | TEXT | Street or landmark description |
| outcome_status | TEXT | Case outcome (null = no outcome recorded) |
| month | TEXT | Incident month YYYY-MM |
| loaded_at | TIMESTAMP | Row insert timestamp |

Primary key: `(crime_id, fetch_month, city)`

## analytics.fct_crimes_by_city

Aggregated by city, category, and month. 814 rows.

| Column | Type |
|---|---|
| city | TEXT |
| category | TEXT |
| month | TEXT |
| crime_count | BIGINT |
| unsolved_count | BIGINT |
| unsolved_pct | NUMERIC |

## analytics.fct_monthly_trend

Monthly totals per city. 60 rows (10 cities x 6 months).

| Column | Type |
|---|---|
| month | TEXT |
| city | TEXT |
| total_crimes | BIGINT |
| crime_types | BIGINT |
| unsolved | BIGINT |

## analytics.fct_crime_hotspots

Street-level crime concentration. 100 rows (top hotspots with 5+ incidents).

| Column | Type |
|---|---|
| city | TEXT |
| street_name | TEXT |
| category | TEXT |
| incident_count | BIGINT |

## Coverage

- **Cities**: Hull, London, Birmingham, Manchester, Leeds, Sheffield, Liverpool, Bristol, Nottingham, Newcastle
- **Period**: May — October 2024
- **Source**: data.police.uk (free, no auth)
