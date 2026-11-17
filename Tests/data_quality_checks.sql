-- ============================================================================
-- PHASE 5: Automated Data Quality Test Suite
-- RULE:    Every query below MUST return 0 rows. Any returned row = test failure.
-- ============================================================================


-- ============================================================================
-- TEST 1: Bronze vs. Source Row Count Parity (Latest Batch)
-- Checks that rows_read equals rows_written with zero errors for Bronze tables.
-- ============================================================================
USE [olist_dwh];
GO

SELECT N'Test 1: Bronze Row Count Parity' AS [test_name],
       CASE WHEN EXISTS (SELECT 1 FROM [etl].[load_log] WHERE [batch_id] = (SELECT MAX([batch_id]) FROM [etl].[batch_log]) AND [table_name] LIKE N'bronze.%' AND ([rows_read] <> [rows_written] OR [rows_error] > 0)) THEN N'FAIL' ELSE N'PASS' END AS [status]
UNION ALL

-- ============================================================================
-- TEST 2: Geolocation Deduplication Integrity
-- Checks that silver.geolocation has strictly 1 row per zip_code_prefix.
-- ============================================================================
SELECT N'Test 2: Geolocation Deduplication',
       CASE WHEN EXISTS (SELECT 1 FROM [silver].[geolocation] GROUP BY [geolocation_zip_code_prefix] HAVING COUNT(*) > 1) THEN N'FAIL' ELSE N'PASS' END
UNION ALL

-- ============================================================================
-- TEST 3: Order Reviews Deduplication Integrity
-- Checks that silver.order_reviews has strictly 1 row per review_id.
-- ============================================================================

SELECT N'Test 3: Order Reviews Deduplication',
       CASE WHEN EXISTS (SELECT 1 FROM [silver].[order_reviews] GROUP BY [review_id] HAVING COUNT(*) > 1) THEN N'FAIL' ELSE N'PASS' END
UNION ALL

-- ============================================================================
-- TEST 4: Core Silver Primary Keys Not Null or Blank
-- Checks customers, orders, products, and sellers for missing business keys.
-- ============================================================================

SELECT N'Test 4: Core Silver Primary Keys Not Null',
       CASE WHEN EXISTS (SELECT 1 FROM [silver].[customers] WHERE [customer_id] IS NULL OR LTRIM(RTRIM([customer_id])) = N'')
              OR EXISTS (SELECT 1 FROM [silver].[orders] WHERE [order_id] IS NULL OR LTRIM(RTRIM([order_id])) = N'')
              OR EXISTS (SELECT 1 FROM [silver].[products] WHERE [product_id] IS NULL OR LTRIM(RTRIM([product_id])) = N'')
              OR EXISTS (SELECT 1 FROM [silver].[sellers] WHERE [seller_id] IS NULL OR LTRIM(RTRIM([seller_id])) = N'') THEN N'FAIL' ELSE N'PASS' END
UNION ALL

-- ============================================================================
-- TEST 5: Product Category English Translation Completeness
-- Checks that no product has a NULL or blank English category name.
-- ============================================================================

SELECT N'Test 5: Product Category English Translation',
       CASE WHEN EXISTS (SELECT 1 FROM [silver].[products] WHERE [product_category_name_english] IS NULL OR LTRIM(RTRIM([product_category_name_english])) = N'') THEN N'FAIL' ELSE N'PASS' END
UNION ALL

-- ============================================================================
-- TEST 6: Referential Integrity Across All Gold Fact Foreign Keys
-- Checks for any orphan keys or NULL foreign keys across all 3 fact tables.
-- ============================================================================

SELECT N'Test 6: Gold Fact Foreign Key Integrity',
       CASE WHEN EXISTS (SELECT 1 FROM [gold].[fact_sales] f LEFT JOIN [gold].[dim_date] d ON f.[date_key] = d.[date_key] WHERE d.[date_key] IS NULL)
              OR EXISTS (SELECT 1 FROM [gold].[fact_sales] f LEFT JOIN [gold].[dim_customer] c ON f.[customer_key] = c.[customer_key] WHERE c.[customer_key] IS NULL)
              OR EXISTS (SELECT 1 FROM [gold].[fact_sales] f LEFT JOIN [gold].[dim_product] p ON f.[product_key] = p.[product_key] WHERE p.[product_key] IS NULL)
              OR EXISTS (SELECT 1 FROM [gold].[fact_sales] f LEFT JOIN [gold].[dim_seller] s ON f.[seller_key] = s.[seller_key] WHERE s.[seller_key] IS NULL)
              OR EXISTS (SELECT 1 FROM [gold].[fact_sales] f LEFT JOIN [gold].[dim_order_status] os ON f.[order_status_key] = os.[order_status_key] WHERE os.[order_status_key] IS NULL) THEN N'FAIL' ELSE N'PASS' END
UNION ALL

-- ============================================================================
-- TEST 7: All 7 Gold Dimensions Contain Their -1 Unknown Fallback Row
-- ============================================================================

SELECT N'Test 7: Gold Dimensions -1 Unknown Row',
       CASE WHEN (SELECT COUNT(*) FROM [gold].[dim_date] WHERE [date_key] = -1) <> 1
              OR (SELECT COUNT(*) FROM [gold].[dim_geography] WHERE [geography_key] = -1) <> 1
              OR (SELECT COUNT(*) FROM [gold].[dim_customer] WHERE [customer_key] = -1) <> 1
              OR (SELECT COUNT(*) FROM [gold].[dim_product] WHERE [product_key] = -1) <> 1
              OR (SELECT COUNT(*) FROM [gold].[dim_seller] WHERE [seller_key] = -1) <> 1
              OR (SELECT COUNT(*) FROM [gold].[dim_order_status] WHERE [order_status_key] = -1) <> 1
              OR (SELECT COUNT(*) FROM [gold].[dim_payment_type] WHERE [payment_type_key] = -1) <> 1 THEN N'FAIL' ELSE N'PASS' END
UNION ALL

-- ============================================================================
-- TEST 8: Financial Calculation Accuracy (total_item_value = price + freight)
-- ============================================================================

SELECT N'Test 8: Financial Calculation Accuracy',
       CASE WHEN EXISTS (SELECT 1 FROM [gold].[fact_sales] WHERE ABS(ISNULL([total_item_value], 0) - (ISNULL([price], 0) + ISNULL([freight_value], 0))) > 0.01) THEN N'FAIL' ELSE N'PASS' END
UNION ALL

-- ============================================================================
-- TEST 9: SCD Type 2 Single Current Version Rule (gold.dim_customer)
-- Checks that no customer_unique_id has more than one is_current = 1 row.
-- ============================================================================

SELECT N'Test 9: SCD Type 2 Single Current Version',
       CASE WHEN EXISTS (SELECT 1 FROM [gold].[dim_customer] WHERE [is_current] = 1 AND [customer_key] <> -1 GROUP BY [customer_unique_id] HAVING COUNT(*) > 1) THEN N'FAIL' ELSE N'PASS' END
UNION ALL

-- ============================================================================
-- TEST 10: Delivery Metrics Logic Check (Delivered vs. Undelivered Orders)
-- Delivered orders must have days_to_deliver >= 0; undelivered must be NULL.
-- ============================================================================
SELECT N'Test 10: Delivery Metrics Logic Check',
       CASE WHEN EXISTS (SELECT 1 FROM [gold].[fact_sales] f JOIN [gold].[dim_order_status] os ON f.[order_status_key] = os.[order_status_key]
                         WHERE (os.[is_delivered] = 1 AND (f.[days_to_deliver] IS NULL OR f.[days_to_deliver] < 0))
                            OR (os.[is_delivered] = 0 AND f.[days_to_deliver] IS NOT NULL)) THEN N'FAIL' ELSE N'PASS' END;
GO
