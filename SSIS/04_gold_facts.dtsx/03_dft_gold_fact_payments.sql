-- DATA FLOW STRUCTURE
    -- 01. OLEDB Source
        -- 02. Look Up
            -- 03. Derived Column
                -- 04. Row Count
                    -- 05. OLE DB Destination

-- 01. FROM: silver_order_payments
SELECT 
    p.[order_id],
    p.[payment_sequential],
    CAST(o.[order_purchase_ts] AS DATE) AS [purchase_date],
    c.[customer_unique_id],
    p.[payment_type],
    p.[payment_installments],
    p.[payment_value]
FROM [silver].[order_payments] AS p
JOIN [silver].[orders] AS o ON p.[order_id] = o.[order_id]
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

-- 2.3 LKP_dim_payment_type

Tick: Full cache
Tick: OLEDB Connection manager
Specify how to handle rows with no matching entries: Ignore failure

Connection: [gold].[dim_payment_type]
columns: 
    Available_look_up_column: 
    - Tick: payment_type_key
    - Match: payment_type to payment_type



-- 03. gold_fact_sales_matadata


-- 04. gold_fact_sales_row_count
user::fact_payments_rows

-- 05. TO:  golf_fact_payments_destination
[gold].[fact_payments]