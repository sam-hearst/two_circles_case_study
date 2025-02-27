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
  COUNT(*) AS cnt
FROM
  take_home.raw_customers
GROUP BY
  1
ORDER BY
  cnt desc
```

