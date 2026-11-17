DECLARE @batch_id INT = ?;

-- Build ordered timeline of customer location changes from orders
WITH customer_timeline AS (
    SELECT 
        c.[customer_unique_id],
        ISNULL(g.[geography_key], -1) AS [geography_key],
        c.[customer_city],
        c.[customer_state],
        MIN(ISNULL(o.[order_purchase_ts], '2016-01-01')) AS [valid_from]
    FROM [silver].[customers] AS c
    LEFT JOIN [silver].[orders] AS o 
        ON c.[customer_id] = o.[customer_id]
    LEFT JOIN [gold].[dim_geography] AS g 
        ON c.[customer_zip_code_prefix] = g.[zip_code_prefix]
    GROUP BY 
        c.[customer_unique_id],
        ISNULL(g.[geography_key], -1),
        c.[customer_city],
        c.[customer_state]
),
versioned_customers AS (
    SELECT 
        [customer_unique_id],
        [geography_key],
        [customer_city],
        [customer_state],
        [valid_from],
        ISNULL(
            LEAD([valid_from]) OVER (PARTITION BY [customer_unique_id] ORDER BY [valid_from]),
            '9999-12-31'
        ) AS [valid_to],
        CASE 
            WHEN LEAD([valid_from]) OVER (PARTITION BY [customer_unique_id] ORDER BY [valid_from]) IS NULL THEN 1 
            ELSE 0 
        END AS [is_current]
    FROM customer_timeline
)
-- Expire old open versions if a newer version arrived
UPDATE tgt
SET 
    tgt.[valid_to]     = src.[valid_to],
    tgt.[is_current]   = 0,
    tgt.[dwh_load_ts]  = SYSDATETIME(),
    tgt.[dwh_batch_id] = @batch_id
FROM [gold].[dim_customer] AS tgt
JOIN versioned_customers AS src
    ON tgt.[customer_unique_id] = src.[customer_unique_id]
    AND tgt.[valid_from] = src.[valid_from]
WHERE tgt.[is_current] = 1 AND src.[is_current] = 0;

-- Insert only versions that do not already exist (re-run safe)
WITH customer_timeline AS (
    SELECT 
        c.[customer_unique_id],
        ISNULL(g.[geography_key], -1) AS [geography_key],
        c.[customer_city],
        c.[customer_state],
        MIN(ISNULL(o.[order_purchase_ts], '2016-01-01')) AS [valid_from]
    FROM [silver].[customers] AS c
    LEFT JOIN [silver].[orders] AS o 
        ON c.[customer_id] = o.[customer_id]
    LEFT JOIN [gold].[dim_geography] AS g 
        ON c.[customer_zip_code_prefix] = g.[zip_code_prefix]
    GROUP BY 
        c.[customer_unique_id],
        ISNULL(g.[geography_key], -1),
        c.[customer_city],
        c.[customer_state]
),
versioned_customers AS (
    SELECT 
        [customer_unique_id],
        [geography_key],
        [customer_city],
        [customer_state],
        [valid_from],
        ISNULL(
            LEAD([valid_from]) OVER (PARTITION BY [customer_unique_id] ORDER BY [valid_from]),
            '9999-12-31'
        ) AS [valid_to],
        CASE 
            WHEN LEAD([valid_from]) OVER (PARTITION BY [customer_unique_id] ORDER BY [valid_from]) IS NULL THEN 1 
            ELSE 0 
        END AS [is_current]
    FROM customer_timeline
)
INSERT INTO [gold].[dim_customer] (
    [customer_unique_id], [geography_key], [customer_city], [customer_state],
    [valid_from], [valid_to], [is_current], [dwh_batch_id]
)
SELECT 
    src.[customer_unique_id], src.[geography_key], src.[customer_city], src.[customer_state],
    src.[valid_from], src.[valid_to], src.[is_current], @batch_id
FROM versioned_customers AS src
WHERE NOT EXISTS (
    SELECT 1 
    FROM [gold].[dim_customer] AS tgt
    WHERE tgt.[customer_unique_id] = src.[customer_unique_id]
      AND tgt.[valid_from] = src.[valid_from]
);

--Parameter Mapping

Variable Name	                    Direction	 Data Type	 Parameter Name	 Parameter Size
$Package::p_batch_id	            Input	     LONG	     0	             -1