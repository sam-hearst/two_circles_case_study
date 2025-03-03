CREATE OR REPLACE TABLE
  take_home.revised_seats AS (
  WITH
    edits AS (
    SELECT
      * EXCEPT(section,
        `row`,
        order_num),
      TRIM(section) AS section,
      TRIM(ROW) AS row_num,
      CAST(order_num AS string) AS order_num
    FROM
      take_home.raw_seats )
  SELECT
    *
  FROM
    edits )