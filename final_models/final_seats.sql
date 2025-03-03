CREATE OR REPLACE TABLE
  take_home.final_seats AS (
  SELECT
    order_id,
    COUNT(DISTINCT seat_id) AS num_tickets,
    ROUND(SUM(price_per_seat),2) AS sale_price_usd
  FROM
    take_home.revised_seats
  GROUP BY
    1 )