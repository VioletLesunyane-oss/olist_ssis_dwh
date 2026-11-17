-- DATA FLOW STRUCTURE
    -- 01. OLEDB Source
        -- 02. Look Up
            -- 03. Derived Column
                -- 04. Row Count
                    -- 05. OLE DB Destination

-- 01. FROM: silver_order_items
SELECT 
    oi.[order_id],
    oi.[order_item_id],
    CAST(o.[order_purchase_ts] AS DATE) AS [purchase_date],
    c.[customer_unique_id],
    oi.[product_id],
    oi.[seller_id],
    o.[order_status],
    oi.[price],
    oi.[freight_value],
    oi.[total_item_value],
    o.[order_purchase_ts],
    o.[order_delivered_customer_date],
    o.[order_estimated_delivery_date],
    CASE 
        WHEN o.[is_delivered] = 1 AND o.[order_delivered_customer_date] IS NOT NULL 
        THEN DATEDIFF(DAY, o.[order_purchase_ts], o.[order_delivered_customer_date])
        ELSE NULL 
    END AS [days_to_deliver],
    CASE 
        WHEN o.[is_delivered] = 1 AND o.[order_delivered_customer_date] IS NOT NULL 
        THEN DATEDIFF(DAY, o.[order_estimated_delivery_date], o.[order_delivered_customer_date])
        ELSE NULL 
    END AS [delivery_delay_days],
    CASE 
        WHEN o.[is_delivered] = 1 AND o.[order_delivered_customer_date] IS NOT NULL 
        THEN CAST(CASE WHEN o.[order_delivered_customer_date] > o.[order_estimated_delivery_date] THEN 1 ELSE 0 END AS BIT)
        ELSE NULL 
    END AS [is_late]
FROM [silver].[order_items] AS oi
JOIN [silver].[orders] AS o ON oi.[order_id] = o.[order_id]
LEFT JOIN [silver].[customers] AS c ON o.[customer_id] = c.[customer_id];

-- 02. Look Up
-- 2.1. LKP_dim_date
Tick: Full cache
Tick: OLEDB Connection manager
Specify how to handle rows with no matching entries: Ignore failure

Connection: [gold].[dim_date]
columns: 
    Available_look_up_column: 
    - Tick: date_key
    - Match: customer_unique_id to full_date

-- 2.2 LKP_dim_customers
Tick: Full cache
Tick: OLEDB Connection manager
Specify how to handle rows with no matching entries: Ignore failure

Connection: 
    SQL command: SELECT customer_key, customer_unique_id FROM [gold].[dim_customer] WHERE is_current = 1
columns: 
    Available_look_up_column: 
    - Tick: customer_key
    - Match: customer_unique_id to customer_unique_id

-- 2.3 LKP_dim_products

Tick: Full cache
Tick: OLEDB Connection manager
Specify how to handle rows with no matching entries: Ignore failure

Connection: [gold].[dim_product]
columns: 
    Available_look_up_column: 
    - Tick: product_key
    - Match: product_id to product_id

-- 2.4 LKP_dim_sellers
Tick: Full cache
Tick: OLEDB Connection manager
Specify how to handle rows with no matching entries: Ignore failure

Connection: [gold].[dim_seller]
columns: 
    Available_look_up_column: 
    - Tick: seller_key
    - Match: seller_id to seller_id

-- 2.5 LKP_dim_order_status
Tick: Full cache
Tick: OLEDB Connection manager
Specify how to handle rows with no matching entries: Ignore failure

Connection: [gold].[dim_order_status]
columns: 
    Available_look_up_column: 
    - Tick: order_status_key
    - Match: order_status to order_status

-- 03. gold_fact_sales_matadata


-- 04. gold_fact_sales_row_count
user::fact_sales_rows

-- 05. TO:  golf_fact_sales_destination
[gold].[fact_sales]