DECLARE @batch_id INT = ?;

MERGE [gold].[dim_payment_type] AS target
USING (
    SELECT DISTINCT [payment_type]
    FROM [silver].[order_payments]
    WHERE [payment_type] IS NOT NULL
) AS source
ON target.[payment_type] = source.[payment_type]
WHEN NOT MATCHED BY TARGET THEN
    INSERT ([payment_type], [dwh_batch_id])
    VALUES (source.[payment_type], @batch_id);

--Parameter Mapping

Variable Name	                    Direction	 Data Type	 Parameter Name	 Parameter Size
$Package::p_batch_id	            Input	     LONG	     0	             -1


