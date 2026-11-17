-- DATA FLOW STRCTURE FOR ALL 9 TABLES
-- 01. Flat_file
    -- 02. Row_count (read_rows)
        -- 03. Derived_columns(metadata)
            -- 04. Row_count (rows_written)
                -- 05. OLE_DB_Destination
Note: Each table has its own Data Flow and Sql log
-- 01. Flat_files 
olist_customers
olist_orders
olist_order_items
olist_order_payments
olist_order_reviews
olist_products
olist_sellers
olist_geolocation
olist_product_category_name_translation

-- 02. Row_count (read_rows) for each table
user::cust_rows_read
user::ord_rows_read
user::items_rows_read
user::pay_rows_read
user::rev_rows_read
user::prod_rows_read
user::sell_rows_read
user::geo_rows_read
user::trans_rows_read

-- 03. Derived_columns(metadata) it is inserted in each tables's data flow
Derived_columns_name   Derived_column           Expression
dwh_source_file        <add as new column>      "copy url of where the datasets are saves in my local machine and paste"
dwh_batch_id           <add as new column>      @[$Package::p_batch_id]

-- 04. Row_count (rows_written)
user::cust_rows_written
user::ord_rows_witten
user::items_rows_witten
user::pay_rows_witten
user::rev_rows_witten
user::prod_rows_witten
user::sell_rows_witten
user::geo_rows_witten
user::trans_rows_witten

-- 05. OLE_DB_Destination
[bronze].[olist_customers]
[bronze].[olist_orders]
[bronze].[olist_order_items]
[bronze].[olist_order_payments]
[bronze].[olist_order_reviews]
[bronze].[olist_products]
[bronze].[olist_sellers]
[bronze].[olist_geolocation]
[bronze].[olist_product_category_name_translation]
