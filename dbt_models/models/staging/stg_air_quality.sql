{{ config(materialized='view') }}

SELECT
    city,
    state,
    country,
    PARSE_TIMESTAMP('%Y-%m-%dT%H:%M:%SZ', current__pollution__ts)
        AS pollution_timestamp,
    current__pollution__aqius AS aqi_us,
    current__pollution__mainus AS main_pollutant_us,
    current__pollution__aqicn AS aqi_cn,
    current__pollution__maincn AS main_pollutant_cn,
    PARSE_TIMESTAMP('%Y-%m-%dT%H:%M:%SZ', current__weather__ts)
        AS weather_timestamp,
    current__weather__tp AS temperature,
    current__weather__pr AS pressure,
    current__weather__hu AS humidity,
    current__weather__ws AS wind_speed,
    current__weather__wd AS wind_direction,
    current__weather__ic AS weather_icon,
    geo_longitude AS longitude,
    geo_latitude AS latitude,
    EXTRACT(
        date FROM PARSE_TIMESTAMP('%Y-%m-%dT%H:%M:%SZ', current__pollution__ts)
    ) AS measurement_date,
    EXTRACT(
        time FROM PARSE_TIMESTAMP('%Y-%m-%dT%H:%M:%SZ', current__pollution__ts)
    ) AS measurement_time
FROM {{ source('raw', 'air_quality_raw') }}
