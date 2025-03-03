CREATE OR REPLACE TABLE
  take_home.revised_customers AS (
  WITH
    edits AS (
    SELECT
      * EXCEPT(first_nam,
        last_nam,
        hashed_id,
        country,
        state_name,
        order_num),
      first_nam AS first_name,
      last_nam AS last_name,
      CASE
        WHEN hashed_id LIKE 'NULL' THEN NULL
        ELSE hashed_id
    END
      AS hashed_id,
      CASE
        WHEN country LIKE '%USA%' THEN 'UNITED STATES'
        WHEN country LIKE '%GB%' THEN 'UNITED KINGDOM'
        WHEN country LIKE '%CA%' THEN 'CANADA'
        ELSE TRIM(country)
    END
      AS country,
      TRIM(state_name) AS state_name,
      CAST(order_num AS string) AS order_num
    FROM
      take_home.raw_customers)
  SELECT
    *
  FROM
    edits
  QUALIFY
    ROW_NUMBER() OVER (PARTITION BY order_num) = 1 )