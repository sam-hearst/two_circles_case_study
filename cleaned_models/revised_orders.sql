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
        row_num,
        e_event_cod,
        evt_kind_nam),
      CAST(order_num AS string) AS order_id,
      DATE_TRUNC(CAST(ord_time AS date), day) AS order_time,
      DATE_TRUNC(CAST(tix_tran_time AS date), day) AS tix_tran_time,
      e_event_cod AS event_code,
      CASE
        WHEN evt_kind_nam LIKE '%MUSICAL%' THEN 'Musical'
        WHEN evt_kind_nam LIKE '%DRAMA%' THEN 'Drama'
        WHEN evt_kind_nam LIKE '%MUSEUM%' THEN 'Museum'
        WHEN evt_kind_nam LIKE '%OFF-BROADWAY/NY%' THEN 'Musical'
        WHEN evt_kind_nam LIKE '%OTHER VARIOUS%' THEN 'Other'
        WHEN evt_kind_nam LIKE '%WAY MUSICAL%' THEN 'Musical'
        WHEN evt_kind_nam LIKE '%OPERA%' THEN 'Opera'
        ELSE TRIM(evt_kind_nam)
    END
      AS event_kind_name
    FROM
      remove_dups )
  SELECT
    *
  FROM
    edits )