CREATE OR REPLACE TABLE
  take_home.revised_orders AS (
  WITH
    remove_dups AS (
    SELECT
      *,
      ROW_NUMBER() OVER (PARTITION BY order_num) AS row_num
    FROM
      take_home.raw_orders
    QUALIFY
      row_num = 1 ),
    edits AS (
    SELECT
      * EXCEPT(order_num,
        ord_time,
        tix_tran_time,
        row_num),
      CAST(order_num AS string) AS order_num,
      DATE_TRUNC(CAST(ord_time AS date), day) AS ord_time,
      DATE_TRUNC(CAST(tix_tran_time AS date), day) AS tix_tran_time
    FROM
      remove_dups )
  SELECT
    *
  FROM
    edits )