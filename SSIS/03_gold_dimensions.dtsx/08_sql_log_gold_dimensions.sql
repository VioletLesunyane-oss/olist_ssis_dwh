DECLARE @batch_id INT = ?;
DECLARE @pkg NVARCHAR(260) = ?;

INSERT INTO [etl].[load_log] ([batch_id], [package_name], [table_name], [rows_read], [rows_written], [rows_error])
SELECT @batch_id, @pkg, N'gold.dim_date', COUNT(*), COUNT(*), 0 FROM [gold].[dim_date] WHERE [date_key] <> -1
UNION ALL
SELECT @batch_id, @pkg, N'gold.dim_geography', COUNT(*), COUNT(*), 0 FROM [gold].[dim_geography] WHERE [geography_key] <> -1
UNION ALL
SELECT @batch_id, @pkg, N'gold.dim_customer', COUNT(*), COUNT(*), 0 FROM [gold].[dim_customer] WHERE [customer_key] <> -1
UNION ALL
SELECT @batch_id, @pkg, N'gold.dim_product', COUNT(*), COUNT(*), 0 FROM [gold].[dim_product] WHERE [product_key] <> -1
UNION ALL
SELECT @batch_id, @pkg, N'gold.dim_seller', COUNT(*), COUNT(*), 0 FROM [gold].[dim_seller] WHERE [seller_key] <> -1
UNION ALL
SELECT @batch_id, @pkg, N'gold.dim_order_status', COUNT(*), COUNT(*), 0 FROM [gold].[dim_order_status] WHERE [order_status_key] <> -1
UNION ALL
SELECT @batch_id, @pkg, N'gold.dim_payment_type', COUNT(*), COUNT(*), 0 FROM [gold].[dim_payment_type] WHERE [payment_type_key] <> -1;

--Parameter Mapping

Variable Name	                    Direction	 Data Type	 Parameter Name	 Parameter Size
$Package::p_batch_id	            Input	     LONG	     0	             -1
System::PackageName	                Input	     NVARCHAR	 1	             260