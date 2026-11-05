USE olist_dwh

IF NOT EXISTS (SELECT 1
               FROM [olist_dwh].[sys].[tables]  AS t
               JOIN [olist_dwh].[sys].[schemas] AS s ON s.[schema_id] = t.[schema_id]
               WHERE s.[name] = N'bronze' AND t.[name] = N'olist_customers')

BEGIN
    CREATE TABLE [olist_dwh].[bronze].[olist_customers]
    (
        [customer_id]              NVARCHAR(50)   NULL,  -- order-level id: a new value for every order
        [customer_unique_id]       NVARCHAR(50)   NULL,  -- the real person id (business key for dim_customer)
        [customer_zip_code_prefix] NVARCHAR(20)   NULL,  -- kept as text so leading zeros survive
        [customer_city]            NVARCHAR(200)  NULL,  -- raw city text, accents and casing untouched
        [customer_state]           NVARCHAR(50)   NULL,  -- raw state code
        [dwh_load_ts]              DATETIME2      NOT NULL CONSTRAINT [df_olist_customers_dwh_load_ts] DEFAULT SYSDATETIME(),  -- load time, set by SQL Server
        [dwh_source_file]          NVARCHAR(260)  NULL,  -- CSV file name, set by SSIS
        [dwh_batch_id]             INT            NULL   -- run id from etl.batch_log, set by SSIS
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
        [geolocation_zip_code_prefix] NVARCHAR(20)   NULL,  -- text, many rows per prefix
        [geolocation_lat]             NVARCHAR(50)   NULL,  -- latitude as text (cast in Silver)
        [geolocation_lng]             NVARCHAR(50)   NULL,  -- longitude as text (cast in Silver)
        [geolocation_city]            NVARCHAR(200)  NULL,  -- raw city text
        [geolocation_state]           NVARCHAR(50)   NULL,  -- raw state code
        [dwh_load_ts]                 DATETIME2      NOT NULL CONSTRAINT [df_olist_geolocation_dwh_load_ts] DEFAULT SYSDATETIME(),  -- load time, set by SQL Server
        [dwh_source_file]             NVARCHAR(260)  NULL,  -- CSV file name, set by SSIS
        [dwh_batch_id]                INT            NULL   -- run id from etl.batch_log, set by SSIS
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
        [order_id]            NVARCHAR(50)   NULL,  -- order the item belongs to
        [order_item_id]       NVARCHAR(50)   NULL,  -- item sequence within the order
        [product_id]          NVARCHAR(50)   NULL,  -- product sold
        [seller_id]           NVARCHAR(50)   NULL,  -- seller fulfilling this item
        [shipping_limit_date] NVARCHAR(50)   NULL,  -- timestamp as text
        [price]               NVARCHAR(50)   NULL,  -- item price as text (cast in Silver)
        [freight_value]       NVARCHAR(50)   NULL,  -- freight as text (cast in Silver)
        [dwh_load_ts]         DATETIME2      NOT NULL CONSTRAINT [df_olist_order_items_dwh_load_ts] DEFAULT SYSDATETIME(),  -- load time, set by SQL Server
        [dwh_source_file]     NVARCHAR(260)  NULL,  -- CSV file name, set by SSIS
        [dwh_batch_id]        INT            NULL   -- run id from etl.batch_log, set by SSIS
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
        [order_id]             NVARCHAR(50)   NULL,  -- order paid
        [payment_sequential]   NVARCHAR(50)   NULL,  -- payment line number within the order
        [payment_type]         NVARCHAR(50)   NULL,  -- credit_card, boleto, voucher, debit_card, not_defined
        [payment_installments] NVARCHAR(50)   NULL,  -- number of installments as text
        [payment_value]        NVARCHAR(50)   NULL,  -- payment amount as text
        [dwh_load_ts]          DATETIME2      NOT NULL CONSTRAINT [df_olist_order_payments_dwh_load_ts] DEFAULT SYSDATETIME(),  -- load time, set by SQL Server
        [dwh_source_file]      NVARCHAR(260)  NULL,  -- CSV file name, set by SSIS
        [dwh_batch_id]         INT            NULL   -- run id from etl.batch_log, set by SSIS
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
        [review_id]               NVARCHAR(50)   NULL,  -- can repeat (duplicates handled in Silver)
        [order_id]                NVARCHAR(50)   NULL,  -- order reviewed
        [review_score]            NVARCHAR(50)   NULL,  -- 1 to 5 as text
        [review_comment_title]    NVARCHAR(500)  NULL,  -- optional title
        [review_comment_message]  NVARCHAR(MAX)  NULL,  -- free text: may contain commas and line breaks
        [review_creation_date]    NVARCHAR(50)   NULL,  -- timestamp as text
        [review_answer_timestamp] NVARCHAR(50)   NULL,  -- timestamp as text
        [dwh_load_ts]             DATETIME2      NOT NULL CONSTRAINT [df_olist_order_reviews_dwh_load_ts] DEFAULT SYSDATETIME(),  -- load time, set by SQL Server
        [dwh_source_file]         NVARCHAR(260)  NULL,  -- CSV file name, set by SSIS
        [dwh_batch_id]            INT            NULL   -- run id from etl.batch_log, set by SSIS
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
        [order_id]                      NVARCHAR(50)   NULL,  -- order business key
        [customer_id]                   NVARCHAR(50)   NULL,  -- order-level customer id
        [order_status]                  NVARCHAR(50)   NULL,  -- delivered, shipped, canceled, ...
        [order_purchase_timestamp]      NVARCHAR(50)   NULL,  -- timestamp as text
        [order_approved_at]             NVARCHAR(50)   NULL,  -- may be empty
        [order_delivered_carrier_date]  NVARCHAR(50)   NULL,  -- may be empty
        [order_delivered_customer_date] NVARCHAR(50)   NULL,  -- empty for undelivered orders
        [order_estimated_delivery_date] NVARCHAR(50)   NULL,  -- timestamp as text
        [dwh_load_ts]                   DATETIME2      NOT NULL CONSTRAINT [df_olist_orders_dwh_load_ts] DEFAULT SYSDATETIME(),  -- load time, set by SQL Server
        [dwh_source_file]               NVARCHAR(260)  NULL,  -- CSV file name, set by SSIS
        [dwh_batch_id]                  INT            NULL   -- run id from etl.batch_log, set by SSIS
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
        [product_id]                 NVARCHAR(50)   NULL,  -- product business key
        [product_category_name]      NVARCHAR(200)  NULL,  -- Portuguese category, may be empty
        [product_name_lenght]        NVARCHAR(50)   NULL,  -- source spelling kept on purpose (renamed in Silver)
        [product_description_lenght] NVARCHAR(50)   NULL,  -- source spelling kept on purpose (renamed in Silver)
        [product_photos_qty]         NVARCHAR(50)   NULL,  -- number of photos
        [product_weight_g]           NVARCHAR(50)   NULL,  -- weight in grams
        [product_length_cm]          NVARCHAR(50)   NULL,  -- length in cm
        [product_height_cm]          NVARCHAR(50)   NULL,  -- height in cm
        [product_width_cm]           NVARCHAR(50)   NULL,  -- width in cm
        [dwh_load_ts]                DATETIME2      NOT NULL CONSTRAINT [df_olist_products_dwh_load_ts] DEFAULT SYSDATETIME(),  -- load time, set by SQL Server
        [dwh_source_file]            NVARCHAR(260)  NULL,  -- CSV file name, set by SSIS
        [dwh_batch_id]               INT            NULL   -- run id from etl.batch_log, set by SSIS
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
        [seller_id]              NVARCHAR(50)   NULL,  -- seller business key
        [seller_zip_code_prefix] NVARCHAR(20)   NULL,  -- kept as text so leading zeros survive
        [seller_city]            NVARCHAR(200)  NULL,  -- raw city text
        [seller_state]           NVARCHAR(50)   NULL,  -- raw state code
        [dwh_load_ts]            DATETIME2      NOT NULL CONSTRAINT [df_olist_sellers_dwh_load_ts] DEFAULT SYSDATETIME(),  -- load time, set by SQL Server
        [dwh_source_file]        NVARCHAR(260)  NULL,  -- CSV file name, set by SSIS
        [dwh_batch_id]           INT            NULL   -- run id from etl.batch_log, set by SSIS
    );
END
GO

-- Source file: product_category_name_translation.csv
IF NOT EXISTS (SELECT 1
               FROM [olist_dwh].[sys].[tables]  AS t
               JOIN [olist_dwh].[sys].[schemas] AS s ON s.[schema_id] = t.[schema_id]
               WHERE s.[name] = N'bronze' AND t.[name] = N'product_category_name_translation')
BEGIN
    CREATE TABLE [olist_dwh].[bronze].[product_category_name_translation]
    (
        [product_category_name]         NVARCHAR(200)  NULL,  -- Portuguese category name
        [product_category_name_english] NVARCHAR(200)  NULL,  -- English category name
        [dwh_load_ts]                   DATETIME2      NOT NULL CONSTRAINT [df_product_category_name_translation_dwh_load_ts] DEFAULT SYSDATETIME(),  -- load time, set by SQL Server
        [dwh_source_file]               NVARCHAR(260)  NULL,  -- CSV file name, set by SSIS
        [dwh_batch_id]                  INT            NULL   -- run id from etl.batch_log, set by SSIS
    );
END
GO
