{{ config(materialized='table') }}

SELECT
    f.measurement_id,
    g.city,
    g.state,
    g.country,
    g.longitude,
    g.latitude,
    f.pollution_timestamp,
    f.weather_timestamp,
    f.measurement_date,
    f.measurement_time,
    f.aqi_us,
    f.main_pollutant_us,
    f.aqi_cn,
    f.main_pollutant_cn,
    f.air_quality_category_us,
    f.air_quality_category_cn,
    f.temperature,
    f.pressure,
    f.humidity,
    f.wind_speed,
    f.wind_direction,
    f.weather_icon
FROM {{ ref('fact_air_quality') }} f
JOIN {{ ref('dim_geography') }} g ON f.geography_id = g.geography_id
