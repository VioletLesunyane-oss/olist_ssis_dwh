-- ============================================================================
-- PHASE 2: Silver Layer DDL Script (Cleansed, Typed, and Standardised)
-- DESIGN CONVENTION: Strict snake_case & Re-runnable Guards
-- ============================================================================

USE olist_dwh;
GO

-- ============================================================================
-- 1. TABLE: silver.customers
-- TRANSFORMATIONS: Trim, proper-case city, upper-case state, pad zip to 5 chars
-- ============================================================================
IF NOT EXISTS (SELECT 1
               FROM [olist_dwh].[sys].[tables]  AS t
               JOIN [olist_dwh].[sys].[schemas] AS s ON s.[schema_id] = t.[schema_id]
               WHERE s.[name] = N'silver' AND t.[name] = N'customers')
BEGIN
    CREATE TABLE [olist_dwh].[silver].[customers]
    (
        [customer_id]              NVARCHAR(50)   NOT NULL,  -- order-level customer id (one row per order's customer)
        [customer_unique_id]       NVARCHAR(50)   NOT NULL,  -- the real person id (business key for dim_customer)
        [customer_zip_code_prefix] NVARCHAR(5)    NULL,      -- padded to 5 characters, e.g. 1046 becomes 01046
        [customer_city]            NVARCHAR(100)  NULL,      -- trimmed, proper case
        [customer_state]           NVARCHAR(10)   NULL,      -- trimmed, upper case
        [dwh_load_ts]              DATETIME2      NOT NULL CONSTRAINT [df_customers_dwh_load_ts] DEFAULT SYSDATETIME(),  -- load time, set by SQL Server
        [dwh_batch_id]             INT            NULL,      -- run id from etl.batch_log, set by SSIS
        CONSTRAINT [pk_customers] PRIMARY KEY CLUSTERED ([customer_id])
    );
END
GO


-- ============================================================================
-- 2. TABLE: silver.sellers
-- TRANSFORMATIONS: Same standardisation rules as silver.customers
-- ============================================================================
IF NOT EXISTS (SELECT 1
               FROM [olist_dwh].[sys].[tables]  AS t
               JOIN [olist_dwh].[sys].[schemas] AS s ON s.[schema_id] = t.[schema_id]
               WHERE s.[name] = N'silver' AND t.[name] = N'sellers')
BEGIN
    CREATE TABLE [olist_dwh].[silver].[sellers]
    (
        [seller_id]              NVARCHAR(50)   NOT NULL,  -- seller business key
        [seller_zip_code_prefix] NVARCHAR(5)    NULL,      -- padded to 5 characters
        [seller_city]            NVARCHAR(100)  NULL,      -- trimmed, proper case
        [seller_state]           NVARCHAR(10)   NULL,      -- trimmed, upper case
        [dwh_load_ts]            DATETIME2      NOT NULL CONSTRAINT [df_sellers_dwh_load_ts] DEFAULT SYSDATETIME(),  -- load time, set by SQL Server
        [dwh_batch_id]           INT            NULL,      -- run id from etl.batch_log, set by SSIS
        CONSTRAINT [pk_sellers] PRIMARY KEY CLUSTERED ([seller_id])
    );
END
GO

-- ============================================================================
-- 3. TABLE: silver.products
-- TRANSFORMATIONS: Fix misspelt columns, map null categories to 'Unknown'
-- ============================================================================
IF NOT EXISTS (SELECT 1
               FROM [olist_dwh].[sys].[tables]  AS t
               JOIN [olist_dwh].[sys].[schemas] AS s ON s.[schema_id] = t.[schema_id]
               WHERE s.[name] = N'silver' AND t.[name] = N'products')
BEGIN
    CREATE TABLE [olist_dwh].[silver].[products]
    (
        [product_id]                    NVARCHAR(50)   NOT NULL,  -- product business key
        [product_category_name]         NVARCHAR(200)  NOT NULL,  -- Portuguese category, Unknown when missing
        [product_category_name_english] NVARCHAR(200)  NOT NULL,  -- English category from the translation table, Unknown when missing
        [product_name_length]           INT            NULL,      -- fixed spelling of product_name_lenght
        [product_description_length]    INT            NULL,      -- fixed spelling of product_description_lenght
        [product_photos_qty]            INT            NULL,      -- number of photos
        [product_weight_g]              INT            NULL,      -- weight in grams
        [product_length_cm]             INT            NULL,      -- length in cm
        [product_height_cm]             INT            NULL,      -- height in cm
        [product_width_cm]              INT            NULL,      -- width in cm
        [dwh_load_ts]                   DATETIME2      NOT NULL CONSTRAINT [df_products_dwh_load_ts] DEFAULT SYSDATETIME(),  -- load time, set by SQL Server
        [dwh_batch_id]                  INT            NULL,      -- run id from etl.batch_log, set by SSIS
        CONSTRAINT [pk_products] PRIMARY KEY CLUSTERED ([product_id])
    );
END
GO


-- ============================================================================
-- 4. TABLE: silver.geolocation
-- TRANSFORMATIONS: Collapse data to 1 unique row per zip_code_prefix
-- ============================================================================
IF NOT EXISTS (SELECT 1
               FROM [olist_dwh].[sys].[tables]  AS t
               JOIN [olist_dwh].[sys].[schemas] AS s ON s.[schema_id] = t.[schema_id]
               WHERE s.[name] = N'silver' AND t.[name] = N'geolocation')
BEGIN
    CREATE TABLE [olist_dwh].[silver].[geolocation]
    (
        [geolocation_zip_code_prefix] NVARCHAR(5)    NOT NULL,  -- one row per zip prefix
        [geolocation_lat]             DECIMAL(9,6)   NULL,      -- average latitude for the prefix
        [geolocation_lng]             DECIMAL(9,6)   NULL,      -- average longitude for the prefix
        [geolocation_city]            NVARCHAR(100)  NULL,      -- most frequent city for the prefix
        [geolocation_state]           NVARCHAR(10)   NULL,      -- upper-case state code
        [dwh_load_ts]                 DATETIME2      NOT NULL CONSTRAINT [df_geolocation_dwh_load_ts] DEFAULT SYSDATETIME(),  -- load time, set by SQL Server
        [dwh_batch_id]                INT            NULL,      -- run id from etl.batch_log, set by SSIS
        CONSTRAINT [pk_geolocation] PRIMARY KEY CLUSTERED ([geolocation_zip_code_prefix])
    );
END
GO


-- ============================================================================
-- 5. TABLE: silver.orders
-- TRANSFORMATIONS: Cast timestamps to DATETIME2, flag is_delivered
-- ============================================================================
IF NOT EXISTS (SELECT 1
               FROM [olist_dwh].[sys].[tables]  AS t
               JOIN [olist_dwh].[sys].[schemas] AS s ON s.[schema_id] = t.[schema_id]
               WHERE s.[name] = N'silver' AND t.[name] = N'orders')
BEGIN
    CREATE TABLE [olist_dwh].[silver].[orders]
    (
        [order_id]                      NVARCHAR(50)   NOT NULL,  -- order business key
        [customer_id]                   NVARCHAR(50)   NOT NULL,  -- order-level customer id
        [order_status]                  NVARCHAR(20)   NULL,      -- trimmed, lower case
        [order_purchase_ts]             DATETIME2      NULL,      -- renamed from order_purchase_timestamp (the name the brief uses)
        [order_approved_at]             DATETIME2      NULL,      -- empty if never approved
        [order_delivered_carrier_date]  DATETIME2      NULL,      -- empty if not yet shipped
        [order_delivered_customer_date] DATETIME2      NULL,      -- empty for undelivered orders: kept, never replaced
        [order_estimated_delivery_date] DATETIME2      NULL,      -- promised delivery date
        [is_delivered]                  BIT            NOT NULL,  -- derived flag: 1 when order_status is delivered, else 0
        [dwh_load_ts]                   DATETIME2      NOT NULL CONSTRAINT [df_orders_dwh_load_ts] DEFAULT SYSDATETIME(),  -- load time, set by SQL Server
        [dwh_batch_id]                  INT            NULL,      -- run id from etl.batch_log, set by SSIS
        CONSTRAINT [pk_orders] PRIMARY KEY CLUSTERED ([order_id])
    );
END
GO

-- ============================================================================
-- 6. TABLE: silver.order_items
-- TRANSFORMATIONS: Cast numeric prices, derive total_item_value
-- ============================================================================
IF NOT EXISTS (SELECT 1
               FROM [olist_dwh].[sys].[tables]  AS t
               JOIN [olist_dwh].[sys].[schemas] AS s ON s.[schema_id] = t.[schema_id]
               WHERE s.[name] = N'silver' AND t.[name] = N'order_items')
BEGIN
    CREATE TABLE [olist_dwh].[silver].[order_items]
    (
        [order_id]            NVARCHAR(50)   NOT NULL,  -- order the item belongs to
        [order_item_id]       INT            NOT NULL,  -- item sequence within the order
        [product_id]          NVARCHAR(50)   NOT NULL,  -- product sold
        [seller_id]           NVARCHAR(50)   NOT NULL,  -- seller fulfilling this item
        [shipping_limit_date] DATETIME2      NULL,      -- seller's shipping deadline
        [price]               DECIMAL(10,2)  NULL,      -- item price
        [freight_value]       DECIMAL(10,2)  NULL,      -- freight charged for the item
        [total_item_value]    DECIMAL(10,2)  NULL,      -- derived: price + freight_value
        [dwh_load_ts]         DATETIME2      NOT NULL CONSTRAINT [df_order_items_dwh_load_ts] DEFAULT SYSDATETIME(),  -- load time, set by SQL Server
        [dwh_batch_id]        INT            NULL,      -- run id from etl.batch_log, set by SSIS
        CONSTRAINT [pk_order_items] PRIMARY KEY CLUSTERED ([order_id], [order_item_id])
    );
END
GO

-- ============================================================================
-- 7. TABLE: silver.order_payments
-- TRANSFORMATIONS: Cast types, standardise payment_type (not_defined -> Unknown)
-- ============================================================================
IF NOT EXISTS (SELECT 1
               FROM [olist_dwh].[sys].[tables]  AS t
               JOIN [olist_dwh].[sys].[schemas] AS s ON s.[schema_id] = t.[schema_id]
               WHERE s.[name] = N'silver' AND t.[name] = N'order_payments')
BEGIN
    CREATE TABLE [olist_dwh].[silver].[order_payments]
    (
        [order_payment_id]    INT IDENTITY(1,1) NOT NULL,
        [order_id]            NVARCHAR(50)   NOT NULL,
        [payment_sequential]  INT            NULL,
        [payment_type]        NVARCHAR(50)   NULL,
        [payment_installments] INT            NULL,
        [payment_value]       DECIMAL(10,2)  NULL,
        [dwh_load_ts]         DATETIME2      NOT NULL CONSTRAINT [df_order_payments_dwh_load_ts] DEFAULT SYSDATETIME(),
        [dwh_batch_id]        INT            NULL,
        CONSTRAINT [pk_order_payments] PRIMARY KEY CLUSTERED ([order_payment_id])
    );
END
GO


-- ============================================================================
-- 8. TABLE: silver.order_reviews
-- TRANSFORMATIONS: Deduplicated on review_id, cast score to TINYINT
-- ============================================================================
IF NOT EXISTS (SELECT 1
               FROM [olist_dwh].[sys].[tables]  AS t
               JOIN [olist_dwh].[sys].[schemas] AS s ON s.[schema_id] = t.[schema_id]
               WHERE s.[name] = N'silver' AND t.[name] = N'order_reviews')
BEGIN
    CREATE TABLE [olist_dwh].[silver].[order_reviews]
    (
        [review_id]               NVARCHAR(50)   NOT NULL,  -- one row per review_id after de-duplication
        [order_id]                NVARCHAR(50)   NOT NULL,  -- order reviewed
        [review_score]            TINYINT        NULL,      -- 1 to 5
        [review_comment_title]    NVARCHAR(200)  NULL,      -- optional title
        [review_comment_message]  NVARCHAR(MAX)  NULL,      -- free text, may contain commas and line breaks
        [review_creation_date]    DATETIME2      NULL,      -- survey sent
        [review_answer_timestamp] DATETIME2      NULL,      -- survey answered
        [dwh_load_ts]             DATETIME2      NOT NULL CONSTRAINT [df_order_reviews_dwh_load_ts] DEFAULT SYSDATETIME(),  -- load time, set by SQL Server
        [dwh_batch_id]            INT            NULL,      -- run id from etl.batch_log, set by SSIS
        CONSTRAINT [pk_order_reviews] PRIMARY KEY CLUSTERED ([review_id])
    );
END
GO

-- ============================================================================
-- 9. TABLE: silver.category_translation
-- TRANSFORMATIONS: Portuguese to English category reference mapping lookup table
-- ============================================================================
IF NOT EXISTS (SELECT 1
               FROM [olist_dwh].[sys].[tables]  AS t
               JOIN [olist_dwh].[sys].[schemas] AS s ON s.[schema_id] = t.[schema_id]
               WHERE s.[name] = N'silver' AND t.[name] = N'category_translation')
BEGIN
    CREATE TABLE [olist_dwh].[silver].[category_translation]
    (
        [product_category_name]         NVARCHAR(100)  NOT NULL,  -- Portuguese category name
        [product_category_name_english] NVARCHAR(100)  NOT NULL,  -- English category name
        [dwh_load_ts]                   DATETIME2      NOT NULL CONSTRAINT [df_category_translation_dwh_load_ts] DEFAULT SYSDATETIME(),  -- load time, set by SQL Server
        [dwh_batch_id]                  INT            NULL,      -- run id from etl.batch_log, set by SSIS
        CONSTRAINT [pk_category_translation] PRIMARY KEY CLUSTERED ([product_category_name])
    );
END
GO

-- ============================================================================
-- PHASE 2: Pre-populate Missing Product Category Translations (Quirk #6)
-- ============================================================================

USE olist_dwh;
GO

-- Insert pc_gamer lookup if missing
IF NOT EXISTS (SELECT 1 
               FROM silver.category_translation 
               WHERE product_category_name = 'pc_gamer'
)
BEGIN
    INSERT INTO silver.category_translation (product_category_name, product_category_name_english, dwh_batch_id)
    VALUES ('pc_gamer', 'pc_gamer', -1);
END;

-- Insert portateis_cozinha_e_preparadores_de_alimentos if missing
IF NOT EXISTS (SELECT 1 
               FROM silver.category_translation 
               WHERE product_category_name = 'portateis_cozinha_e_preparadores_de_alimentos'
)
BEGIN
    INSERT INTO silver.category_translation (product_category_name, product_category_name_english, dwh_batch_id)
    VALUES ('portateis_cozinha_e_preparadores_de_alimentos', 'kitchen_portables_and_food_preparators', -1);
END;
GO

-- Verify the table structure is ready
SELECT * FROM silver.category_translation;
GO
