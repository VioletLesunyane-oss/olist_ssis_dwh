DECLARE @batch_id INT = ?;

MERGE [gold].[dim_order_status] AS target
USING (
    SELECT DISTINCT [order_status], [is_delivered]
    FROM [silver].[orders]
    WHERE [order_status] IS NOT NULL
) AS source
ON target.[order_status] = source.[order_status]
WHEN NOT MATCHED BY TARGET THEN
    INSERT ([order_status], [is_delivered], [dwh_batch_id])
    VALUES (source.[order_status], source.[is_delivered], @batch_id);

--Parameter Mapping

Variable Name	                    Direction	 Data Type	 Parameter Name	 Parameter Size
$Package::p_batch_id	            Input	     LONG	     0	             -1