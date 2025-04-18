{{ config(materialized='table') }}

WITH date_spine AS (
  {{ dbt_utils.date_spine(
      datepart="day",
      start_date="CAST('2025-01-01' AS DATE)",
      end_date="CAST(DATE_ADD(CURRENT_DATE(), INTERVAL 1 YEAR) AS DATE)"
     )
  }}
)

SELECT
  date_day as date_id,
  date_day as full_date,
  EXTRACT(YEAR FROM date_day) as year,
  EXTRACT(QUARTER FROM date_day) as quarter,
  EXTRACT(MONTH FROM date_day) as month,
  EXTRACT(DAY FROM date_day) as day_of_month,
  EXTRACT(DAYOFWEEK FROM date_day) as day_of_week,
  FORMAT_DATE('%A', date_day) as day_name,
  FORMAT_DATE('%B', date_day) as month_name,
  CASE
    WHEN EXTRACT(DAYOFWEEK FROM date_day) IN (1, 7) THEN TRUE
    ELSE FALSE
  END as is_weekend
FROM date_spine
