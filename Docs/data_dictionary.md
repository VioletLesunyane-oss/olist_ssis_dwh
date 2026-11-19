# Data Dictionary: Olist E-Commerce Data Warehouse (`olist_dwh`)

An end to end SSIS medallion pipeline on SQL Server (Bronze, Silver and Gold). This document describes every table and column in the warehouse.

| Layer | Schema | Purpose | Tables |
| :--- | :--- | :--- | ---: |
| Audit | `etl` | Pipeline runs, row counts and rejected rows | 3 |
| Bronze | `bronze` | Raw landing zone, exact copy of the CSV files | 9 |
| Silver | `silver` | Typed, cleansed and de-duplicated data | 9 |
| Gold | `gold` | Star schema for reporting: 7 dimensions and 3 facts | 10 |

## Contents

1. [ETL tracking and audit layer](#1-etl-tracking-and-audit-layer)
2. [Bronze layer (raw landing zone)](#2-bronze-layer-raw-landing-zone)
3. [Silver layer (cleansed and standardised)](#3-silver-layer-cleansed-and-standardised)
4. [Gold layer (business reporting star schema)](#4-gold-layer-business-reporting-star-schema)
5. [Loading rules and naming conventions](#5-loading-rules-and-naming-conventions)

---

## 1. ETL tracking and audit layer

> The etl schema records every pipeline run, how many rows each table loaded and any rows that were rejected, so every load is transparent and auditable. Audit tables are append only: a new batch_id is created on every run and they are never truncated.

### `etl.batch_log`

**Purpose:** Records each end to end run of the master pipeline (00_master.dtsx).  
**Grain:** One row per pipeline run.  

| Column | Data type | Key or constraint | Description |
| :--- | :--- | :--- | :--- |
| `batch_id` | INT | Primary key (identity) | Unique id created automatically at the start of every run. |
| `start_ts` | DATETIME2 | NOT NULL, default current time | Date and time the run started. |
| `end_ts` | DATETIME2 | NULL | Date and time the run finished. NULL while the run is still going. |
| `status` | NVARCHAR(20) | NOT NULL, default running | Run outcome: running, succeeded or failed (enforced by a check constraint). |

### `etl.load_log`

**Purpose:** Records how many rows were read, written and rejected for each table loaded in each run.  
**Grain:** One row per table per package run.  

| Column | Data type | Key or constraint | Description |
| :--- | :--- | :--- | :--- |
| `batch_id` | INT | NOT NULL | Run that did the load. Matches etl.batch_log.batch_id. |
| `package` | NVARCHAR(100) | NOT NULL | SSIS package that loaded the table, for example 01_bronze_load.dtsx. |
| `table_name` | NVARCHAR(200) | NOT NULL | Target table, for example silver.orders. |
| `rows_read` | INT | NULL | Rows read from the source file or upstream table. |
| `rows_written` | INT | NULL | Rows inserted into the target table. |
| `rows_error` | INT | NULL | Rows sent to etl.error_rows. |
| `ts` | DATETIME2 | NOT NULL, default current time | When the entry was written. |

### `etl.error_rows`

**Purpose:** Holds rows rejected during Silver loads, so bad data is captured instead of silently dropped.  
**Grain:** One row per rejected record.  

| Column | Data type | Key or constraint | Description |
| :--- | :--- | :--- | :--- |
| `batch_id` | INT | NOT NULL | Run during which the row was rejected. |
| `table_name` | NVARCHAR(200) | NOT NULL | Target table the row was meant for, for example silver.orders. |
| `error_code` | INT | NULL | SSIS error code, or -1 for a custom rule such as a missing key. |
| `error_column` | NVARCHAR(200) | NULL | Column, or SSIS column id, that caused the error. |
| `raw_row` | NVARCHAR(MAX) | NULL | The rejected row as pipe delimited text. |

---

## 2. Bronze layer (raw landing zone)

> The bronze schema holds exact copies of the nine raw Olist CSV files as text (NVARCHAR) with no cleaning. Every table is emptied and reloaded on every run, so rows are never appended twice. Source column names are kept exactly as they arrive, including the spelling mistakes in the products file.

### Audit columns on every Bronze table

| Column | Data type | Description |
| :--- | :--- | :--- |
| `dwh_load_ts` | DATETIME2 | Time the row landed in Bronze. Set by SQL Server (default current time). |
| `dwh_source_file` | NVARCHAR(260) | Name of the CSV file the row came from. Set by SSIS. |
| `dwh_batch_id` | INT | Run id from etl.batch_log. Set by SSIS. |

### The nine Bronze tables

| Table | Source CSV file | Grain | Raw columns |
| :--- | :--- | :--- | :--- |
| `bronze.olist_customers` | olist_customers_dataset.csv | One row per order level customer record | customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state |
| `bronze.olist_geolocation` | olist_geolocation_dataset.csv | One row per raw coordinate reading | geolocation_zip_code_prefix, geolocation_lat, geolocation_lng, geolocation_city, geolocation_state |
| `bronze.olist_orders` | olist_orders_dataset.csv | One row per order | order_id, customer_id, order_status, order_purchase_timestamp, order_approved_at, order_delivered_carrier_date, order_delivered_customer_date, order_estimated_delivery_date |
| `bronze.olist_order_items` | olist_order_items_dataset.csv | One row per item in an order | order_id, order_item_id, product_id, seller_id, shipping_limit_date, price, freight_value |
| `bronze.olist_order_payments` | olist_order_payments_dataset.csv | One row per payment line | order_id, payment_sequential, payment_type, payment_installments, payment_value |
| `bronze.olist_order_reviews` | olist_order_reviews_dataset.csv | One row per raw review | review_id, order_id, review_score, review_comment_title, review_comment_message (NVARCHAR(MAX)), review_creation_date, review_answer_timestamp |
| `bronze.olist_products` | olist_products_dataset.csv | One row per product | product_id, product_category_name, product_name_lenght, product_description_lenght, product_photos_qty, product_weight_g, product_length_cm, product_height_cm, product_width_cm |
| `bronze.olist_sellers` | olist_sellers_dataset.csv | One row per seller | seller_id, seller_zip_code_prefix, seller_city, seller_state |
| `bronze.product_category_name_translation` | product_category_name_translation.csv | One row per Portuguese category | product_category_name, product_category_name_english |

> Note: product_name_lenght and product_description_lenght are misspelt in the source file. They are kept as they are in Bronze and corrected to length in Silver.

---

## 3. Silver layer (cleansed and standardised)

> The silver schema holds typed, trimmed and de-duplicated data: zip prefixes are padded to five digits, misspelt columns are fixed, product categories are translated and every date and amount has a real data type. Rows that fail a rule are sent to etl.error_rows instead of being dropped.

### Audit columns on every Silver table

| Column | Data type | Description |
| :--- | :--- | :--- |
| `dwh_load_ts` | DATETIME2 | Time the row was loaded into Silver. Set by SQL Server (default current time). |
| `dwh_batch_id` | INT | Run id from etl.batch_log. Set by SSIS. |

### `silver.customers`

**Grain:** One row per customer_id (one per order). The real person is customer_unique_id.  

| Column | Data type | Key or constraint | Transformation rule |
| :--- | :--- | :--- | :--- |
| `customer_id` | NVARCHAR(50) | Primary key | Trimmed. |
| `customer_unique_id` | NVARCHAR(50) | NOT NULL | Persistent person id across several orders. |
| `customer_zip_code_prefix` | NVARCHAR(5) | NULL | Left padded with zeros to five characters. |
| `customer_city` | NVARCHAR(100) | NULL | Trimmed and converted to proper case. |
| `customer_state` | NVARCHAR(10) | NULL | Trimmed and converted to upper case, for example SP. |

### `silver.sellers`

**Grain:** One row per seller.  

| Column | Data type | Key or constraint | Transformation rule |
| :--- | :--- | :--- | :--- |
| `seller_id` | NVARCHAR(50) | Primary key | Trimmed. |
| `seller_zip_code_prefix` | NVARCHAR(5) | NULL | Left padded with zeros to five characters. |
| `seller_city` | NVARCHAR(100) | NULL | Trimmed and converted to proper case. |
| `seller_state` | NVARCHAR(10) | NULL | Trimmed and converted to upper case. |

### `silver.geolocation`

**Grain:** One row per zip code prefix, collapsed from about one million raw readings.  

| Column | Data type | Key or constraint | Transformation rule |
| :--- | :--- | :--- | :--- |
| `geolocation_zip_code_prefix` | NVARCHAR(5) | Primary key | Five character prefix. All readings for a prefix are grouped into one row. |
| `geolocation_lat` | DECIMAL(9,6) | NULL | Average latitude of all readings for the prefix. |
| `geolocation_lng` | DECIMAL(9,6) | NULL | Average longitude of all readings for the prefix. |
| `geolocation_city` | NVARCHAR(100) | NULL | Most frequent city for the prefix, in proper case. |
| `geolocation_state` | NVARCHAR(10) | NULL | Upper case state code. |

### `silver.category_translation`

**Grain:** One row per Portuguese product category.  

| Column | Data type | Key or constraint | Transformation rule |
| :--- | :--- | :--- | :--- |
| `product_category_name` | NVARCHAR(200) | Primary key | Portuguese category name. |
| `product_category_name_english` | NVARCHAR(200) | NOT NULL | English category name. The two categories missing from the source file (pc_gamer and portateis_cozinha_e_preparadores_de_alimentos) are added during the load. |

### `silver.products`

**Grain:** One row per product.  

| Column | Data type | Key or constraint | Transformation rule |
| :--- | :--- | :--- | :--- |
| `product_id` | NVARCHAR(50) | Primary key | Trimmed product id. |
| `product_category_name` | NVARCHAR(200) | NOT NULL | Portuguese category name. Unknown when missing. |
| `product_category_name_english` | NVARCHAR(200) | NOT NULL | English name looked up from silver.category_translation. Unknown when unmatched. |
| `product_name_length` | INT | NULL | Renamed from product_name_lenght and cast to integer. |
| `product_description_length` | INT | NULL | Renamed from product_description_lenght and cast to integer. |
| `product_photos_qty` | INT | NULL | Number of photos, cast to integer. |
| `product_weight_g` | INT | NULL | Weight in grams, cast to integer. |
| `product_length_cm` | INT | NULL | Length in centimetres, cast to integer. |
| `product_height_cm` | INT | NULL | Height in centimetres, cast to integer. |
| `product_width_cm` | INT | NULL | Width in centimetres, cast to integer. |

### `silver.orders`

**Grain:** One row per order.  

| Column | Data type | Key or constraint | Transformation rule |
| :--- | :--- | :--- | :--- |
| `order_id` | NVARCHAR(50) | Primary key | Trimmed order id. |
| `customer_id` | NVARCHAR(50) | NOT NULL | Order level customer id. Joins to silver.customers. |
| `order_status` | NVARCHAR(20) | NULL | Trimmed and converted to lower case, for example delivered or canceled. |
| `order_purchase_ts` | DATETIME2 | NULL | Renamed from order_purchase_timestamp and cast to DATETIME2. |
| `order_approved_at` | DATETIME2 | NULL | Cast to DATETIME2. NULL when the order was never approved. |
| `order_delivered_carrier_date` | DATETIME2 | NULL | Cast to DATETIME2. NULL when not yet handed to the carrier. |
| `order_delivered_customer_date` | DATETIME2 | NULL | Cast to DATETIME2. Kept NULL when the order has not been delivered. |
| `order_estimated_delivery_date` | DATETIME2 | NULL | Cast to DATETIME2. Delivery date promised to the customer. |
| `is_delivered` | BIT | NOT NULL | Derived flag: 1 when order_status is delivered, otherwise 0. |

### `silver.order_items`

**Grain:** One row per item in an order.  

| Column | Data type | Key or constraint | Transformation rule |
| :--- | :--- | :--- | :--- |
| `order_id` | NVARCHAR(50) | Primary key (part 1) | Trimmed order id. |
| `order_item_id` | INT | Primary key (part 2) | Item number within the order, cast to integer. |
| `product_id` | NVARCHAR(50) | NOT NULL | Product sold. |
| `seller_id` | NVARCHAR(50) | NOT NULL | Seller fulfilling this item. |
| `shipping_limit_date` | DATETIME2 | NULL | Cast to DATETIME2. Seller shipping deadline. |
| `price` | DECIMAL(10,2) | NULL | Item price, cast to DECIMAL(10,2). |
| `freight_value` | DECIMAL(10,2) | NULL | Freight charged for the item, cast to DECIMAL(10,2). |
| `total_item_value` | DECIMAL(10,2) | NULL | Derived: price plus freight_value. |

### `silver.order_payments`

**Grain:** One row per payment line of an order.  

| Column | Data type | Key or constraint | Transformation rule |
| :--- | :--- | :--- | :--- |
| `order_id` | NVARCHAR(50) | Primary key (part 1) | Trimmed order id. |
| `payment_sequential` | INT | Primary key (part 2) | Payment line number within the order, cast to integer. |
| `payment_type` | NVARCHAR(30) | NOT NULL | Payment method. The value not_defined is standardised to Unknown. |
| `payment_installments` | INT | NULL | Number of installments, cast to integer. |
| `payment_value` | DECIMAL(10,2) | NULL | Amount paid, cast to DECIMAL(10,2). |

### `silver.order_reviews`

**Grain:** One row per review_id after de-duplication.  

| Column | Data type | Key or constraint | Transformation rule |
| :--- | :--- | :--- | :--- |
| `review_id` | NVARCHAR(50) | Primary key | Duplicates are removed with ROW_NUMBER, keeping the latest review_answer_timestamp. |
| `order_id` | NVARCHAR(50) | NOT NULL | Order reviewed. |
| `review_score` | TINYINT | NULL | Satisfaction score from 1 to 5. |
| `review_comment_title` | NVARCHAR(500) | NULL | Optional comment title. |
| `review_comment_message` | NVARCHAR(MAX) | NULL | Comment text. Kept in full, including commas and line breaks. |
| `review_creation_date` | DATETIME2 | NULL | Cast to DATETIME2. When the survey was sent. |
| `review_answer_timestamp` | DATETIME2 | NULL | Cast to DATETIME2. When the customer answered. |

---

## 4. Gold layer (business reporting star schema)

> The gold schema is a star schema of seven dimensions and three facts. Every dimension has a row with surrogate key -1 and the value Unknown, so a fact row never holds a missing key. Every Gold table also has dwh_load_ts (DATETIME2, set by SQL Server) and dwh_batch_id (INT, set by SSIS).

### Dimensions at a glance

| Table | Surrogate key | Business key | Grain and special rules |
| :--- | :--- | :--- | :--- |
| `gold.dim_date` | date_key | full_date | One row per calendar day, 2016 to 2019, generated by a script. day_of_week runs from 1 (Monday) to 7 (Sunday). |
| `gold.dim_geography` | geography_key | zip_code_prefix | One row per zip code prefix. Loaded before dim_customer and dim_seller. |
| `gold.dim_customer` | customer_key | customer_unique_id | Slowly changing dimension Type 2: one row per city and state version of a customer, with valid_from, valid_to (9999-12-31 while open) and is_current. |
| `gold.dim_product` | product_key | product_id | One row per product, with Portuguese and English category names. |
| `gold.dim_seller` | seller_key | seller_id | One row per seller, linked to dim_geography. |
| `gold.dim_order_status` | order_status_key | order_status | One row per order status, with an is_delivered flag. |
| `gold.dim_payment_type` | payment_type_key | payment_type | One row per payment method: credit_card, boleto, voucher, debit_card and Unknown. |

### `gold.dim_date`

**Grain:** One row per calendar day.  

| Column | Data type | Key or constraint | Description | Source |
| :--- | :--- | :--- | :--- | :--- |
| `date_key` | INT | Primary key (identity) | Surrogate key. -1 is the Unknown row (1900-01-01). | Generated |
| `full_date` | DATE | Unique, NOT NULL | Business key: the calendar date. | Generated by script |
| `calendar_year` | SMALLINT | NOT NULL | Year, for example 2017. | Derived from full_date |
| `calendar_quarter` | TINYINT | NOT NULL | Quarter, 1 to 4. | Derived from full_date |
| `calendar_month` | TINYINT | NOT NULL | Month number, 1 to 12. | Derived from full_date |
| `month_name` | NVARCHAR(20) | NOT NULL | Month name, for example March. | Derived from full_date |
| `year_month` | NVARCHAR(7) | NOT NULL | Year and month, for example 2017-03. Used for monthly trends. | Derived from full_date |
| `day_of_month` | TINYINT | NOT NULL | Day of the month, 1 to 31. | Derived from full_date |
| `day_of_week` | TINYINT | NOT NULL | 1 is Monday, 7 is Sunday. | Derived from full_date |
| `day_name` | NVARCHAR(20) | NOT NULL | Day name, for example Monday. | Derived from full_date |
| `is_weekend` | BIT | NOT NULL | 1 for Saturday and Sunday. | Derived from full_date |

### `gold.dim_geography`

**Grain:** One row per zip code prefix.  

| Column | Data type | Key or constraint | Description | Source |
| :--- | :--- | :--- | :--- | :--- |
| `geography_key` | INT | Primary key (identity) | Surrogate key. -1 is the Unknown row. | Generated |
| `zip_code_prefix` | NVARCHAR(10) | Unique, NOT NULL | Business key: five character zip prefix. | silver.geolocation.geolocation_zip_code_prefix |
| `latitude` | DECIMAL(9,6) | NULL | Average latitude for the prefix. | silver.geolocation.geolocation_lat |
| `longitude` | DECIMAL(9,6) | NULL | Average longitude for the prefix. | silver.geolocation.geolocation_lng |
| `city` | NVARCHAR(100) | NULL | Most frequent city for the prefix. | silver.geolocation.geolocation_city |
| `state` | NVARCHAR(10) | NULL | Upper case state code. | silver.geolocation.geolocation_state |

### `gold.dim_customer`

**Grain:** One row per customer_unique_id per city and state version.  

| Column | Data type | Key or constraint | Description | Source |
| :--- | :--- | :--- | :--- | :--- |
| `customer_key` | INT | Primary key (identity) | Surrogate key. -1 is the Unknown row. | Generated |
| `customer_unique_id` | NVARCHAR(50) | NOT NULL | Business key: the real person id, not customer_id. | silver.customers.customer_unique_id |
| `geography_key` | INT | Foreign key to dim_geography | Zip prefix of this version. -1 when not found. | Lookup of silver.customers.customer_zip_code_prefix |
| `customer_city` | NVARCHAR(100) | NULL | City for this version. Tracked by the SCD Type 2 rule. | silver.customers.customer_city |
| `customer_state` | NVARCHAR(10) | NULL | State for this version. Tracked by the SCD Type 2 rule. | silver.customers.customer_state |
| `valid_from` | DATETIME2 | NOT NULL | Purchase time of the first order seen in this city and state. | silver.orders.order_purchase_ts |
| `valid_to` | DATETIME2 | NOT NULL, default 9999-12-31 | End of the version. 9999-12-31 means the version is still open. | Derived: start of the next version |
| `is_current` | BIT | NOT NULL | 1 for the latest version of the customer, otherwise 0. | Derived |

### `gold.dim_product`

**Grain:** One row per product.  

| Column | Data type | Key or constraint | Description | Source |
| :--- | :--- | :--- | :--- | :--- |
| `product_key` | INT | Primary key (identity) | Surrogate key. -1 is the Unknown row. | Generated |
| `product_id` | NVARCHAR(50) | Unique, NOT NULL | Business key. | silver.products.product_id |
| `product_category_name` | NVARCHAR(200) | NOT NULL | Portuguese category. Unknown when missing. | silver.products.product_category_name |
| `product_category_name_english` | NVARCHAR(200) | NOT NULL | English category. Unknown when missing. | silver.products.product_category_name_english |
| `product_name_length` | INT | NULL | Length of the product name. | silver.products.product_name_length |
| `product_description_length` | INT | NULL | Length of the product description. | silver.products.product_description_length |
| `product_photos_qty` | INT | NULL | Number of photos. | silver.products.product_photos_qty |
| `product_weight_g` | INT | NULL | Weight in grams. | silver.products.product_weight_g |
| `product_length_cm` | INT | NULL | Length in centimetres. | silver.products.product_length_cm |
| `product_height_cm` | INT | NULL | Height in centimetres. | silver.products.product_height_cm |
| `product_width_cm` | INT | NULL | Width in centimetres. | silver.products.product_width_cm |

### `gold.dim_seller`

**Grain:** One row per seller.  

| Column | Data type | Key or constraint | Description | Source |
| :--- | :--- | :--- | :--- | :--- |
| `seller_key` | INT | Primary key (identity) | Surrogate key. -1 is the Unknown row. | Generated |
| `seller_id` | NVARCHAR(50) | Unique, NOT NULL | Business key. | silver.sellers.seller_id |
| `geography_key` | INT | Foreign key to dim_geography | Zip prefix of the seller. -1 when not found. | Lookup of silver.sellers.seller_zip_code_prefix |
| `seller_city` | NVARCHAR(100) | NULL | Seller city. | silver.sellers.seller_city |
| `seller_state` | NVARCHAR(10) | NULL | Seller state. | silver.sellers.seller_state |

### `gold.dim_order_status`

**Grain:** One row per order status.  

| Column | Data type | Key or constraint | Description | Source |
| :--- | :--- | :--- | :--- | :--- |
| `order_status_key` | INT | Primary key (identity) | Surrogate key. -1 is the Unknown row. | Generated |
| `order_status` | NVARCHAR(20) | Unique, NOT NULL | Business key: lower case status such as delivered, shipped or canceled. | silver.orders.order_status |
| `is_delivered` | BIT | NOT NULL | 1 when the status is delivered, otherwise 0. | silver.orders.is_delivered |

### `gold.dim_payment_type`

**Grain:** One row per payment method.  

| Column | Data type | Key or constraint | Description | Source |
| :--- | :--- | :--- | :--- | :--- |
| `payment_type_key` | INT | Primary key (identity) | Surrogate key. -1 is the Unknown row. | Generated |
| `payment_type` | NVARCHAR(30) | Unique, NOT NULL | Business key: credit_card, boleto, voucher, debit_card or Unknown. | silver.order_payments.payment_type |

### `gold.fact_sales`

**Grain:** One row per item purchased within an order.  
**Primary key:** order_id and order_item_id together.  
**Important:** payment_value is deliberately not stored here. An order can have several items and several payments, so joining them would double count. Payments have their own fact table.  

| Column | Data type | Key or constraint | Description | Source |
| :--- | :--- | :--- | :--- | :--- |
| `order_id` | NVARCHAR(50) | Primary key (part 1) | Order identifier (degenerate dimension). | silver.order_items.order_id |
| `order_item_id` | INT | Primary key (part 2) | Item number within the order. | silver.order_items.order_item_id |
| `date_key` | INT | Foreign key to dim_date | Order purchase date. -1 if missing. | Lookup of silver.orders.order_purchase_ts (date part) |
| `customer_key` | INT | Foreign key to dim_customer | Customer version valid at the time of purchase. -1 if missing. | Lookup of customer_unique_id and order_purchase_ts against valid_from and valid_to |
| `product_key` | INT | Foreign key to dim_product | Product purchased. -1 if missing. | Lookup of silver.order_items.product_id |
| `seller_key` | INT | Foreign key to dim_seller | Seller fulfilling this item. -1 if missing. | Lookup of silver.order_items.seller_id |
| `order_status_key` | INT | Foreign key to dim_order_status | Status of the order. -1 if missing. | Lookup of silver.orders.order_status |
| `price` | DECIMAL(10,2) | NULL | Item price in BRL. | silver.order_items.price |
| `freight_value` | DECIMAL(10,2) | NULL | Shipping charged for the item in BRL. | silver.order_items.freight_value |
| `total_item_value` | DECIMAL(10,2) | NULL | Price plus freight_value. | silver.order_items.total_item_value |
| `order_purchase_ts` | DATETIME2 | NULL | Purchase time, kept for the delivery calculations. | silver.orders.order_purchase_ts |
| `order_delivered_customer_date` | DATETIME2 | NULL | Delivery time. NULL when not delivered. | silver.orders.order_delivered_customer_date |
| `order_estimated_delivery_date` | DATETIME2 | NULL | Promised delivery date. | silver.orders.order_estimated_delivery_date |
| `days_to_deliver` | INT | NULL | Days from purchase to delivery. NULL when not delivered. | Derived: DATEDIFF(day, purchase, delivered) |
| `delivery_delay_days` | INT | NULL | Days against the promised date: negative is early, positive is late. NULL when not delivered. | Derived: DATEDIFF(day, estimated, delivered) |
| `is_late` | BIT | NULL | 1 if delivered after the promised date, 0 if on time, NULL when not delivered. | Derived: delivery_delay_days above 0 |

### `gold.fact_payments`

**Grain:** One row per payment line of an order.  
**Primary key:** order_id and payment_sequential together.  
**Important:** Never join this fact directly to fact_sales on order_id. Aggregate each fact separately.  

| Column | Data type | Key or constraint | Description | Source |
| :--- | :--- | :--- | :--- | :--- |
| `order_id` | NVARCHAR(50) | Primary key (part 1) | Order identifier. | silver.order_payments.order_id |
| `payment_sequential` | INT | Primary key (part 2) | Payment line number when several methods are used. | silver.order_payments.payment_sequential |
| `date_key` | INT | Foreign key to dim_date | Order purchase date. -1 if missing. | Lookup of silver.orders.order_purchase_ts (date part) |
| `customer_key` | INT | Foreign key to dim_customer | Customer version valid at the time of purchase. -1 if missing. | Lookup of customer_unique_id and order_purchase_ts |
| `payment_type_key` | INT | Foreign key to dim_payment_type | Payment method used. -1 if missing. | Lookup of silver.order_payments.payment_type |
| `payment_installments` | INT | NULL | Number of installments chosen. | silver.order_payments.payment_installments |
| `payment_value` | DECIMAL(10,2) | NULL | Amount paid in BRL. | silver.order_payments.payment_value |

### `gold.fact_reviews`

**Grain:** One row per customer review.  
**Primary key:** review_id.  
**Important:** Reviews belong to an order, not to an item. To link a review to a seller, go through the distinct order_id and seller_key pairs in fact_sales. Never join reviews straight onto item rows.  

| Column | Data type | Key or constraint | Description | Source |
| :--- | :--- | :--- | :--- | :--- |
| `review_id` | NVARCHAR(50) | Primary key | Review identifier. | silver.order_reviews.review_id |
| `order_id` | NVARCHAR(50) | NOT NULL | Order being reviewed (degenerate dimension). | silver.order_reviews.order_id |
| `date_key` | INT | Foreign key to dim_date | Date the review survey was sent. -1 if missing. | Lookup of silver.order_reviews.review_creation_date (date part) |
| `customer_key` | INT | Foreign key to dim_customer | Customer who placed the reviewed order. -1 if missing. | Lookup through silver.orders.customer_id |
| `review_score` | TINYINT | NULL | Satisfaction rating from 1 (worst) to 5 (best). | silver.order_reviews.review_score |
| `review_creation_date` | DATETIME2 | NULL | When the survey was sent. | silver.order_reviews.review_creation_date |
| `review_answer_timestamp` | DATETIME2 | NULL | When the customer answered. | silver.order_reviews.review_answer_timestamp |

---

## 5. Loading rules and naming conventions

### How each layer is loaded

| Layer | Load rule |
| :--- | :--- |
| `etl (audit)` | Append only. A new batch_id is created on every run. Never truncated. |
| `bronze` | Truncate and reload on every run. Never append. |
| `silver` | Truncate and reload from Bronze on every run. Rows that fail a rule go to etl.error_rows. |
| `gold dimensions` | MERGE on the business key, so surrogate keys stay the same across runs. Never truncated. The -1 Unknown row is inserted only if it is missing. dim_date inserts only dates that do not exist yet. |
| `gold dim_customer` | SCD Type 2 using a MERGE. A re-run with no source change creates no new version. |
| `gold facts` | Truncate and reload on every run, after all dimensions are loaded. Never append. |

### Naming conventions

| Object | Convention | Example |
| :--- | :--- | :--- |
| `All names` | Lower case snake_case | `order_purchase_ts` |
| `Bronze tables` | bronze.source_name | `bronze.olist_orders` |
| `Silver tables` | silver.entity | `silver.orders` |
| `Dimensions and facts` | gold.dim_name and gold.fact_name | `gold.dim_customer` |
| `Surrogate keys` | dimension_key, INT identity | `customer_key` |
| `Audit columns` | Prefix dwh_ | `dwh_load_ts, dwh_batch_id` |
| `Constraints` | pk_, fk_, uq_ and df_ prefixes | `pk_dim_customer, fk_fact_sales_dim_date` |