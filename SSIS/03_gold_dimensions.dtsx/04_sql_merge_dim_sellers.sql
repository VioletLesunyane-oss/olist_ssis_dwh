DECLARE @batch_id INT = ?;

MERGE [gold].[dim_seller] AS target
USING (
    SELECT 
        s.[seller_id],
        ISNULL(g.[geography_key], -1) AS [geography_key],
        s.[seller_city],
        s.[seller_state]
    FROM [silver].[sellers] AS s
    LEFT JOIN [gold].[dim_geography] AS g
        ON s.[seller_zip_code_prefix] = g.[zip_code_prefix]
) AS source
ON target.[seller_id] = source.[seller_id]
WHEN MATCHED AND (
    target.[geography_key] <> source.[geography_key] OR
    ISNULL(target.[seller_city], N'') <> ISNULL(source.[seller_city], N'') OR
    ISNULL(target.[seller_state], N'') <> ISNULL(source.[seller_state], N'')
) THEN
    UPDATE SET
        target.[geography_key] = source.[geography_key],
        target.[seller_city]   = source.[seller_city],
        target.[seller_state]  = source.[seller_state],
        target.[dwh_load_ts]   = SYSDATETIME(),
        target.[dwh_batch_id]  = @batch_id
WHEN NOT MATCHED BY TARGET THEN
    INSERT ([seller_id], [geography_key], [seller_city], [seller_state], [dwh_batch_id])
    VALUES (source.[seller_id], source.[geography_key], source.[seller_city], source.[seller_state], @batch_id);

--Parameter Mapping

Variable Name	                    Direction	 Data Type	 Parameter Name	 Parameter Size
$Package::p_batch_id	            Input	     LONG	     0	             -1