-- ============================================================================
-- PHASE 5: Automated Data Quality Test Suite
-- RULE:    Every query below MUST return 0 rows. Any returned row = test failure.
-- ============================================================================


USE [olist_dwh];
GO

-- ============================================================================
-- TEST 1: Bronze row count = CSV row count (Layer: Bronze / ETL Log)
-- Verifies that rows_read from CSV equals rows_written in Bronze for the
-- latest batch run, with zero rejected rows.
-- ============================================================================
SELECT 
    [batch_id],
    [table_name],
    [rows_read] AS [csv_row_count],
    [rows_written] AS [bronze_row_count],
    [rows_error]
FROM [etl].[load_log]
WHERE [batch_id] = (SELECT MAX([batch_id]) FROM [etl].[batch_log])
  AND [table_name] LIKE N'bronze.%'
  AND ([rows_read] <> [rows_written] OR [rows_error] > 0);
GO

-- ============================================================================
-- TEST 2: No duplicate review_id (Layer: Silver)
-- ============================================================================
SELECT 
    [review_id],
    COUNT(*) AS [duplicate_count]
FROM [silver].[order_reviews]
GROUP BY [review_id]
HAVING COUNT(*) > 1;
GO

-- ============================================================================
-- TEST 3: One row per zip_code_prefix in geolocation (Layer: Silver)
-- ============================================================================
SELECT 
    [geolocation_zip_code_prefix],
    COUNT(*) AS [row_count]
FROM [silver].[geolocation]
GROUP BY [geolocation_zip_code_prefix]
HAVING COUNT(*) > 1;
GO

-- ============================================================================
-- TEST 4: No NULL business keys in any dimension (Layer: Gold)
-- ============================================================================
SELECT N'gold.dim_date' AS [dimension_table], CAST([date_key] AS NVARCHAR(50)) AS [surrogate_key]
FROM [gold].[dim_date] WHERE [full_date] IS NULL
UNION ALL
SELECT N'gold.dim_geography', CAST([geography_key] AS NVARCHAR(50))
FROM [gold].[dim_geography] WHERE [zip_code_prefix] IS NULL OR LTRIM(RTRIM([zip_code_prefix])) = N''
UNION ALL
SELECT N'gold.dim_customer', CAST([customer_key] AS NVARCHAR(50))
FROM [gold].[dim_customer] WHERE [customer_unique_id] IS NULL OR LTRIM(RTRIM([customer_unique_id])) = N''
UNION ALL
SELECT N'gold.dim_product', CAST([product_key] AS NVARCHAR(50))
FROM [gold].[dim_product] WHERE [product_id] IS NULL OR LTRIM(RTRIM([product_id])) = N''
UNION ALL
SELECT N'gold.dim_seller', CAST([seller_key] AS NVARCHAR(50))
FROM [gold].[dim_seller] WHERE [seller_id] IS NULL OR LTRIM(RTRIM([seller_id])) = N''
UNION ALL
SELECT N'gold.dim_order_status', CAST([order_status_key] AS NVARCHAR(50))
FROM [gold].[dim_order_status] WHERE [order_status] IS NULL OR LTRIM(RTRIM([order_status])) = N''
UNION ALL
SELECT N'gold.dim_payment_type', CAST([payment_type_key] AS NVARCHAR(50))
FROM [gold].[dim_payment_type] WHERE [payment_type] IS NULL OR LTRIM(RTRIM([payment_type])) = N'';
GO

-- ============================================================================
-- TEST 5: Every surrogate key is unique per dimension (Layer: Gold)
-- ============================================================================
SELECT N'gold.dim_date' AS [dimension_table], [date_key] AS [duplicate_sk], COUNT(*) AS [row_count]
FROM [gold].[dim_date] GROUP BY [date_key] HAVING COUNT(*) > 1
UNION ALL
SELECT N'gold.dim_geography', [geography_key], COUNT(*)
FROM [gold].[dim_geography] GROUP BY [geography_key] HAVING COUNT(*) > 1
UNION ALL
SELECT N'gold.dim_customer', [customer_key], COUNT(*)
FROM [gold].[dim_customer] GROUP BY [customer_key] HAVING COUNT(*) > 1
UNION ALL
SELECT N'gold.dim_product', [product_key], COUNT(*)
FROM [gold].[dim_product] GROUP BY [product_key] HAVING COUNT(*) > 1
UNION ALL
SELECT N'gold.dim_seller', [seller_key], COUNT(*)
FROM [gold].[dim_seller] GROUP BY [seller_key] HAVING COUNT(*) > 1
UNION ALL
SELECT N'gold.dim_order_status', [order_status_key], COUNT(*)
FROM [gold].[dim_order_status] GROUP BY [order_status_key] HAVING COUNT(*) > 1
UNION ALL
SELECT N'gold.dim_payment_type', [payment_type_key], COUNT(*)
FROM [gold].[dim_payment_type] GROUP BY [payment_type_key] HAVING COUNT(*) > 1;
GO

-- ============================================================================
-- TEST 6: No orphan FKs in facts — every FK exists in its dim (Layer: Gold)
-- ============================================================================
SELECT N'fact_sales.date_key' AS [broken_fk], [order_id]
FROM [gold].[fact_sales] f LEFT JOIN [gold].[dim_date] d ON f.[date_key] = d.[date_key] WHERE d.[date_key] IS NULL
UNION ALL
SELECT N'fact_sales.customer_key', [order_id]
FROM [gold].[fact_sales] f LEFT JOIN [gold].[dim_customer] c ON f.[customer_key] = c.[customer_key] WHERE c.[customer_key] IS NULL
UNION ALL
SELECT N'fact_sales.product_key', [order_id]
FROM [gold].[fact_sales] f LEFT JOIN [gold].[dim_product] p ON f.[product_key] = p.[product_key] WHERE p.[product_key] IS NULL
UNION ALL
SELECT N'fact_sales.seller_key', [order_id]
FROM [gold].[fact_sales] f LEFT JOIN [gold].[dim_seller] s ON f.[seller_key] = s.[seller_key] WHERE s.[seller_key] IS NULL
UNION ALL
SELECT N'fact_sales.order_status_key', [order_id]
FROM [gold].[fact_sales] f LEFT JOIN [gold].[dim_order_status] os ON f.[order_status_key] = os.[order_status_key] WHERE os.[order_status_key] IS NULL
UNION ALL
SELECT N'fact_payments.date_key', [order_id]
FROM [gold].[fact_payments] fp LEFT JOIN [gold].[dim_date] d ON fp.[date_key] = d.[date_key] WHERE d.[date_key] IS NULL
UNION ALL
SELECT N'fact_payments.customer_key', [order_id]
FROM [gold].[fact_payments] fp LEFT JOIN [gold].[dim_customer] c ON fp.[customer_key] = c.[customer_key] WHERE c.[customer_key] IS NULL
UNION ALL
SELECT N'fact_payments.payment_type_key', [order_id]
FROM [gold].[fact_payments] fp LEFT JOIN [gold].[dim_payment_type] pt ON fp.[payment_type_key] = pt.[payment_type_key] WHERE pt.[payment_type_key] IS NULL
UNION ALL
SELECT N'fact_reviews.date_key', [review_id]
FROM [gold].[fact_reviews] fr LEFT JOIN [gold].[dim_date] d ON fr.[date_key] = d.[date_key] WHERE d.[date_key] IS NULL
UNION ALL
SELECT N'fact_reviews.customer_key', [review_id]
FROM [gold].[fact_reviews] fr LEFT JOIN [gold].[dim_customer] c ON fr.[customer_key] = c.[customer_key] WHERE c.[customer_key] IS NULL;
GO

-- ============================================================================
-- TEST 7: SUM(fact_sales.price) = SUM(silver.order_items.price) (Layer: Gold)
-- ============================================================================
SELECT 
    g.[gold_total_price],
    s.[silver_total_price],
    (g.[gold_total_price] - s.[silver_total_price]) AS [variance]
FROM (SELECT ISNULL(SUM([price]), 0) AS [gold_total_price] FROM [gold].[fact_sales]) AS g
CROSS JOIN (SELECT ISNULL(SUM([price]), 0) AS [silver_total_price] FROM [silver].[order_items]) AS s
WHERE ABS(g.[gold_total_price] - s.[silver_total_price]) > 0.01;
GO

-- ============================================================================
-- TEST 8: SUM(fact_payments.payment_value) = SUM(silver.order_payments.payment_value) (Layer: Gold)
-- ============================================================================
SELECT 
    g.[gold_total_payment],
    s.[silver_total_payment],
    (g.[gold_total_payment] - s.[silver_total_payment]) AS [variance]
FROM (SELECT ISNULL(SUM([payment_value]), 0) AS [gold_total_payment] FROM [gold].[fact_payments]) AS g
CROSS JOIN (SELECT ISNULL(SUM([payment_value]), 0) AS [silver_total_payment] FROM [silver].[order_payments]) AS s
WHERE ABS(g.[gold_total_payment] - s.[silver_total_payment]) > 0.01;
GO

-- ============================================================================
-- TEST 9: Only one is_current = 1 row per customer_unique_id (Layer: Gold)
-- ============================================================================
SELECT 
    [customer_unique_id],
    COUNT(*) AS [current_row_count]
FROM [gold].[dim_customer]
WHERE [is_current] = 1
  AND [customer_key] <> -1
GROUP BY [customer_unique_id]
HAVING COUNT(*) > 1;
GO

-- ============================================================================
-- TEST 10: No negative prices or freight values (Layer: Silver)
-- ============================================================================
SELECT 
    [order_id],
    [order_item_id],
    [price],
    [freight_value]
FROM [silver].[order_items]
WHERE [price] < 0 
   OR [freight_value] < 0;
GO



