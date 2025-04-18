{{ config(materialized='view') }}

WITH cities_with_rank AS (
    SELECT
        city,
        state,
        country,
        ROW_NUMBER()
            OVER (
                PARTITION BY city, state, country
                ORDER BY current__pollution__ts DESC
            )
            AS row_num
    FROM {{ source('raw', 'air_quality_raw') }}
)

SELECT
    city,
    state,
    country
FROM cities_with_rank
WHERE row_num = 1
