CREATE OR REPLACE TABLE
  take_home.final AS (
  WITH
    orders_joined_to_seats_to_customers AS (
    SELECT
      *
    FROM
      take_home.final_orders orders
    JOIN
      take_home.final_seats seats
    USING
      (order_num)
    JOIN
      take_home.final_customers customers
    USING
      (order_num) )
  SELECT
    *
  FROM
    orders_joined_to_seats_to_customers)