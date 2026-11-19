End-to-End Data Lineage --- Olist E-Commerce Data Warehouse
Database: olist_dwh
Architecture: Medallion (Source → Bronze → Silver → Gold →
Consumption)
ETL platform: SQL Server Integration Services (SSIS)
Orchestration: SSIS Project Deployment Model
Audit schema: etl
1. Purpose and Scope
This document describes the end-to-end movement and transformation of
data through the Olist Data Warehouse. It traces the nine raw source CSV
files through the Bronze, Silver and Gold layers, and documents the
audit and reconciliation processes used to monitor ETL execution.

The lineage covers:
- Source files and their Bronze landing tables.
- Bronze-to-Silver cleansing and transformation rules.
- Silver-to-Gold dimension and fact-table loading.
- Surrogate-key lookups and unknown-member handling.
- Batch execution, load reconciliation and rejected-row logging.
2. High-Level Architecture and Control-Flow Lineage
The master package, 00_master.dtsx, orchestrates the ETL execution. It
creates a unique batch_id in etl.batch_log and passes that
identifier to the child packages so that the work performed during a
pipeline execution can be traced.
[ 9 Raw CSV Files (@[$Project::p_source_folder]) ]
                         |
                         v
        01_bronze_load.dtsx (Truncate & Fast Load)
                         |
                         v
             [ Bronze Layer: 9 Raw Landing Tables ]
                         |
                         +------------------------------> etl.load_log
                         |                                  rows_read, rows_written
                         v
        02_silver_transform.dtsx
        (Cleanse, Deduplicate, Cast, Lookup, Split)
                         |
                         v
             [ Silver Layer: 9 Cleansed Tables ]
                         |
                         +------------------------------> etl.error_rows
                         |                                  Quarantined bad rows
                         |
                         +------------------------------> etl.load_log
                         |                                  rows_read, rows_written, rows_error
                         |
              +----------+-------------------+
              |                              |
              v                              v
  03_gold_dimensions.dtsx         04_gold_facts.dtsx
  (MERGE / SCD Type 2)             (Truncate & Reload +
              |                    SSIS Lookups -> -1 Fallback)
              v                              v
  [ Gold Layer: 7 Dimensions ]     [ Gold Layer: 3 Facts ]
              |                              |
              +--------------+---------------+
                             |
                             v
                      etl.load_log
                 Gold load and row counts
                             |
                             v
                 SQL_data_quality_gate
                 (Automated Validation Rules)
                             |
                             v
                      etl.batch_log
              Updates end_ts and final status
                 (SUCCEEDED / FAILED)
2.1 SSIS Package Responsibilities
  SSIS package                 Responsibility    Input             Output
  00_master.dtsx             Orchestrates the  Pipeline          Sequential
complete ETL      parameters and    child-package
execution,        source-folder     execution and
creates the batch parameter         batch audit
identifier and                      record
passes it to
child packages.                     

  01_bronze_load.dtsx        Loads the raw CSV Nine source CSV   Nine Bronze
files into Bronze files             tables
landing tables.                     

  02_silver_transform.dtsx   Cleanses,         Bronze tables     Nine Silver
deduplicates,                       tables and
converts and                        rejected-row
enriches the                        records
Bronze data.                        

  03_gold_dimensions.dtsx    Loads and         Silver tables and Seven Gold
maintains Gold    Gold geography    dimensions
dimensions,       dimension
including
customer SCD Type
2 history.                          
04_gold_facts.dtsx         Loads the Gold    Silver tables and Three Gold fact
fact tables and   Gold dimensions   tables
resolves
dimension
surrogate keys.
The SQL Server Agent / SSISDB Catalog is identified as an optional
scheduling component.
3. Source-to-Target Lineage Matrix
The following matrix maps each source CSV file to its Bronze landing
table, Silver cleansed table and Gold target table or tables.
  Source CSV file                           Bronze landing table                               Silver cleansed table           Gold target table(s)
  olist_customers_dataset.csv             bronze.olist_customers                           silver.customers              gold.dim_customer (SCD
Type 2)

  olist_geolocation_dataset.csv           bronze.olist_geolocation                         silver.geolocation            gold.dim_geography

  olist_sellers_dataset.csv               bronze.olist_sellers                             silver.sellers                gold.dim_seller

  product_category_name_translation.csv   bronze.olist_product_category_name_translation   silver.category_translation   gold.dim_product
(through English category
lookup)

  olist_products_dataset.csv              bronze.olist_products                            silver.products               gold.dim_product

  olist_orders_dataset.csv                bronze.olist_orders                              silver.orders                 gold.dim_order_status,
gold.dim_customer
(valid-from dates),
gold.fact_sales,
gold.fact_payments,
gold.fact_reviews

  olist_order_items_dataset.csv           bronze.olist_order_items                         silver.order_items            gold.fact_sales

  olist_order_payments_dataset.csv        bronze.olist_order_payments                      silver.order_payments         gold.dim_payment_type,
gold.fact_payments

  olist_order_reviews_dataset.csv         bronze.olist_order_reviews                       silver.order_reviews          gold.fact_reviews
Generated T-SQL calendar loop             Not applicable                                     Not applicable                  gold.dim_date
(2016-01-01 to 2019-12-31)
4. Bronze Layer Lineage
SSIS package: 01_bronze_load.dtsx
Source: Nine raw CSV files
Target schema: bronze
4.1 Load Pattern
The Bronze load uses the following pattern:
1. Truncate the existing Bronze landing tables.
2. Read the CSV files using SSIS Flat File Sources.
3. Load the source columns into the corresponding Bronze tables using
   OLE DB Destinations configured for Fast Load.
4. Add data-lineage metadata to identify when and from where each row
   was loaded.
4.2 Column Handling
- Source columns are passed through to Bronze using a one-to-one
  column mapping.
- Bronze source columns use NVARCHAR so that raw formatting
  differences do not cause data-type conversion failures during
  ingestion.
- The original source values are retained in the raw landing layer.
4.3 Lineage Metadata Columns
  Metadata column         Purpose                 Value or source
  dwh_load_ts           Records when the row    Load timestamp (GETDATE() in
entered Bronze.         the supplied design)

  dwh_source_file       Identifies the CSV file Source filename derived from
from which the row      @[$Project::p_source_folder]
originated.             
dwh_batch_id          Identifies the master   @[$Package::p_batch_id],
ETL execution           passed from the master package
associated with the
row.
5. Silver Layer Lineage and Transformation Rules
SSIS package: 02_silver_transform.dtsx
Source schema: bronze
Target schema: silver
5.1 Load Pattern
Silver tables are truncated and reloaded, except for
silver.category_translation, which preserves pre-seeded translations.

The Silver layer applies data cleansing, deduplication, data-type
conversion, lookups and business-rule preparation. Rows that fail the
specified validation conditions are directed to etl.error_rows.
5.2 Table-by-Table Transformation Lineage
  Target Silver table             Source Bronze table(s)                             Transformations and cleansing rules
  silver.customers              bronze.olist_customers                           Trim customer_id and customer_unique_id. Left-pad customer_zip_code_prefix to
five digits using RIGHT('00000' + zip, 5). Trim customer_city and convert
customer_state to uppercase.

  silver.sellers                bronze.olist_sellers                             Trim seller_id. Left-pad seller_zip_code_prefix to five digits. Trim
seller_city and convert seller_state to uppercase.

  silver.geolocation            bronze.olist_geolocation                         Deduplicate approximately 1,000,000 raw coordinate readings to one row per five-digit
geolocation_zip_code_prefix. Calculate AVG(latitude) and AVG(longitude) as
DECIMAL(9,6) for each ZIP code prefix.

  silver.category_translation   bronze.olist_product_category_name_translation   Load standard Portuguese-to-English category mappings. Retain manually seeded
mappings for pc_gamer and kitchen_portables_and_food_preparators.

  silver.products               bronze.olist_products and                        Correct raw header typos: product_name_lenght to product_name_length, and
silver.category_translation                      product_description_lenght to product_description_length. Convert
product_weight_g to INT using SSIS Data Conversion. Retrieve the English category
using SSIS Lookup lkp_category_translation; default missing values to 'Unknown'.

  silver.orders                 bronze.olist_orders                              Convert order_purchase_timestamp, order_approved_at,
order_delivered_carrier_date, order_delivered_customer_date and
order_estimated_delivery_date to DATETIME2. Preserve NULL delivery dates for
cancelled or undelivered orders. Derive is_delivered as BIT (1 when
order_status = 'delivered', otherwise 0). Route rows with NULL keys or failed
purchase timestamps to etl.error_rows using SSIS Conditional Split.

  silver.order_items            bronze.olist_order_items                         Convert order_item_id to INT, shipping_limit_date to DATETIME2, and price
and freight_value to DECIMAL(10,2). Derive
total_item_value = price + freight_value.

  silver.order_payments         bronze.olist_order_payments                      Map 'not_defined' payment types to 'Unknown'. Convert payment_sequential and
payment_installments to INT, and payment_value to DECIMAL(10,2).
silver.order_reviews          bronze.olist_order_reviews                       Deduplicate records sharing the same review_id using
ROW_NUMBER() OVER (PARTITION BY review_id ORDER BY review_answer_timestamp DESC).
Convert review_score to TINYINT and survey timestamps to DATETIME2.
6. Gold Layer Lineage --- Dimension Tables
SSIS package: 03_gold_dimensions.dtsx
Source schema: silver
Target schema: gold
6.1 Dimension Load Pattern
Gold dimensions use an idempotent MERGE / INSERT WHERE NOT EXISTS
approach. They are not truncated during normal package execution so that
surrogate keys remain stable across re-runs.

Each dimension includes a pre-seeded -1 member representing Unknown.
6.2 Dimension Lineage Matrix
  Gold dimension            Upstream source(s)        Lineage and
key-generation logic
  gold.dim_date           Generated T-SQL date loop Generates one row per
calendar day from
2016-01-01 to
2019-12-31. Includes
year, quarter, month,
year_month, ISO
weekday (1 = Monday
to 7 = Sunday) and
is_weekend.

  gold.dim_geography      silver.geolocation      Merges distinct ZIP
code prefix values and
assigns geography_key
using INT IDENTITY.
Loaded first so that
dim_customer and
dim_seller can
resolve
geography_key.

  gold.dim_product        silver.products         Merges on product_id
to assign
product_key. Stores
Portuguese and English
category names and
physical product
dimensions.

  gold.dim_seller         silver.sellers and      Merges on seller_id
gold.dim_geography      to assign seller_key.
Links to
geography_key; uses
-1 when the ZIP code
prefix cannot be found.

  gold.dim_order_status   silver.orders           Merges distinct
order_status values
with the is_delivered
flag (1 or 0).

  gold.dim_payment_type   silver.order_payments   Merges distinct payment
types, including
credit_card,
boleto, voucher,
debit_card and
Unknown.
gold.dim_customer       silver.customers,       Implements SCD Type 2.
silver.orders and       Tracks historical
gold.dim_geography      changes in
customer_city and
customer_state per
customer_unique_id,
ordered by earliest
order_purchase_ts.
Manages valid_from,
valid_to
(9999-12-31 for the
active record) and
is_current (1 for
current, 0 for
historical).
6.3 Dimension Load Dependency
gold.dim_geography is loaded before gold.dim_customer and
gold.dim_seller because those dimensions require geography
surrogate-key resolution.
7. Gold Layer Lineage --- Fact Tables
SSIS package: 04_gold_facts.dtsx
Source schema: silver
Target schema: gold
7.1 Fact Load Pattern
The fact tables use a sequential truncate-and-reload pattern in the
following order:
1. gold.fact_sales
2. gold.fact_payments
3. gold.fact_reviews
SSIS Lookup transformations are configured with Ignore Failure,
followed by a Derived Column transformation using REPLACENULL(key, -1)
to assign the -1 Unknown surrogate key when a lookup does not resolve.
7.2 Fact Table Lineage Matrix
  Gold fact table        Grain             Upstream Silver sources    Surrogate-key lookups and measures
  gold.fact_sales      One row per order silver.order_items,      Lookups: date_key using order_purchase_ts; active-version customer_key; product_key;
item              silver.orders and        seller_key; and order_status_key. All unresolved lookups fall back to -1. Measures: price,
silver.customers         freight_value and total_item_value. Delivery metrics when is_delivered = 1:
days_to_deliver = DATEDIFF(DAY, order_purchase_ts, order_delivered_customer_date);
delivery_delay_days = DATEDIFF(DAY, order_estimated_delivery_date, order_delivered_customer_date);
is_late = CASE WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 1 ELSE 0 END.

  gold.fact_payments   One row per       silver.order_payments,   Lookups: date_key using order_purchase_ts; customer_key; and payment_type_key. All
payment line      silver.orders and        unresolved lookups fall back to -1. Measures: payment_installments and payment_value.
silver.customers         
gold.fact_reviews    One row per       silver.order_reviews,    Lookups: date_key using review_creation_date and customer_key. All unresolved lookups fall
review            silver.orders and        back to -1. Measures/attributes: review_score, review_creation_date and
silver.customers         review_answer_timestamp.
7.3 Unknown Surrogate-Key Handling
The Gold dimensions contain a pre-seeded -1 Unknown member. During
fact loading, unresolved SSIS Lookup results are replaced with -1
using the Derived Column expression:
REPLACENULL(key, -1)
This allows fact rows to retain their dimension-key relationship when a
matching dimension record is not found.
8. Audit, Logging and Reconciliation Lineage
Schema: etl

The audit and logging layer records batch execution details, table-level
load statistics and rejected Silver records. The batch_id links the
records generated during a pipeline execution.
8.1 Audit Tables
  Audit table             Information captured    Purpose
  etl.batch_log         batch_id, start_ts, Tracks each execution
end_ts and status   of 00_master.dtsx.
Status progresses from
RUNNING to
SUCCEEDED or
FAILED.

  etl.load_log          Package, table,         Records load and
rows_read,            reconciliation
rows_written and      information across the
rows_error, linked by 28 table loads: 9
batch_id              Bronze, 9 Silver, 7
Gold dimensions and 3
Gold facts.
etl.error_rows        batch_id,             Stores rejected Silver
table_name,           records so that failed
logged_ts and         rows are not silently
pipe-delimited raw row  lost.
snapshots
8.2 Batch Execution Lineage
1. 00_master.dtsx starts an execution and creates a unique
   batch_id.
2. The batch record is created in etl.batch_log with a RUNNING
   status and a start timestamp.
3. The master package passes the batch identifier to its child
   packages.
4. The Bronze, Silver and Gold package loads write their table-level
   load statistics to etl.load_log.
5. Rejected Silver rows are written to etl.error_rows.
6. The SQL_data_quality_gate runs the automated validation rules.
7. The batch record is updated with the end timestamp and final status:
   SUCCEEDED or FAILED.
8.3 Reconciliation
The etl.load_log table provides the row-count information used to
monitor the number of records read, written and rejected by each table
load.

The supplied design specifies logging across 28 table loads:

  Layer               Number of tables
  Bronze                             9
Silver                             9
Gold dimensions                    7
Gold facts                         3
Total                     28
9. Data Lineage and Design Guarantees
The supplied architecture identifies the following design guarantees:
- Re-runnable: The same counts are expected on every run.
- Stable dimension keys: Gold dimensions use idempotent loading
  and are not truncated during normal execution.
- Consistent naming: Schema, table and package naming is kept
  consistent throughout the pipeline.
- No hard-coded paths: The source-folder path is supplied through
  the project parameter @[$Project::p_source_folder].
- Raw-data retention: Raw CSV data is kept out of the Gold
  reporting layer.
- Unknown-member handling: Gold dimensions contain a -1 Unknown
  member, and unresolved fact lookups use that key.
- Rejected-row traceability: Rejected Silver records are captured
  in etl.error_rows.
- Batch traceability: The batch_id connects package execution,
  load statistics and rejected-row records.
10. Gold Layer Consumption
The Gold layer is the business-ready reporting layer. It exposes the
dimensional model and fact tables for analytical queries and reporting.

The documented consumption tools are:
- Power BI: Dashboards and business reporting using the Gold
  layer.
- T-SQL / SSMS: Analytical queries against the Gold tables,
  including the documented 06_analytics_queries.sql script.
The documented reporting focus includes revenue, delivery and review
insights.
11. End-to-End Lineage Summary
  Pipeline stage    Input             Main activity     Output
  Source            Nine raw Olist    Provides the      Raw CSV files
CSV files         original
e-commerce data.  

  Bronze            Raw CSV files     Truncate and Fast Nine Bronze
Load; preserve    landing tables
source values and
add lineage
metadata.         

  Silver            Bronze tables     Cleanse,          Nine Silver tables
deduplicate,      and error records
convert data
types, enrich
categories and
route rejected
rows.             

  Gold dimensions   Silver tables and Build dimensions, Seven Gold
generated         assign surrogate  dimensions
calendar          keys and maintain
customer SCD Type
2 history.        

  Gold facts        Silver tables and Resolve dimension Three Gold fact
Gold dimensions   keys, apply       tables
Unknown fallbacks
and calculate
fact measures.    

  Audit and logging Master and child  Track batch       etl.batch_log,
package           status, row       etl.load_log,
executions        counts and        etl.error_rows
rejected records. 
Consumption       Gold dimensions   Support           Power BI
and facts         analytical        dashboards and
queries and       T-SQL analysis
reporting.
End of document
Project: Olist E-Commerce Data Warehouse (olist_dwh)
Lineage coverage: Source → Bronze → Silver → Gold → Consumption,
including ETL audit and error logging.