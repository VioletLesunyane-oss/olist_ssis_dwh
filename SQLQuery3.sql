-- ============================================================================
-- PROJECT: Olist E-Commerce Data Warehouse
-- PHASE 5: Automated Data Quality Test Suite
-- RULE:    Every query below MUST return 0 rows. Any returned row = test failure.
-- ============================================================================

USE [olist_dwh];
GO

-- ============================================================================
-- TEST 1: Bronze vs. Source Row Count Parity (Latest Batch)
-- Checks that rows_read equals rows_written for all Bronze loads in latest run.
-- ============================================================================
SELECT 
    [batch_id], [table_name], [rows_read], [rows_written], [rows_error]
FROM [etl].[load_log]
WHERE [batch_id] = (SELECT MAX([batch_id]) FROM [etl].[batch_log])
  AND [table_name] LIKE N'bronze.%'
  AND ([rows_read] <> [rows_written] OR [rows_error] > 0);
GO

-- ============================================================================
-- TEST 2: Geolocation Deduplication Integrity
-- Checks that silver.geolocation has strictly 1 row per zip_code_prefix.
-- ============================================================================
SELECT 
    [geolocation_zip_code_prefix], COUNT(*) AS [duplicate_count]
FROM [silver].[geolocation]
GROUP BY [geolocation_zip_code_prefix]
HAVING COUNT(*) > 1;
GO

-- ============================================================================
-- TEST 3: Order Reviews Deduplication Integrity
-- Checks that silver.order_reviews has strictly 1 row per review_id.
-- ============================================================================
SELECT 
    [review_id], COUNT(*) AS [duplicate_count]
FROM [silver].[order_reviews]
GROUP BY [review_id]
HAVING COUNT(*) > 1;
GO

-- ============================================================================
-- TEST 4: Core Silver Primary Keys Not Null or Blank
-- Checks customers, orders, products, and sellers for missing business keys.
-- ============================================================================
SELECT N'silver.customers' AS [table_name], [customer_id] AS [bad_key]
FROM [silver].[customers] WHERE [customer_id] IS NULL OR LTRIM(RTRIM([customer_id])) = N''
UNION ALL
SELECT N'silver.orders', [order_id]
FROM [silver].[orders] WHERE [order_id] IS NULL OR LTRIM(RTRIM([order_id])) = N''
UNION ALL
SELECT N'silver.products', [product_id]
FROM [silver].[products] WHERE [product_id] IS NULL OR LTRIM(RTRIM([product_id])) = N''
UNION ALL
SELECT N'silver.sellers', [seller_id]
FROM [silver].[sellers] WHERE [seller_id] IS NULL OR LTRIM(RTRIM([seller_id])) = N'';
GO

-- ============================================================================
-- TEST 5: Product Category English Translation Completeness
-- Checks that no product has a NULL or blank English category name.
-- ============================================================================
SELECT 
    [product_id], [product_category_name], [product_category_name_english]
FROM [silver].[products]
WHERE [product_category_name_english] IS NULL 
   OR LTRIM(RTRIM([product_category_name_english])) = N'';
GO

-- ============================================================================
-- TEST 6: Referential Integrity Across All Gold Fact Foreign Keys
-- Checks for any orphan keys or NULL foreign keys across all 3 fact tables.
-- ============================================================================
SELECT N'fact_sales.date_key' AS [broken_fk], [order_id] FROM [gold].[fact_sales] f LEFT JOIN [gold].[dim_date] d ON f.[date_key] = d.[date_key] WHERE d.[date_key] IS NULL
UNION ALL
SELECT N'fact_sales.customer_key', [order_id] FROM [gold].[fact_sales] f LEFT JOIN [gold].[dim_customer] c ON f.[customer_key] = c.[customer_key] WHERE c.[customer_key] IS NULL
UNION ALL
SELECT N'fact_sales.product_key', [order_id] FROM [gold].[fact_sales] f LEFT JOIN [gold].[dim_product] p ON f.[product_key] = p.[product_key] WHERE p.[product_key] IS NULL
UNION ALL
SELECT N'fact_sales.seller_key', [order_id] FROM [gold].[fact_sales] f LEFT JOIN [gold].[dim_seller] s ON f.[seller_key] = s.[seller_key] WHERE s.[seller_key] IS NULL
UNION ALL
SELECT N'fact_sales.order_status_key', [order_id] FROM [gold].[fact_sales] f LEFT JOIN [gold].[dim_order_status] os ON f.[order_status_key] = os.[order_status_key] WHERE os.[order_status_key] IS NULL
UNION ALL
SELECT N'fact_payments.payment_type_key', [order_id] FROM [gold].[fact_payments] f LEFT JOIN [gold].[dim_payment_type] pt ON f.[payment_type_key] = pt.[payment_type_key] WHERE pt.[payment_type_key] IS NULL
UNION ALL
SELECT N'fact_reviews.date_key', [review_id] FROM [gold].[fact_reviews] f LEFT JOIN [gold].[dim_date] d ON f.[date_key] = d.[date_key] WHERE d.[date_key] IS NULL;
GO

-- ============================================================================
-- TEST 7: All 7 Gold Dimensions Contain Their -1 Unknown Fallback Row
-- ============================================================================
SELECT [dim_name], [row_count]
FROM (
    SELECT N'dim_date' AS [dim_name], COUNT(*) AS [row_count] FROM [gold].[dim_date] WHERE [date_key] = -1
    UNION ALL SELECT N'dim_geography', COUNT(*) FROM [gold].[dim_geography] WHERE [geography_key] = -1
    UNION ALL SELECT N'dim_customer', COUNT(*) FROM [gold].[dim_customer] WHERE [customer_key] = -1
    UNION ALL SELECT N'dim_product', COUNT(*) FROM [gold].[dim_product] WHERE [product_key] = -1
    UNION ALL SELECT N'dim_seller', COUNT(*) FROM [gold].[dim_seller] WHERE [seller_key] = -1
    UNION ALL SELECT N'dim_order_status', COUNT(*) FROM [gold].[dim_order_status] WHERE [order_status_key] = -1
    UNION ALL SELECT N'dim_payment_type', COUNT(*) FROM [gold].[dim_payment_type] WHERE [payment_type_key] = -1
) AS checks
WHERE [row_count] <> 1;
GO

-- ============================================================================
-- TEST 8: Financial Calculation Accuracy (total_item_value = price + freight)
-- ============================================================================
SELECT 
    [order_id], [order_item_id], [price], [freight_value], [total_item_value]
FROM [gold].[fact_sales]
WHERE ABS(ISNULL([total_item_value], 0) - (ISNULL([price], 0) + ISNULL([freight_value], 0))) > 0.01;
GO

-- ============================================================================
-- TEST 9: SCD Type 2 Single Current Version Rule (gold.dim_customer)
-- Checks that no customer_unique_id has more than one is_current = 1 row.
-- ============================================================================
SELECT 
    [customer_unique_id], COUNT(*) AS [active_versions]
FROM [gold].[dim_customer]
WHERE [is_current] = 1
  AND [customer_key] <> -1
GROUP BY [customer_unique_id]
HAVING COUNT(*) > 1;
GO

-- ============================================================================
-- TEST 10: Delivery Metrics Logic Check (Delivered vs. Undelivered Orders)
-- Delivered orders must have days_to_deliver >= 0; undelivered must be NULL.
-- ============================================================================
SELECT 
    f.[order_id], f.[order_item_id], os.[order_status], f.[days_to_deliver]
FROM [gold].[fact_sales] AS f
JOIN [gold].[dim_order_status] AS os ON f.[order_status_key] = os.[order_status_key]
WHERE (os.[is_delivered] = 1 AND (f.[days_to_deliver] IS NULL OR f.[days_to_deliver] < 0))
   OR (os.[is_delivered] = 0 AND f.[days_to_deliver] IS NOT NULL);
GO
