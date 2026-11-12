--01. Execute SQL Task: Table Truncate
TRUNCATE TABLE silver.customers;
TRUNCATE TABLE silver.sellers;
TRUNCATE TABLE silver.products;
TRUNCATE TABLE silver.geolocation;
TRUNCATE TABLE silver.orders;
TRUNCATE TABLE silver.order_items;
TRUNCATE TABLE silver.order_payments;
TRUNCATE TABLE silver.order_reviews;
TRUNCATE TABLE silver.category_translation;

--02. Data Flow: 
  --2.1. OLE DB Sourse: bronze_customers
SELECT 
    CAST(NULLIF(LTRIM(RTRIM([customer_id])), N'') AS NVARCHAR(50)) AS [customer_id],
    CAST(NULLIF(LTRIM(RTRIM([customer_unique_id])), N'') AS NVARCHAR(50)) AS [customer_unique_id],
    CAST(RIGHT(N'00000' + NULLIF(LTRIM(RTRIM([customer_zip_code_prefix])), N''), 5) AS NVARCHAR(5)) AS [customer_zip_code_prefix],
    CAST(NULLIF(LTRIM(RTRIM([customer_city])), N'') AS NVARCHAR(100)) AS [customer_city],
    CAST(UPPER(NULLIF(LTRIM(RTRIM([customer_state])), N'')) AS NVARCHAR(10)) AS [customer_state]
FROM [olist_dwh].[bronze].[olist_customers];

  --2.2. Derived Columns: silver_customers_metadata
--2.2.1. Batch ID
Derived Column name: dwh_batch_id
Derived Column: <add as new column>
Expression: @[$Package::p_batch_id]
Data Type: DT_I4

  --2.2.2. Looad Timestamp
Derived Column name: dwh_batch_id
Derived Column: <add as new column>
Expression: @[$Package::p_batch_id]
Data Type: DT_I4

  --2.3. Row Count: variable: user::silver_cust_row_written
variable: user::silver_cust_row_written

  --2.4. OLE DB Destination: silver_customers_destination (data loaded)

--03. Data Flow: 
  --3.1. OLE DB Sourse: bronze_orders
  SELECT 
    CAST(TRIM(order_id) AS NVARCHAR(50)) AS order_id,
    CAST(TRIM(customer_id) AS NVARCHAR(50)) AS customer_id,
    CAST(TRIM(order_status) AS NVARCHAR(20)) AS order_status,
    TRY_CAST(order_purchase_timestamp AS DATETIME2) AS order_purchase_ts,
    TRY_CAST(order_approved_at AS DATETIME2) AS order_approved_at,
    TRY_CAST(order_delivered_carrier_date AS DATETIME2) AS order_delivered_carrier_date,
    TRY_CAST(order_delivered_customer_date AS DATETIME2) AS order_delivered_customer_date,
    TRY_CAST(order_estimated_delivery_date AS DATETIME2) AS order_estimated_delivery_date,
    CASE WHEN TRIM(order_status) = 'delivered' THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS is_delivered
FROM [olist_dwh].[bronze].[olist_orders];

  --3.2. Derived Columns: silver_orders_metadata
--3.3.1. Batch ID
Derived Column name: dwh_batch_id
Derived Column: <add as new column>
Expression: @[$Package::p_batch_id]
Data Type: DT_I4

  --3.2.2. Looad Timestamp
Derived Column name: dwh_batch_id
Derived Column: <add as new column>
Expression: @[$Package::p_batch_id]
Data Type: DT_I4
  --3.3. Row Count: variable: user::silver_ord_row_written
  variable: user::silver_ord_row_written
  --3.4. OLE DB Destination: silver_orders_destination (data loaded)

--04. Data Flow: 
  --4.1. OLE DB Sourse: bronze_order_items
  SELECT 
    CAST(TRIM(order_id) AS NVARCHAR(50)) AS order_id,
    TRY_CAST(order_item_id AS INT) AS order_item_id,
    CAST(TRIM(product_id) AS NVARCHAR(50)) AS product_id,
    CAST(TRIM(seller_id) AS NVARCHAR(50)) AS seller_id,
    TRY_CAST(shipping_limit_date AS DATETIME2) AS shipping_limit_date,
    TRY_CAST(price AS DECIMAL(10, 2)) AS price,
    TRY_CAST(freight_value AS DECIMAL(10, 2)) AS freight_value,
    (TRY_CAST(price AS DECIMAL(10, 2)) + TRY_CAST(freight_value AS DECIMAL(10, 2))) AS total_item_value
FROM [olist_dwh].[bronze].[olist_order_items];

  --4.2. Derived Columns: silver_order_items_metadata
--4.2.1. Batch ID
Derived Column name: dwh_batch_id
Derived Column: <add as new column>
Expression: @[$Package::p_batch_id]
Data Type: DT_I4

  --4.2.2. Looad Timestamp
Derived Column name: dwh_batch_id
Derived Column: <add as new column>
Expression: @[$Package::p_batch_id]
Data Type: DT_I4
  --4.3. Row Count: variable: user::silver_items_row_written
  variable: user::silver_items_row_written
  --4.4. OLE DB Destination: silver_order_items_destination (data loaded)

--05. Data Flow: 
  --5.1. OLE DB Sourse: bronze_order_payments
  SELECT 
    CAST(TRIM(order_id) AS NVARCHAR(32)) AS order_id,
    TRY_CAST(payment_sequential AS SMALLINT) AS payment_sequential,
    CAST(CASE WHEN TRIM(payment_type) = 'not_defined' THEN 'Unknown' ELSE TRIM(payment_type) END AS NVARCHAR(50)) AS payment_type,
    TRY_CAST(payment_installments AS SMALLINT) AS payment_installments,
    TRY_CAST(payment_value AS DECIMAL(10, 2)) AS payment_value
FROM [olist_dwh].[bronze].[olist_order_payments];

  --5.2. Derived Columns: silver_order_payments_metadata
--5.2.1
Derived Column name: dwh_batch_id
Derived Column: <add as new column>
Expression: @[$Package::p_batch_id]
Data Type: DT_I4

  --5.2.2. Looad Timestamp
Derived Column name: dwh_batch_id
Derived Column: <add as new column>
Expression: @[$Package::p_batch_id]
Data Type: DT_I4
  --5.3. Row Count: variable: user::silver_pay_row_written
  variable: user::silver_pay_row_written
  --5.4. OLE DB Destination: silver_order_payments_destination (data loaded)

--06. Data Flow: 
  --6.1. OLE DB Sourse: bronze_order_reviews
  WITH ranked_reviews AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY review_id ORDER BY TRY_CAST(review_answer_timestamp AS DATETIME2) DESC) as rn
    FROM [olist_dwh].[bronze].[olist_order_reviews]
)
SELECT 
    CAST(TRIM(review_id) AS NVARCHAR(50)) AS review_id,
    CAST(TRIM(order_id) AS NVARCHAR(50)) AS order_id,
    TRY_CAST(review_score AS TINYINT) AS review_score,
    CAST(review_comment_title AS NVARCHAR(200)) AS review_comment_title,
    CAST(review_comment_message AS NVARCHAR(MAX)) AS review_comment_message,
    TRY_CAST(review_creation_date AS DATETIME2) AS review_creation_date,
    TRY_CAST(review_answer_timestamp AS DATETIME2) AS review_answer_timestamp
FROM ranked_reviews
WHERE rn = 1;

  --6.2. Derived Columns: silver_order_reviews_metadata
  --6.2.1. Batch Id
Derived Column name: dwh_batch_id
Derived Column: <add as new column>
Expression: @[$Package::p_batch_id]
Data Type: DT_I4

  --6.2.2. Looad Timestamp
Derived Column name: dwh_batch_id
Derived Column: <add as new column>
Expression: @[$Package::p_batch_id]
Data Type: DT_I4
  --6.3. Row Count: variable: user::silver_rev_row_written
  variable: user::silver_rev_row_written
  --6.4. OLE DB Destination: silver_order_reviews_destination (data loaded)

--07. Data Flow: 
  --7.1. OLE DB Sourse: bronze_products
  SELECT 
    CAST(TRIM(bp.product_id) AS NVARCHAR(50)) AS product_id,
    CAST(ISNULL(bp.product_category_name, 'Unknown') AS NVARCHAR(200)) AS product_category_name,
    CAST(ISNULL(st.product_category_name_english, 'Unknown') AS NVARCHAR(200)) AS product_category_name_english,
    TRY_CAST(bp.product_name_lenght AS SMALLINT) AS product_name_length,
    TRY_CAST(bp.product_description_lenght AS SMALLINT) AS product_description_length,
    TRY_CAST(bp.product_photos_qty AS SMALLINT) AS product_photos_qty,
    TRY_CAST(bp.product_weight_g AS INT) AS product_weight_g,
    TRY_CAST(bp.product_length_cm AS SMALLINT) AS product_length_cm,
    TRY_CAST(bp.product_height_cm AS SMALLINT) AS product_height_cm,
    TRY_CAST(bp.product_width_cm AS SMALLINT) AS product_width_cm
FROM [olist_dwh].[bronze].[olist_products] bp
LEFT JOIN silver.category_translation st ON TRIM(bp.product_category_name) = st.product_category_name;

  --7.2. Derived Columns: silver_products_metadata
--7.2.1. Batch Id
Derived Column name: dwh_batch_id
Derived Column: <add as new column>
Expression: @[$Package::p_batch_id]
Data Type: DT_I4

  --7.2.2. Looad Timestamp
Derived Column name: dwh_batch_id
Derived Column: <add as new column>
Expression: @[$Package::p_batch_id]
Data Type: DT_I4
  --7.3. Row Count: variable: user::silver_prod_row_written
  variable: user::silver_prod_row_written
  --7.4. OLE DB Destination: silver_products_destination (data loaded)

--08. Data Flow: 
  --8.1. OLE DB Sourse: bronze_sellers
  SELECT 
    CAST(TRIM(seller_id) AS NVARCHAR(50)) AS seller_id,
    CAST(RIGHT('00000' + TRIM(seller_zip_code_prefix), 5) AS NVARCHAR(5)) AS seller_zip_code_prefix,
    CAST(LOWER(TRIM(seller_city)) AS NVARCHAR(100)) AS seller_city,
    CAST(UPPER(TRIM(seller_state)) AS NVARCHAR(10)) AS seller_state
FROM [olist_dwh].[bronze].[olist_sellers];

  --8.2. Derived Columns: silver_sellers_metadata
  --8.2.1. Batch Id
Derived Column name: dwh_batch_id
Derived Column: <add as new column>
Expression: @[$Package::p_batch_id]
Data Type: DT_I4

  --8.2.2. Looad Timestamp
Derived Column name: dwh_batch_id
Derived Column: <add as new column>
Expression: @[$Package::p_batch_id]
Data Type: DT_I4
  --8.3. Row Count: variable: user::silver_sell_row_written
  variable: user::silver_sell_row_written
  --8.4. OLE DB Destination: silver_sellers_destination (data loaded)

--09. Data Flow: 
  --9.1. OLE DB Sourse: bronze_geolocation
  WITH [g] AS (
    SELECT CAST(RIGHT(N'00000' + LTRIM(RTRIM([geolocation_zip_code_prefix])), 5) AS NVARCHAR(5)) AS [zip],
           TRY_CAST(NULLIF(LTRIM(RTRIM([geolocation_lat])), N'') AS DECIMAL(9,6))  AS [lat],
           TRY_CAST(NULLIF(LTRIM(RTRIM([geolocation_lng])), N'') AS DECIMAL(9,6))  AS [lng],
           LOWER(LTRIM(RTRIM([geolocation_city])))  AS [city_raw],
           UPPER(LTRIM(RTRIM([geolocation_state]))) AS [state_raw]
    FROM [olist_dwh].[bronze].[olist_geolocation]
    WHERE NULLIF(LTRIM(RTRIM([geolocation_zip_code_prefix])), N'') IS NOT NULL
),
[agg] AS (
    SELECT [zip], 
           AVG([lat]) AS [lat], 
           AVG([lng]) AS [lng]
    FROM [g]
    GROUP BY [zip]
),
[ranked] AS (
    SELECT [zip], 
           [city_raw], 
           [state_raw],
           ROW_NUMBER() OVER (PARTITION BY [zip] ORDER BY COUNT(*) DESC, [city_raw], [state_raw]) AS [rn]
    FROM [g]
    GROUP BY [zip], [city_raw], [state_raw]
)
SELECT [a].[zip]                                                         AS [geolocation_zip_code_prefix],
       CAST([a].[lat] AS DECIMAL(9,6))                                   AS [geolocation_lat],
       CAST([a].[lng] AS DECIMAL(9,6))                                   AS [geolocation_lng],
       CAST([silver].[fn_proper_case]([r].[city_raw]) AS NVARCHAR(100))  AS [geolocation_city],
       CAST([r].[state_raw] AS NVARCHAR(10))                              AS [geolocation_state]
FROM [agg] AS [a]
JOIN [ranked] AS [r] ON [r].[zip] = [a].[zip] AND [r].[rn] = 1;

  --9.2. Derived Columns: silver_geolocation_metadata
--9.2.1. Batch Id
Derived Column name: dwh_batch_id
Derived Column: <add as new column>
Expression: @[$Package::p_batch_id]
Data Type: DT_I4

  --2.1.2. Looad Timestamp
Derived Column name: dwh_batch_id
Derived Column: <add as new column>
Expression: @[$Package::p_batch_id]
Data Type: DT_I4
  --2.3. Row Count: variable: user::silver_geo_row_written
  variable: user::silver_geo_row_written
  --2.4. OLE DB Destination: silver_geolocation_destination (data loaded)

--10. Data Flow: 
  --10.1. OLE DB Sourse: bronze_category_translation
  SELECT CAST(NULLIF(LTRIM(RTRIM([product_category_name])), N'') AS NVARCHAR(100))         AS [product_category_name],
       CAST(NULLIF(LTRIM(RTRIM([product_category_name_english])), N'') AS NVARCHAR(100)) AS [product_category_name_english]
FROM [olist_dwh].[bronze].[olist_product_category_name_translation]
UNION ALL
SELECT [v].[product_category_name], [v].[product_category_name_english]
FROM (VALUES (CAST(N'pc_gamer' AS NVARCHAR(100)), CAST(N'pc_gamer' AS NVARCHAR(100))),
             (N'portateis_cozinha_e_preparadores_de_alimentos', N'portable_kitchen_and_food_preparers'))
     AS [v] ([product_category_name], [product_category_name_english])
WHERE NOT EXISTS (SELECT 1
                  FROM [olist_dwh].[bronze].[olist_product_category_name_translation] AS [b]
                  WHERE LTRIM(RTRIM([b].[product_category_name])) = [v].[product_category_name]);

  --10.2. Derived Columns: silver_category_translation_metadata
  --10.2.1. Batch Id
Derived Column name: dwh_batch_id
Derived Column: <add as new column>
Expression: @[$Package::p_batch_id]
Data Type: DT_I4

  --10.2.2. Looad Timestamp
Derived Column name: dwh_batch_id
Derived Column: <add as new column>
Expression: @[$Package::p_batch_id]
Data Type: DT_I4
  --10.3. Row Count: variable: user::silver_trans_row_written
variable: user::silver_trans_row_written
  --10.4. OLE DB Destination: silver_category_translation_destination
