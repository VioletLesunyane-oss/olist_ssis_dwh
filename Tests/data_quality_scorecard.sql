-- ============================================================================
-- SCRIPT:  Phase 5 Data Quality Summary Scorecard
-- PURPOSE: Runs all 10 automated data quality checks across the Bronze,
--          Silver, and Gold layers in a single query and displays a clear
--          PASS or FAIL status for each rule.
-- ============================================================================

USE [olist_dwh];
GO

SELECT N'Test 1: Bronze row count = CSV row count (Bronze)' AS [test_name],
       CASE WHEN EXISTS (
           SELECT 1 
           FROM [etl].[load_log] 
           WHERE [batch_id] = (SELECT MAX([batch_id]) FROM [etl].[batch_log]) 
             AND [table_name] LIKE N'bronze.%' 
             AND ([rows_read] <> [rows_written] OR [rows_error] > 0)
       ) THEN N'FAIL' ELSE N'PASS' END AS [status]
UNION ALL
SELECT N'Test 2: No duplicate review_id (Silver)',
       CASE WHEN EXISTS (
           SELECT 1 
           FROM [silver].[order_reviews] 
           GROUP BY [review_id] 
           HAVING COUNT(*) > 1
       ) THEN N'FAIL' ELSE N'PASS' END
UNION ALL
SELECT N'Test 3: One row per zip_code_prefix in geolocation (Silver)',
       CASE WHEN EXISTS (
           SELECT 1 
           FROM [silver].[geolocation] 
           GROUP BY [geolocation_zip_code_prefix] 
           HAVING COUNT(*) > 1
       ) THEN N'FAIL' ELSE N'PASS' END
UNION ALL
SELECT N'Test 4: No NULL business keys in any dimension (Gold)',
       CASE WHEN EXISTS (SELECT 1 FROM [gold].[dim_date] WHERE [full_date] IS NULL)
              OR EXISTS (SELECT 1 FROM [gold].[dim_geography] WHERE [zip_code_prefix] IS NULL OR LTRIM(RTRIM([zip_code_prefix])) = N'')
              OR EXISTS (SELECT 1 FROM [gold].[dim_customer] WHERE [customer_unique_id] IS NULL OR LTRIM(RTRIM([customer_unique_id])) = N'')
              OR EXISTS (SELECT 1 FROM [gold].[dim_product] WHERE [product_id] IS NULL OR LTRIM(RTRIM([product_id])) = N'')
              OR EXISTS (SELECT 1 FROM [gold].[dim_seller] WHERE [seller_id] IS NULL OR LTRIM(RTRIM([seller_id])) = N'')
              OR EXISTS (SELECT 1 FROM [gold].[dim_order_status] WHERE [order_status] IS NULL OR LTRIM(RTRIM([order_status])) = N'')
              OR EXISTS (SELECT 1 FROM [gold].[dim_payment_type] WHERE [payment_type] IS NULL OR LTRIM(RTRIM([payment_type])) = N'')
       THEN N'FAIL' ELSE N'PASS' END
UNION ALL
SELECT N'Test 5: Every surrogate key is unique per dimension (Gold)',
       CASE WHEN EXISTS (SELECT 1 FROM [gold].[dim_date] GROUP BY [date_key] HAVING COUNT(*) > 1)
              OR EXISTS (SELECT 1 FROM [gold].[dim_geography] GROUP BY [geography_key] HAVING COUNT(*) > 1)
              OR EXISTS (SELECT 1 FROM [gold].[dim_customer] GROUP BY [customer_key] HAVING COUNT(*) > 1)
              OR EXISTS (SELECT 1 FROM [gold].[dim_product] GROUP BY [product_key] HAVING COUNT(*) > 1)
              OR EXISTS (SELECT 1 FROM [gold].[dim_seller] GROUP BY [seller_key] HAVING COUNT(*) > 1)
              OR EXISTS (SELECT 1 FROM [gold].[dim_order_status] GROUP BY [order_status_key] HAVING COUNT(*) > 1)
              OR EXISTS (SELECT 1 FROM [gold].[dim_payment_type] GROUP BY [payment_type_key] HAVING COUNT(*) > 1)
       THEN N'FAIL' ELSE N'PASS' END
UNION ALL
SELECT N'Test 6: No orphan FKs in facts (Gold)',
       CASE WHEN EXISTS (SELECT 1 FROM [gold].[fact_sales] f LEFT JOIN [gold].[dim_date] d ON f.[date_key] = d.[date_key] WHERE d.[date_key] IS NULL)
              OR EXISTS (SELECT 1 FROM [gold].[fact_sales] f LEFT JOIN [gold].[dim_customer] c ON f.[customer_key] = c.[customer_key] WHERE c.[customer_key] IS NULL)
              OR EXISTS (SELECT 1 FROM [gold].[fact_sales] f LEFT JOIN [gold].[dim_product] p ON f.[product_key] = p.[product_key] WHERE p.[product_key] IS NULL)
              OR EXISTS (SELECT 1 FROM [gold].[fact_sales] f LEFT JOIN [gold].[dim_seller] s ON f.[seller_key] = s.[seller_key] WHERE s.[seller_key] IS NULL)
              OR EXISTS (SELECT 1 FROM [gold].[fact_sales] f LEFT JOIN [gold].[dim_order_status] os ON f.[order_status_key] = os.[order_status_key] WHERE os.[order_status_key] IS NULL)
              OR EXISTS (SELECT 1 FROM [gold].[fact_payments] fp LEFT JOIN [gold].[dim_date] d ON fp.[date_key] = d.[date_key] WHERE d.[date_key] IS NULL)
              OR EXISTS (SELECT 1 FROM [gold].[fact_payments] fp LEFT JOIN [gold].[dim_customer] c ON fp.[customer_key] = c.[customer_key] WHERE c.[customer_key] IS NULL)
              OR EXISTS (SELECT 1 FROM [gold].[fact_payments] fp LEFT JOIN [gold].[dim_payment_type] pt ON fp.[payment_type_key] = pt.[payment_type_key] WHERE pt.[payment_type_key] IS NULL)
              OR EXISTS (SELECT 1 FROM [gold].[fact_reviews] fr LEFT JOIN [gold].[dim_date] d ON fr.[date_key] = d.[date_key] WHERE d.[date_key] IS NULL)
              OR EXISTS (SELECT 1 FROM [gold].[fact_reviews] fr LEFT JOIN [gold].[dim_customer] c ON fr.[customer_key] = c.[customer_key] WHERE c.[customer_key] IS NULL)
       THEN N'FAIL' ELSE N'PASS' END
UNION ALL
SELECT N'Test 7: SUM(fact_sales.price) = SUM(silver.order_items.price) (Gold)',
       CASE WHEN ABS(
           (SELECT ISNULL(SUM([price]), 0) FROM [gold].[fact_sales]) - 
           (SELECT ISNULL(SUM([price]), 0) FROM [silver].[order_items])
       ) > 0.01 THEN N'FAIL' ELSE N'PASS' END
UNION ALL
SELECT N'Test 8: SUM(fact_payments.payment_value) = SUM(silver.order_payments.payment_value) (Gold)',
       CASE WHEN ABS(
           (SELECT ISNULL(SUM([payment_value]), 0) FROM [gold].[fact_payments]) - 
           (SELECT ISNULL(SUM([payment_value]), 0) FROM [silver].[order_payments])
       ) > 0.01 THEN N'FAIL' ELSE N'PASS' END
UNION ALL
SELECT N'Test 9: Only one is_current = 1 row per customer_unique_id (Gold)',
       CASE WHEN EXISTS (
           SELECT 1 
           FROM [gold].[dim_customer] 
           WHERE [is_current] = 1 
             AND [customer_key] <> -1 
           GROUP BY [customer_unique_id] 
           HAVING COUNT(*) > 1
       ) THEN N'FAIL' ELSE N'PASS' END
UNION ALL
SELECT N'Test 10: No negative prices or freight values (Silver)',
       CASE WHEN EXISTS (
           SELECT 1 
           FROM [silver].[order_items] 
           WHERE [price] < 0 
              OR [freight_value] < 0
       ) THEN N'FAIL' ELSE N'PASS' END;
GO