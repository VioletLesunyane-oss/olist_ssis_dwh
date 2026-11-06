USE olist_dwh

IF NOT EXISTS (SELECT 1
               FROM [olist_dwh].[sys].[tables]  AS t
               JOIN [olist_dwh].[sys].[schemas] AS s ON s.[schema_id] = t.[schema_id]
               WHERE s.[name] = N'bronze' AND t.[name] = N'olist_customers')

BEGIN
    CREATE TABLE [olist_dwh].[bronze].[olist_customers]
    (
        [customer_id]              NVARCHAR(50),  
        [customer_unique_id]       NVARCHAR(50), 
        [customer_zip_code_prefix] NVARCHAR(20),
        [customer_city]            NVARCHAR(200), 
        [customer_state]           NVARCHAR(50),
        [dwh_load_ts]              DATETIME2 DEFAULT SYSDATETIME(),  
        [dwh_source_file]          NVARCHAR(260),
        [dwh_batch_id]             INT         
    );
END
GO

-- Source file: olist_geolocation_dataset.csv
IF NOT EXISTS (SELECT 1
               FROM [olist_dwh].[sys].[tables]  AS t
               JOIN [olist_dwh].[sys].[schemas] AS s ON s.[schema_id] = t.[schema_id]
               WHERE s.[name] = N'bronze' AND t.[name] = N'olist_geolocation')
BEGIN
    CREATE TABLE [olist_dwh].[bronze].[olist_geolocation]
    (
        [geolocation_zip_code_prefix] NVARCHAR(20),
        [geolocation_lat]             NVARCHAR(50),
        [geolocation_lng]             NVARCHAR(50),
        [geolocation_city]            NVARCHAR(200),
        [geolocation_state]           NVARCHAR(50),
        [dwh_load_ts]                 DATETIME2 DEFAULT SYSDATETIME(),
        [dwh_source_file]             NVARCHAR(260),
        [dwh_batch_id]                INT            
    );
END
GO

-- Source file: olist_order_items_dataset.csv
IF NOT EXISTS (SELECT 1
               FROM [olist_dwh].[sys].[tables]  AS t
               JOIN [olist_dwh].[sys].[schemas] AS s ON s.[schema_id] = t.[schema_id]
               WHERE s.[name] = N'bronze' AND t.[name] = N'olist_order_items')
BEGIN
    CREATE TABLE [olist_dwh].[bronze].[olist_order_items]
    (
        [order_id]            NVARCHAR(50),
        [order_item_id]       NVARCHAR(50),
        [product_id]          NVARCHAR(50),
        [seller_id]           NVARCHAR(50),
        [shipping_limit_date] NVARCHAR(50),
        [price]               NVARCHAR(50),
        [freight_value]       NVARCHAR(50),
        [dwh_load_ts]         DATETIME2 DEFAULT SYSDATETIME(),
        [dwh_source_file]     NVARCHAR(260),
        [dwh_batch_id]        INT
    );
END
GO

-- Source file: olist_order_payments_dataset.csv
IF NOT EXISTS (SELECT 1
               FROM [olist_dwh].[sys].[tables]  AS t
               JOIN [olist_dwh].[sys].[schemas] AS s ON s.[schema_id] = t.[schema_id]
               WHERE s.[name] = N'bronze' AND t.[name] = N'olist_order_payments')
BEGIN
    CREATE TABLE [olist_dwh].[bronze].[olist_order_payments]
    (
        [order_id]             NVARCHAR(50),
        [payment_sequential]   NVARCHAR(50),
        [payment_type]         NVARCHAR(50),
        [payment_installments] NVARCHAR(50),
        [payment_value]        NVARCHAR(50),
        [dwh_load_ts]          DATETIME2 DEFAULT SYSDATETIME(),
        [dwh_source_file]      NVARCHAR(260),
        [dwh_batch_id]         INT
    );
END
GO

-- Source file: olist_order_reviews_dataset.csv
IF NOT EXISTS (SELECT 1
               FROM [olist_dwh].[sys].[tables]  AS t
               JOIN [olist_dwh].[sys].[schemas] AS s ON s.[schema_id] = t.[schema_id]
               WHERE s.[name] = N'bronze' AND t.[name] = N'olist_order_reviews')
BEGIN
    CREATE TABLE [olist_dwh].[bronze].[olist_order_reviews]
    (
        [review_id]               NVARCHAR(50),
        [order_id]                NVARCHAR(50),
        [review_score]            NVARCHAR(50),
        [review_comment_title]    NVARCHAR(500),
        [review_comment_message]  NVARCHAR(MAX),
        [review_creation_date]    NVARCHAR(50),
        [review_answer_timestamp] NVARCHAR(50),
        [dwh_load_ts]             DATETIME2 DEFAULT SYSDATETIME(), 
        [dwh_source_file]         NVARCHAR(260),
        [dwh_batch_id]            INT
    );
END
GO

-- Source file: olist_orders_dataset.csv
IF NOT EXISTS (SELECT 1
               FROM [olist_dwh].[sys].[tables]  AS t
               JOIN [olist_dwh].[sys].[schemas] AS s ON s.[schema_id] = t.[schema_id]
               WHERE s.[name] = N'bronze' AND t.[name] = N'olist_orders')
BEGIN
    CREATE TABLE [olist_dwh].[bronze].[olist_orders]
    (
        [order_id]                      NVARCHAR(50),
        [customer_id]                   NVARCHAR(50),
        [order_status]                  NVARCHAR(50),
        [order_purchase_timestamp]      NVARCHAR(50),
        [order_approved_at]             NVARCHAR(50),
        [order_delivered_carrier_date]  NVARCHAR(50),
        [order_delivered_customer_date] NVARCHAR(50),
        [order_estimated_delivery_date] NVARCHAR(50),
        [dwh_load_ts]                   DATETIME2 DEFAULT SYSDATETIME(),
        [dwh_source_file]               NVARCHAR(260),
        [dwh_batch_id]                  INT
    );
END
GO

-- Source file: olist_products_dataset.csv
IF NOT EXISTS (SELECT 1
               FROM [olist_dwh].[sys].[tables]  AS t
               JOIN [olist_dwh].[sys].[schemas] AS s ON s.[schema_id] = t.[schema_id]
               WHERE s.[name] = N'bronze' AND t.[name] = N'olist_products')
BEGIN
    CREATE TABLE [olist_dwh].[bronze].[olist_products]
    (
        [product_id]                 NVARCHAR(50),
        [product_category_name]      NVARCHAR(200),
        [product_name_lenght]        NVARCHAR(50),
        [product_description_lenght] NVARCHAR(50),
        [product_photos_qty]         NVARCHAR(50),
        [product_weight_g]           NVARCHAR(50),
        [product_length_cm]          NVARCHAR(50),
        [product_height_cm]          NVARCHAR(50),
        [product_width_cm]           NVARCHAR(50),
        [dwh_load_ts]                DATETIME2 DEFAULT SYSDATETIME(),
        [dwh_source_file]            NVARCHAR(260),
        [dwh_batch_id]               INT
    );
END
GO

-- Source file: olist_sellers_dataset.csv
IF NOT EXISTS (SELECT 1
               FROM [olist_dwh].[sys].[tables]  AS t
               JOIN [olist_dwh].[sys].[schemas] AS s ON s.[schema_id] = t.[schema_id]
               WHERE s.[name] = N'bronze' AND t.[name] = N'olist_sellers')
BEGIN
    CREATE TABLE [olist_dwh].[bronze].[olist_sellers]
    (
        [seller_id]              NVARCHAR(50),
        [seller_zip_code_prefix] NVARCHAR(20),
        [seller_city]            NVARCHAR(200),
        [seller_state]           NVARCHAR(50),
        [dwh_load_ts]            DATETIME2 DEFAULT SYSDATETIME(),
        [dwh_source_file]        NVARCHAR(260),
        [dwh_batch_id]           INT
    );
END
GO

-- Source file: product_category_name_translation.csv
IF NOT EXISTS (SELECT 1
               FROM [olist_dwh].[sys].[tables]  AS t
               JOIN [olist_dwh].[sys].[schemas] AS s ON s.[schema_id] = t.[schema_id]
               WHERE s.[name] = N'bronze' AND t.[name] = N'olist_product_category_name_translation')
BEGIN
    CREATE TABLE [olist_dwh].[bronze].[olist_product_category_name_translation]
    (
        [product_category_name]         NVARCHAR(200),
        [product_category_name_english] NVARCHAR(200),
        [dwh_load_ts]                   DATETIME2 DEFAULT SYSDATETIME(),
        [dwh_source_file]               NVARCHAR(260),
        [dwh_batch_id]                  INT
    );
END
GO

-- checking_schemas

SELECT t.[name] AS [table_name], COUNT(c.[column_id]) AS [column_count]
FROM [olist_dwh].[sys].[tables]  AS t
JOIN [olist_dwh].[sys].[columns] AS c ON c.[object_id] = t.[object_id]
WHERE t.[schema_id] = SCHEMA_ID(N'bronze')
GROUP BY t.[name]
ORDER BY t.[name];
GO



-- metadata_check
  
SELECT t.[name] AS [table_name]
FROM [olist_dwh].[sys].[tables] AS t
WHERE t.[schema_id] = SCHEMA_ID(N'bronze')
  AND (SELECT COUNT(*) FROM [olist_dwh].[sys].[columns] AS c
       WHERE c.[object_id] = t.[object_id]
         AND c.[name] IN (N'dwh_load_ts', N'dwh_source_file', N'dwh_batch_id')) <> 3;
GO

