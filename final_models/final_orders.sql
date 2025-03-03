CREATE OR REPLACE TABLE
  take_home.final_orders AS (
  WITH
    cte AS (
    SELECT
      order_num,
      ord_time,
      tix_tran_time,
      p_perf_date,
      e_event_cod,
      evt_kind_nam
    FROM
      take_home.revised_orders )
  SELECT
    *
  FROM
    cte)