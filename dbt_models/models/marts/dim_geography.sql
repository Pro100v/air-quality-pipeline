{{ config(materialized='table') }}

WITH city_coords AS (
  SELECT
    city,
    state,
    country,
    AVG(geo_longitude) as longitude,
    AVG(geo_latitude) as latitude
  FROM {{ ref('stg_air_quality') }}
  GROUP BY city, state, country
)

SELECT
  {{ dbt_utils.generate_surrogate_key(['city', 'state', 'country']) }} as geography_id,
  c.city,
  s.state,
  co.country,
  cc.longitude,
  cc.latitude
FROM {{ ref('stg_cities') }} c
JOIN {{ ref('stg_states') }} s ON c.state = s.state AND c.country = s.country
JOIN {{ ref('stg_countries') }} co ON s.country = co.country
LEFT JOIN city_coords cc ON c.city = cc.city AND c.state = cc.state AND c.country = cc.country
