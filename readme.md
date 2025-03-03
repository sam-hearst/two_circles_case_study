# Two Circles Case Study

# 1. Data Ingestion

## 1a

I'm choosing to query the data using BigQuery in Google Cloud Platform (GCP). In order to do so I first need to put the data into google cloud storage (S3 equivalent) and then will load it into BigQuery using BigQuery's built-in CLI command. Given that the data is pipe delimited, I will need to specify that in the command to load in the data. I also renamed the files to be snake cased.

## 1b

i. I am going to load the data into BigQuery using a CLI command.

ii. The datasets look to be, for the most part, in good shape. All the files have headers, and each row appears to have enough delimiters in comparison to the header columns. The data appears to be a more standard model of fact vs dimension tables with the orders table being the fact table. Both seat and customer information about an order can be done by joining `orders` to those respective tables. 

iii. I did not manipulate the data prior to loading it. I only renamed the files.

Here is the command that I used to load each csv file into BigQuery. My dataset is called `take_home`.

- customers
```bash
bq load \
--autodetect \
--source_format=CSV \
--skip_leading_rows=1 \
--field_delimiter="|" \
take_home.raw_customers \
gs://two_circles_data/case_study_customer.csv
```

- orders
```bash
bq load \
--autodetect \
--source_format=CSV \
--skip_leading_rows=1 \
--field_delimiter="|" \
take_home.raw_orders \
gs://two_circles_data/case_study_order.csv
```

- seats
```bash
bq load \
--autodetect \
--source_format=CSV \
--skip_leading_rows=1 \
--field_delimiter="|" \
take_home.raw_seats \
gs://two_circles_data/case_study_seat.csv
```

# 2. Data Cleaning and Standardization 

## 2a. 

I will talk about the standardizations that I made for each table here, and the sql is provided in the `cleaned_data` directory. 

- customers

1. renamed 'first_nam' and 'last_nam'. 
2. There are a couple thousand rows with a null `hashed_id`. However, it seems that the csv file had the string 'NULL' so I went ahead and made sure that those cells are null and don't have the string 'NULL'.
3. Looking at the country column I'm noticing some irregularies in naming conventions. Because the US, Canada, and the UK are the biggest customers, I just tried to standardize their names. Additionally I saw that there is some added white space at the end of these country names. I removed that white space as well.

```sql
SELECT
  country,
  COUNT(*) AS count
FROM
  take_home.raw_customers
GROUP BY
  1
ORDER BY
  count DESC
```
4. The state_name column also had the trailing white space issue so I went ahead and corrected it
5. about 200 rows where there are duplicate order numbers. I went ahead and removed these duplicates.

```sql
SELECT
  order_num,
  COUNT(*) AS cnt
FROM
  take_home.raw_customers
GROUP BY
  1
ORDER BY
  cnt desc
```


- orders

1. Again I'm seeing what I assume to be an error where the order number is counted twice or more. Because the order number should be unique I am going to go ahead and remove those duplicates. I looked at a few of these duplicates and saw no difference in other columns as well so I'm going ahead and removing them so we have a unique `order_num` for each row. 

```sql
SELECT
  order_num,
  COUNT(*)
FROM
  take_home.raw_orders
GROUP BY
  1
ORDER BY
  2 desc
```

2. The last portion of this presentation is only asking for visualizations by day so I'm going to go ahead and truncate all the dates up to the day. 


- seats

1. There is white space in the `section` and `row` columns so I removed that. `row` is also a order used in SQL syntax so I renamed it to `row_num`. 

2. Seats has a similar error where there appears to be some duplicate `order_num` rows. In the case of seats however, I'm also seeing that there are two rows with the same `order_num` but a different `seannum`.  This leads me to believe that duplicate order numbers should be tolerated in the final seats table provided they have a different `seannum`. I'm going to go ahead and make this change. I also looked at a particularly high duplicate `order_num` in the seats table: 190652366. From what I saw in that order number, the `seannum`, 

```sql

```

3. I am also seeing entries where is the `action` column is `Returned`. I'm not sure if I should be counting these towards my final calculations.

```sql
SELECT
  action,
  COUNT(*) AS cnt
FROM
  take_home.raw_seats
GROUP BY
  1
```

4. That is it for seats. I am going to have to aggregate up to the `order_num` column to get the USD sales, but that is something I will do in the next stage. 

# 3. Data Modeling 

You will need to develop a modelled view that integrates all data sets into one that the client can use for reporting. This view should be easily accessible to answer a variety of questions that the client may have. You will be asked to walk through your logic in building this view.

The orders table is the fact table while the seats and customers are the dimension tables. It makes sense for the analysis that I would join the seats and customers information to that table. However I want to be only joining on columns where I'm able to get all the information so I will be using an inner join for both joins. I need to filter data to United States in the customers table because my analysis is in USD, and I want to roll up the seats table to a unique order num per row. 


1. Modfying seats table

I want to modify the seats table so that each row is a unique order_num. To do that and to also get the number of tickets in an order, I needed to create a seat_id table. The seat_id column is created as so `seannum || '-' || row_num || '-' || zone || '-' || section AS seat_id`. This column will allow me to collect information on number of tickets which is needed for the data analysis portion. The information that I need is total price per order_num, and number of tickets per order_num. I'm also going to be thorough and remove duplicates where the order number is the same AND the seat_id is too. There are approximately 4000 of these duplicates. I looked through and the only difference between these rows is the `feeamt` column. I'm not sure but for this analysis I am going to assume that those should not be duplicated, and remove them. 

```sql
WITH
  edits_filtered AS (
  SELECT
    seannum || '-' || row_num || '-' || zone || '-' || section AS seat_id,
    *
  FROM
    take_home.revised_seats
  WHERE
    seat_retuned = 0 )
SELECT
  *,
  ROW_NUMBER() OVER (PARTITION BY order_num, seat_id) AS pot_dups
FROM
  edits_filtered
QUALIFY
  pot_dups > 1
ORDER BY
  order_num
```

2. Modifying customers table

The structure of the customers table does not have to be changed. The big thing that has to be changed is that I want to filter out all values that are not in the US. This is because my visualizations at the end are only concerned with partitioning the data via State. I'm also seeing some peculiarity with the states. While some states are real, other states are actually the names of other countries. I'm filtering all these out by simple saying that the state must be present in a tuple of all 50 states. Ultimately the only columns I need from the customers table is `order_num`, `state`, and `country`, so I'm just going to grab those nessecary columns. 

```sql
WITH
  filtered AS (
  SELECT
    *
  FROM
    take_home.revised_customers
  WHERE
    country = 'UNITED STATES')
SELECT
  state,
  COUNT(*) AS cnt
FROM
  filtered
GROUP BY
  1
ORDER BY
  cnt desc
```

3. Modifying orders table

The orders table likely does not have to be modified. The one thing might be to just grab the specific columns that I will need in this table. Let's go ahead and do that, and then I will save the final table that I use for my Tableau visualizations as `take_home.final`. I'm not sure which date I will use for the analysis, so let's go ahead and include all of them for now. Also, the final analysis wants to look at show Code so I will be sure to grab that column as well. While it is not asked for I'm also going to go ahead and grab `evt_kind_nam`. 

4. Final table

For this table I am going to join all the data from seats and customers into orders, and that should be the final table that I will use in my visualizations. I want no fanning in this table, and I also want information on only rows where there is information from all three tables so I will be using an inner join. This table will be located here: `final_models/final.sql`