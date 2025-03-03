# Two Circles Case Study

# Part 1: Data Modeling

## 1. Data Ingestion

### 1a.

I'm choosing to query the data using BigQuery in Google Cloud Platform (GCP). In order to do so I need to put the data into google cloud storage (S3 equivalent), and load it into BigQuery using BigQuery's built-in CLI command. Given that the data is pipe delimited, I will need to specify that in the command to load in the data.

### 1b

i. I am going to load the data into BigQuery using CLI commands in Google's Cloud Shell. If this were a production setting and I was loading in many csv files, I would try to create an lcsv tool. I could also use an ETL tool like Fivetran or AirByte.

ii. The datasets look to be, for the most part, in good shape. All the files have headers, and each row appears to have enough delimiters in comparison to the header columns. The data appears to be a more standard model of fact vs dimension tables with `orders` being the fact table and `customers` and `seats` being the dimensional tables.

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

## 2. Data Cleaning and Standardization

***NOTE***: For this section I was not sure how much the data would be changed and standardized. I didn't want to make too many major changes. Instead I focused my attention on cleaning the standardizing the columns that I would be using in the analysis portion of this case study. I made more structural changes to the data in the `Data Modeling` portion of this take home. I will talk about the standardizations that I made for each table here, and the SQL is provided in the `cleaned_data` directory.

### 2a. 

#### Customers

1. renamed several columns so that they are most clear and explicit. 
2. There are a couple thousand rows with a null `hashed_id`. It seems that the csv file had the string 'NULL' so I made sure that those cells are null and don't have the string 'NULL'.
3. Looking at the country column I'm noticing some irregularies in naming conventions. Because the US, Canada, and the UK are the biggest customers, I just tried to standardize their names. 

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

4. I removed whitespace from the columns that had it.
5. There are about 200 rows where there are duplicate order numbers. I went ahead and removed these duplicates.

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


#### Orders

1. I'm seeing what I assume to be an error where the order number is counted twice or more. Because the order number should be unique I am going to go ahead and remove those duplicates. I looked at a few of these duplicates and saw no difference in other columns, so I'm removing them so we have a unique `order_num` for each row. I am also renaming the order number column in each table to `order_id`.

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
3. I renamed columns for greater clarity
4. Standardized the categories in `evt_kind_nam` because I will need them later on.


#### Seats

1. There is white space in the `section` and `row` columns so I removed that. `row` is also a order used in SQL syntax so I renamed it to `row_num`. 
2. Created a `seat_id` column as a concatenation of multiple descriptors of the seat.

3. Seats has a similar error where there appears to be some duplicate `order_num` rows. In the case of seats however, I'm also seeing that there are two rows with the same `order_num` but a different `seannum`.  This leads me to believe that duplicate order numbers should be tolerated in the final seats table provided they are at a different seat. To do this I first need to create a `seat_id` column. I am concatenating together a number of seat descriptors for that ID. After I've done that I've checked for duplicates, and there are about 4,000 rows that still have duplicates. I've gone ahead and removed these duplicates and made sure that if the `action` is "Scanned In" that those rows are kept. 

```sql
WITH
  edits AS (
  SELECT
    * EXCEPT(section,
      `row`),
    TRIM(section) AS section,
    TRIM(ROW) AS row_num,
  FROM
    take_home.raw_seats ),
  building_ids AS (
  SELECT
    CAST(order_num AS string) AS order_id,
    seannum || '-' || row_num || '-' || zone || '-' || section AS seat_id,
    * EXCEPT(order_num)
  FROM
    edits)
SELECT
  order_id,
  seat_id,
  COUNT(*) AS cnt
FROM
  building_ids
GROUP BY
  1,
  2
ORDER BY
  3 desc
```

4. I also removed all entries where `seat_retuned` was 1 indicating a return / refund.

## 3. Data Modeling 

Now that the data has been cleaned and standardized, I need to combine all three tables into one. The orders table is the table that is most easy to work from. I want to join the customers and seats table to the orders table, and I want to only include pertinent information. I also will be using an inner join because I want the rows in the final view to have information from all three tables.

All of my work in modifying the three tables and my final view / table can be found in the `final_models` directory.


1. Modfying seats table

The major change that I have to make to the seats table before joining to orders is to roll up the data to the order level. The two major metrics that I need from the seats table are price per order and number of tickets per order. These can both be done through the aggregation.

2. Modifying customers table

I want to filter out all values that are not in the US. This is because my visualizations at the end are only concerned with partitioning the data via state. I'm also seeing some peculiarity with the states, and used some additional logic to ensure that the customers are in the United States. In the end, the only columns I need from the customers table are `order_num`, `customer_id`, `state`, and `country`, so I'm just going to grab those nessecary columns. 

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

The orders table likely does not have to be modified. I only want to include nessecary columns. I grabbed all the columns that are nessecary for the visualization, and a few more I thought would be interesting to examine.

4. Final table

For this table I am going to join all the data from seats and customers into orders, and that should be the final table that I will use in my visualizations. I want no fanning in this table, and I also want information on only rows where there is information from all three tables so I will be using an inner join. This table will be located here: `final_models/final.sql`


# Part 2: Data Analysis

## C.

A dataset that could supplement the data that I already have would be one that goes into more detail about the events that are being described here. I'm working with a client and I want to understand how to increase ticket sales for different shows. I think something that could have been very helpful would be to have more metadata on the shows that this data is representing. If I were to get that data then I would be more able to analyze with shows are bringing in the most sales, customes, and tickets. Then I could start to look at how to improve those numbers, and which events need more attention. 