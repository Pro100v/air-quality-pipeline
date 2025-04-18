{{ config(materialized='view') }}

WITH countries_with_rank AS (
    SELECT
        country,
        ROW_NUMBER() OVER (
            PARTITION BY country
            ORDER BY state
        ) AS row_num
    FROM {{ ref('stg_states') }}
    GROUP BY country, state
)

SELECT country
FROM countries_with_rank
WHERE row_num = 1
