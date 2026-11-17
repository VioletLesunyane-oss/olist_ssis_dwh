INSERT INTO etl.load_log (batch_id, package_name, table_name, rows_read, rows_written, rows_error)
VALUES (?, ?, 'bronze.olist_customers', ?, ?, 0);

INSERT INTO etl.load_log (batch_id, package_name, table_name, rows_read, rows_written, rows_error)
VALUES (?, ?, 'bronze.olist_orders', ?, ?, 0);

INSERT INTO etl.load_log (batch_id, package_name, table_name, rows_read, rows_written, rows_error)
VALUES (?, ?, 'bronze.olist_order_items', ?, ?, 0);

INSERT INTO etl.load_log (batch_id, package_name, table_name, rows_read, rows_written, rows_error)
VALUES (?, ?, 'bronze.olist_order_payments', ?, ?, 0);

INSERT INTO etl.load_log (batch_id, package_name, table_name, rows_read, rows_written, rows_error)
VALUES (?, ?, 'bronze.olist_order_reviews', ?, ?, 0);

INSERT INTO etl.load_log (batch_id, package_name, table_name, rows_read, rows_written, rows_error)
VALUES (?, ?, 'bronze.olist_products', ?, ?, 0);

INSERT INTO etl.load_log (batch_id, package_name, table_name, rows_read, rows_written, rows_error)
VALUES (?, ?, 'bronze.olist_sellers', ?, ?, 0);

INSERT INTO etl.load_log (batch_id, package_name, table_name, rows_read, rows_written, rows_error)
VALUES (?, ?, 'bronze.olist_geolocation', ?, ?, 0);

INSERT INTO etl.load_log (batch_id, package_name, table_name, rows_read, rows_written, rows_error)
VALUES (?, ?, 'bronze.olist_product_category_name_translation', ?, ?, 0);

--Parameter Mapping
--NOTE: All sql tables use same parameter mappings, but variables change for each table
Variable Name	                    Direction	 Data Type	 Parameter Name	 Parameter Size
$Package::p_batch_id	            Input	     LONG	     0	             -1
System::PackageName	                Input	     NVARCHAR	 1	             260
User::cust_rows_written	            Input	     NUMERIC	 2	             -1
User::cust_rows_written	            Input	     NUMERIC	 3	             -1

Note: Parameters for each table
user::ord_rows_witten
user::items_rows_witten
user::pay_rows_witten
user::rev_rows_witten
user::prod_rows_witten
user::sell_rows_witten
user::geo_rows_witten
user::trans_rows_witten