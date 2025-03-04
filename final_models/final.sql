CREATE OR REPLACE TABLE
  take_home.final AS (
  SELECT
    *
  FROM
    take_home.final_orders orders
  JOIN
    take_home.final_seats seats
  USING
    (order_id)
  JOIN
    take_home.final_customers customers
  USING
    (order_id) )