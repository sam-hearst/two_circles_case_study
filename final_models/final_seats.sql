CREATE OR REPLACE TABLE
  take_home.final_seats AS (
  WITH
    edits_filtered AS (
    SELECT
      seannum || '-' || row_num || '-' || zone || '-' || section AS seat_id,
      *
    FROM
      take_home.revised_seats
    WHERE
      seat_retuned = 0 ),
    dedupe AS (
    SELECT
      *
    FROM
      edits_filtered
    QUALIFY
      ROW_NUMBER() OVER (PARTITION BY order_num, seat_id) = 1 ),
    aggregate_to_order_num AS (
    SELECT
      order_num,
      COUNT(DISTINCT seat_id) AS num_tickets,
      ROUND(SUM(price_per_seat),2) AS price_usd
    FROM
      dedupe
    GROUP BY
      1 )
  SELECT
    *
  FROM
    aggregate_to_order_num )