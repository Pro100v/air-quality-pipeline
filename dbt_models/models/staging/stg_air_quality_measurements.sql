{{
    config(
        materialized='view',
        description='Staged air quality measurements'
    )
}}

WITH source_data AS (
    SELECT
        location_id,
        location,
        parameter,
        value,
        unit,
        city,
        country,
        coordinates.latitude AS latitude,
        coordinates.longitude AS longitude,
        TIMESTAMP(date.utc) AS date_utc,
        TIMESTAMP(date.local) AS date_local,
        TIMESTAMP(ingestion_timestamp) AS ingestion_timestamp
    FROM
        {{ source('air_quality', 'measurements') }}
)

SELECT
    -- Генерируем уникальный ID измерения
    {{ dbt_utils.generate_surrogate_key(['location_id', 'parameter', 'date_utc']) }} AS measurement_id,
    *,
    
    -- Добавляем данные для анализа
    EXTRACT(YEAR FROM date_utc) AS year,
    EXTRACT(MONTH FROM date_utc) AS month,
    EXTRACT(DAY FROM date_utc) AS day,
    EXTRACT(HOUR FROM date_utc) AS hour,
    EXTRACT(DAYOFWEEK FROM date_utc) AS day_of_week
FROM
    source_data
WHERE
    -- Исключаем записи с NULL значениями в ключевых полях
    location IS NOT NULL
    AND parameter IS NOT NULL
    AND value IS NOT NULL
    AND date_utc IS NOT NULL
