-- ============================================================================
-- PHASE 6: Business Analytics Queries (Gold Layer Star Schema)
-- ============================================================================


-- ============================================================================
-- Q1: Monthly Revenue & Order Volume Trends (2017–2018)
-- Tracks total items sold, distinct orders, product revenue, freight, and total revenue.
-- ============================================================================
SELECT 
    d.[calendar_year],
    d.[calendar_month],
    d.[year_month],
    COUNT(DISTINCT f.[order_id]) AS [total_orders],
    COUNT(*) AS [total_items_sold],
    SUM(f.[price]) AS [product_revenue],
    SUM(f.[freight_value]) AS [freight_revenue],
    SUM(f.[total_item_value]) AS [total_revenue]
FROM [gold].[fact_sales] AS f
JOIN [gold].[dim_date] AS d 
    ON f.[date_key] = d.[date_key]
WHERE d.[calendar_year] IN (2017, 2018)
  AND d.[date_key] <> -1
GROUP BY 
    d.[calendar_year], 
    d.[calendar_month], 
    d.[year_month]
ORDER BY 
    d.[calendar_year], 
    d.[calendar_month];
GO

-- ============================================================================
-- Q2: Top 10 Product Categories by Revenue & Order Volume (English Names)
-- Ranks categories by total sales value and shows average item price.
-- ============================================================================
SELECT TOP 10
    p.[product_category_name_english] AS [category_english],
    p.[product_category_name] AS [category_portuguese],
    COUNT(DISTINCT f.[order_id]) AS [total_orders],
    COUNT(*) AS [units_sold],
    SUM(f.[total_item_value]) AS [total_revenue],
    CAST(AVG(f.[price]) AS DECIMAL(10,2)) AS [avg_item_price]
FROM [gold].[fact_sales] AS f
JOIN [gold].[dim_product] AS p 
    ON f.[product_key] = p.[product_key]
WHERE p.[product_key] <> -1
GROUP BY 
    p.[product_category_name_english], 
    p.[product_category_name]
ORDER BY 
    [total_revenue] DESC;
GO

-- ============================================================================
-- Q3: Payment Method Breakdown (Share of Orders, Revenue & Installments)
-- Analyzes payment preferences, total spend, and average installment counts.
-- ============================================================================
SELECT 
    pt.[payment_type],
    COUNT(DISTINCT fp.[order_id]) AS [distinct_orders],
    COUNT(*) AS [payment_transactions],
    SUM(fp.[payment_value]) AS [total_payment_value],
    CAST(SUM(fp.[payment_value]) * 100.0 / SUM(SUM(fp.[payment_value])) OVER () AS DECIMAL(5,2)) AS [revenue_share_pct],
    CAST(AVG(CAST(fp.[payment_installments] AS DECIMAL(10,2))) AS DECIMAL(5,2)) AS [avg_installments]
FROM [gold].[fact_payments] AS fp
JOIN [gold].[dim_payment_type] AS pt 
    ON fp.[payment_type_key] = pt.[payment_type_key]
GROUP BY 
    pt.[payment_type]
ORDER BY 
    [total_payment_value] DESC;
GO

-- ============================================================================
-- Q4: Delivery Performance & Late Delivery Rate by Customer State
-- Filters strictly to delivered orders (is_delivered = 1) to evaluate logistics.
-- ============================================================================
WITH order_delivery AS (
    SELECT DISTINCT
        f.[order_id],
        c.[customer_state],
        f.[days_to_deliver],
        f.[delivery_delay_days],
        CAST(f.[is_late] AS INT) AS [is_late_int]
    FROM [gold].[fact_sales] AS f
    JOIN [gold].[dim_customer] AS c 
        ON f.[customer_key] = c.[customer_key]
    JOIN [gold].[dim_order_status] AS os 
        ON f.[order_status_key] = os.[order_status_key]
    WHERE os.[is_delivered] = 1
      AND c.[customer_key] <> -1
      AND f.[days_to_deliver] IS NOT NULL
)
SELECT 
    [customer_state],
    COUNT(*) AS [delivered_orders],
    CAST(AVG(CAST([days_to_deliver] AS DECIMAL(10,2))) AS DECIMAL(5,2)) AS [avg_days_to_deliver],
    CAST(AVG(CAST([delivery_delay_days] AS DECIMAL(10,2))) AS DECIMAL(5,2)) AS [avg_delay_vs_estimate_days],
    SUM([is_late_int]) AS [late_orders],
    CAST(SUM([is_late_int]) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS [late_delivery_rate_pct]
FROM order_delivery
GROUP BY 
    [customer_state]
ORDER BY 
    [delivered_orders] DESC;
GO

-- ============================================================================
-- Q5: Top 10 States by Customer Spend & Average Order Value (AOV)
-- Compares regional purchasing power across Brazilian states.
-- ============================================================================
SELECT TOP 10
    c.[customer_state],
    COUNT(DISTINCT c.[customer_unique_id]) AS [unique_customers],
    COUNT(DISTINCT f.[order_id]) AS [total_orders],
    SUM(f.[total_item_value]) AS [total_spend],
    CAST(SUM(f.[total_item_value]) / NULLIF(COUNT(DISTINCT f.[order_id]), 0) AS DECIMAL(10,2)) AS [avg_order_value]
FROM [gold].[fact_sales] AS f
JOIN [gold].[dim_customer] AS c 
    ON f.[customer_key] = c.[customer_key]
WHERE c.[customer_key] <> -1
GROUP BY 
    c.[customer_state]
ORDER BY 
    [total_spend] DESC;
GO

-- ============================================================================
-- Q6: Top 10 Sellers by Revenue & Customer Review Satisfaction
-- Joins sales volume with average review scores per seller (minimum 20 orders).
-- ============================================================================
WITH seller_sales AS (
    SELECT 
        s.[seller_key],
        s.[seller_id],
        s.[seller_city],
        s.[seller_state],
        COUNT(DISTINCT f.[order_id]) AS [total_orders],
        COUNT(*) AS [items_sold],
        SUM(f.[total_item_value]) AS [total_revenue]
    FROM [gold].[fact_sales] AS f
    JOIN [gold].[dim_seller] AS s 
        ON f.[seller_key] = s.[seller_key]
    WHERE s.[seller_key] <> -1
    GROUP BY 
        s.[seller_key], s.[seller_id], s.[seller_city], s.[seller_state]
),
seller_reviews AS (
    SELECT DISTINCT
        f.[seller_key],
        r.[review_id],
        CAST(r.[review_score] AS DECIMAL(5,2)) AS [review_score]
    FROM [gold].[fact_sales] AS f
    JOIN [gold].[fact_reviews] AS r 
        ON f.[order_id] = r.[order_id]
)
SELECT TOP 10
    ss.[seller_id],
    ss.[seller_city],
    ss.[seller_state],
    ss.[total_orders],
    ss.[items_sold],
    ss.[total_revenue],
    CAST(AVG(sr.[review_score]) AS DECIMAL(3,2)) AS [avg_review_score]
FROM seller_sales AS ss
LEFT JOIN seller_reviews AS sr 
    ON ss.[seller_key] = sr.[seller_key]
WHERE ss.[total_orders] >= 20
GROUP BY 
    ss.[seller_id], ss.[seller_city], ss.[seller_state],
    ss.[total_orders], ss.[items_sold], ss.[total_revenue]
ORDER BY 
    ss.[total_revenue] DESC;
GO

-- ============================================================================
-- Q7: Customer Retention & Repeat Purchase Rate (Using customer_unique_id)
-- Measures single-order vs. repeat customers across the platform.
-- ============================================================================
WITH customer_orders AS (
    SELECT 
        c.[customer_unique_id],
        COUNT(DISTINCT f.[order_id]) AS [order_count],
        SUM(f.[total_item_value]) AS [lifetime_spend]
    FROM [gold].[fact_sales] AS f
    JOIN [gold].[dim_customer] AS c 
        ON f.[customer_key] = c.[customer_key]
    WHERE c.[customer_key] <> -1
    GROUP BY 
        c.[customer_unique_id]
)
SELECT 
    COUNT(*) AS [total_unique_customers],
    SUM(CASE WHEN [order_count] = 1 THEN 1 ELSE 0 END) AS [one_time_customers],
    SUM(CASE WHEN [order_count] > 1 THEN 1 ELSE 0 END) AS [repeat_customers],
    CAST(SUM(CASE WHEN [order_count] > 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS [repeat_customer_rate_pct],
    CAST(AVG([lifetime_spend]) AS DECIMAL(10,2)) AS [avg_customer_lifetime_value]
FROM customer_orders;
GO

-- ============================================================================
-- Q8: Impact of Late Deliveries on Customer Review Scores
-- Compares average review scores and 1-star rates for On-Time vs. Late orders.
-- ============================================================================
WITH order_timeliness AS (
    SELECT DISTINCT
        f.[order_id],
        f.[is_late]
    FROM [gold].[fact_sales] AS f
    JOIN [gold].[dim_order_status] AS os 
        ON f.[order_status_key] = os.[order_status_key]
    WHERE os.[is_delivered] = 1
      AND f.[is_late] IS NOT NULL
)
SELECT 
    CASE WHEN ot.[is_late] = 1 THEN N'Late Delivery' ELSE N'On-Time Delivery' END AS [delivery_status],
    COUNT(DISTINCT r.[review_id]) AS [total_reviews],
    CAST(AVG(CAST(r.[review_score] AS DECIMAL(5,2))) AS DECIMAL(3,2)) AS [avg_review_score],
    SUM(CASE WHEN r.[review_score] = 1 THEN 1 ELSE 0 END) AS [one_star_reviews],
    CAST(SUM(CASE WHEN r.[review_score] = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS [one_star_rate_pct]
FROM order_timeliness AS ot
JOIN [gold].[fact_reviews] AS r 
    ON ot.[order_id] = r.[order_id]
GROUP BY 
    ot.[is_late]
ORDER BY 
    ot.[is_late];
GO
