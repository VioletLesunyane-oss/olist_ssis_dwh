--01. silver_customers
INSERT INTO etl.load_log (batch_id, package_name, table_name, rows_read, rows_written, rows_error)
VALUES (?, ?, 'silver.customers', ?, ?, 0);

--02. silver_orders
INSERT INTO etl.load_log (batch_id, package_name, table_name, rows_read, rows_written, rows_error)
VALUES (?, ?, 'silver.orders', ?, ?, 0);

--03. silver.order_items
INSERT INTO etl.load_log (batch_id, package_name, table_name, rows_read, rows_written, rows_error)
VALUES (?, ?, 'silver.order_items', ?, ?, 0);

--04. silver.order_payments
INSERT INTO etl.load_log (batch_id, package_name, table_name, rows_read, rows_written, rows_error)
VALUES (?, ?, 'silver.order_payments', ?, ?, 0);

--05. silver.order_reviews
INSERT INTO etl.load_log (batch_id, package_name, table_name, rows_read, rows_written, rows_error)
VALUES (?, ?, 'silver.order_reviews', ?, ?, 0);

--06. silver.products
INSERT INTO etl.load_log (batch_id, package_name, table_name, rows_read, rows_written, rows_error)
VALUES (?, ?, 'silver.products', ?, ?, 0);

--07. silver.sellers
INSERT INTO etl.load_log (batch_id, package_name, table_name, rows_read, rows_written, rows_error)
VALUES (?, ?, 'silver.sellers', ?, ?, 0);

--08. silver.geolocation
INSERT INTO etl.load_log (batch_id, package_name, table_name, rows_read, rows_written, rows_error)
VALUES (?, ?, 'silver.geolocation', ?, ?, 0);

--09. silver_category_translation
INSERT INTO etl.load_log (batch_id, package_name, table_name, rows_read, rows_written, rows_error)
VALUES (?, ?, 'silver.category_translation', ?, ?, 0);

--Parameter Mapping
--NOTE: All sql tables use same parameter mappings, but variables change for each table
Variable Name	Direction	            Data   Type	 Parameter Name	 Parameter Size
$Package::p_batch_id	              Input	 LONG	     0	             -1
System::PackageName	                Input	 NVARCHAR	 1	             260
User::silver_cust_rows_written	    Input	 NUMERIC	 2	             -1
User::silver_cust_rows_written	    Input	 NUMERIC	 3	             -1
