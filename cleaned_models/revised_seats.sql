CREATE OR REPLACE TABLE
  take_home.revised_seats AS (
WITH
  edits AS (
  SELECT
    * EXCEPT(section,
      `row`),
    TRIM(section) AS section,
    TRIM(ROW) AS row_num,
  FROM
    take_home.raw_seats
  WHERE
    seat_retuned = 0),
  building_ids AS (
  SELECT
    CAST(order_num AS string) AS order_id,
    seannum || '-' || row_num || '-' || zone || '-' || section AS seat_id,
    * EXCEPT(order_num)
  FROM
    edits)
SELECT
  *
FROM
  building_ids
QUALIFY
  ROW_NUMBER() OVER (PARTITION BY order_id, seat_id ORDER BY CASE WHEN action = 'Scanned In' THEN 1 WHEN action = 'Created' THEN 2 ELSE 3 END ) = 1 )