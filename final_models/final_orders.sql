CREATE OR REPLACE TABLE
  take_home.final_orders AS (
  SELECT
    order_id,
    order_time,
    ord_location AS order_location,
    tix_tran_time,
    p_perf_date,
    event_code,
    event_kind_name
  FROM
    take_home.revised_orders )