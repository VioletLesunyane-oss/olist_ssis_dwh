DECLARE @batch_id INT = ?;

MERGE [gold].[dim_geography] AS target
USING [silver].[geolocation] AS source
ON target.[zip_code_prefix] = source.[geolocation_zip_code_prefix]
WHEN MATCHED AND (
    ISNULL(target.[city], N'') <> ISNULL(source.[geolocation_city], N'') OR
    ISNULL(target.[state], N'') <> ISNULL(source.[geolocation_state], N'')
) THEN
    UPDATE SET
        target.[latitude]     = source.[geolocation_lat],
        target.[longitude]    = source.[geolocation_lng],
        target.[city]         = source.[geolocation_city],
        target.[state]        = source.[geolocation_state],
        target.[dwh_load_ts]  = SYSDATETIME(),
        target.[dwh_batch_id] = @batch_id
WHEN NOT MATCHED BY TARGET THEN
    INSERT ([zip_code_prefix], [latitude], [longitude], [city], [state], [dwh_batch_id])
    VALUES (
        source.[geolocation_zip_code_prefix],
        source.[geolocation_lat],
        source.[geolocation_lng],
        source.[geolocation_city],
        source.[geolocation_state],
        @batch_id
    );

--Parameter Mapping

Variable Name	                    Direction	 Data Type	 Parameter Name	 Parameter Size
$Package::p_batch_id	            Input	     LONG	     0	             -1