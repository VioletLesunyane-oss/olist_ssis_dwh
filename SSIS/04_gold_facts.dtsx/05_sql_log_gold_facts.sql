DECLARE @batch_id INT = ?;
DECLARE @pkg NVARCHAR(260) = ?;
DECLARE @sales_rows BIGINT = ?;
DECLARE @pay_rows BIGINT = ?;
DECLARE @rev_rows BIGINT = ?;

INSERT INTO [etl].[load_log] ([batch_id], [package_name], [table_name], [rows_read], [rows_written], [rows_error])
VALUES
    (@batch_id, @pkg, N'gold.fact_sales', @sales_rows, @sales_rows, 0),
    (@batch_id, @pkg, N'gold.fact_payments', @pay_rows, @pay_rows, 0),
    (@batch_id, @pkg, N'gold.fact_reviews', @rev_rows, @rev_rows, 0);

--Parameter Mapping
--NOTE: All sql tables use same parameter mappings, but variables change for each table
Variable Name	                    Direction	 Data Type	 Parameter Name	 Parameter Size
$Package::p_batch_id	            Input	     LONG	     0	             -1
System::PackageName	                Input	     NVARCHAR	 1	             260
User::fact_sales_rows	            Input	     NUMERIC	 2	             -1
User::fact_payments_rows	        Input	     NUMERIC	 3	             -1
user::fact_review_rows              Input	     NUMERIC	 4	             -1