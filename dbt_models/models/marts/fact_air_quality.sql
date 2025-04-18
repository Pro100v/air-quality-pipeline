{{ config(materialized='table') }}

SELECT
  {{ dbt_utils.generate_surrogate_key(['city', 'state', 'country', 'measurement_date', 'measurement_time']) }} as measurement_id,
  {{ dbt_utils.generate_surrogate_key(['city', 'state', 'country']) }} as geography_id,
  CAST(measurement_date AS STRING) as date_id,
  
  -- Time attributes
  pollution_timestamp,
  weather_timestamp,
  measurement_date,
  measurement_time,
  
  -- Air quality metrics
  aqi_us,
  main_pollutant_us,
  aqi_cn,
  main_pollutant_cn,
  
  -- Weather metrics
  temperature,
  pressure,
  humidity,
  wind_speed,
  wind_direction,
  weather_icon,
  
  -- Air quality categories
  CASE
    WHEN aqi_us BETWEEN 0 AND 50 THEN 'Good'
    WHEN aqi_us BETWEEN 51 AND 100 THEN 'Moderate'
    WHEN aqi_us BETWEEN 101 AND 150 THEN 'Unhealthy for Sensitive Groups'
    WHEN aqi_us BETWEEN 151 AND 200 THEN 'Unhealthy'
    WHEN aqi_us BETWEEN 201 AND 300 THEN 'Very Unhealthy'
    ELSE 'Hazardous'
  END as air_quality_category_us,
  
  CASE
    WHEN aqi_cn BETWEEN 0 AND 50 THEN 'Good'
    WHEN aqi_cn BETWEEN 51 AND 100 THEN 'Moderate'
    WHEN aqi_cn BETWEEN 101 AND 150 THEN 'Lightly Polluted'
    WHEN aqi_cn BETWEEN 151 AND 200 THEN 'Moderately Polluted'
    WHEN aqi_cn BETWEEN 201 AND 300 THEN 'Heavily Polluted'
    ELSE 'Severely Polluted'
  END as air_quality_category_cn
  
FROM {{ ref('stg_air_quality') }}
