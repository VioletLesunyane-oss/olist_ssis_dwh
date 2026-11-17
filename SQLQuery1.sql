SELECT 
    s.[name] AS schema_name,
    t.[name] AS table_name,
    COUNT(c.[column_id]) AS total_columns,
    SUM(p.[rows]) AS current_row_count,
    CASE 
        WHEN t.[name] IN (
            'dim_date', 'dim_geography', 'dim_customer', 'dim_product',
            'dim_seller', 'dim_order_status', 'dim_payment_type',
            'fact_sales', 'fact_payments', 'fact_reviews'
        ) THEN N'✅ EXPECTED TABLE'
        ELSE N'⚠️ EXTRA TABLE'
    END AS validation_status
FROM [sys].[tables] AS t
JOIN [sys].[schemas] AS s ON s.[schema_id] = t.[schema_id]
JOIN [sys].[columns] AS c ON c.[object_id] = t.[object_id]
JOIN [sys].[partitions] AS p ON p.[object_id] = t.[object_id] AND p.[index_id] IN (0, 1)
WHERE s.[name] = N'gold'
GROUP BY s.[name], t.[name]
ORDER BY t.[name];
GO