{{ config(materialized='view') }}

WITH states_with_rank AS (
    SELECT
        state,
        country,
        ROW_NUMBER() OVER (
            PARTITION BY state, country
            ORDER BY city
        ) AS row_num
    FROM {{ ref('stg_cities') }}
    GROUP BY state, country, city
)

SELECT
    state,
    country
FROM states_with_rank
WHERE row_num = 1
