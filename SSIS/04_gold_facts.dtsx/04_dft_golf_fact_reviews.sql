-- DATA FLOW STRUCTURE
    -- 01. OLEDB Source
        -- 02. Look Up
            -- 03. Derived Column
                -- 04. Row Count
                    -- 05. OLE DB Destination

-- 01. FROM: silver_order_reviews
SELECT 
    r.[review_id],
    r.[order_id],
    CAST(r.[review_creation_date] AS DATE) AS [review_date],
    c.[customer_unique_id],
    r.[review_score],
    r.[review_creation_date],
    r.[review_answer_timestamp]
FROM [silver].[order_reviews] AS r
JOIN [silver].[orders] AS o ON r.[order_id] = o.[order_id]
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
    - Match: review_date to full_date

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


-- 03. gold_fact_sales_matadata


-- 04. gold_fact_sales_row_count
user::fact_review_rows

-- 05. TO:  golf_fact_payments_destination
[gold].[fact_reviews]