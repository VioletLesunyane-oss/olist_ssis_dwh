DECLARE @batch_id INT = ?;

MERGE [gold].[dim_product] AS target
USING [silver].[products] AS source
ON target.[product_id] = source.[product_id]
WHEN MATCHED AND (
    target.[product_category_name] <> source.[product_category_name] OR
    target.[product_category_name_english] <> source.[product_category_name_english]
) THEN
    UPDATE SET
        target.[product_category_name]         = source.[product_category_name],
        target.[product_category_name_english] = source.[product_category_name_english],
        target.[product_name_length]           = source.[product_name_length],
        target.[product_description_length]    = source.[product_description_length],
        target.[product_photos_qty]            = source.[product_photos_qty],
        target.[product_weight_g]              = source.[product_weight_g],
        target.[product_length_cm]             = source.[product_length_cm],
        target.[product_height_cm]             = source.[product_height_cm],
        target.[product_width_cm]              = source.[product_width_cm],
        target.[dwh_load_ts]                   = SYSDATETIME(),
        target.[dwh_batch_id]                  = @batch_id
WHEN NOT MATCHED BY TARGET THEN
    INSERT (
        [product_id], [product_category_name], [product_category_name_english],
        [product_name_length], [product_description_length], [product_photos_qty],
        [product_weight_g], [product_length_cm], [product_height_cm], [product_width_cm],
        [dwh_batch_id]
    )
    VALUES (
        source.[product_id], source.[product_category_name], source.[product_category_name_english],
        source.[product_name_length], source.[product_description_length], source.[product_photos_qty],
        source.[product_weight_g], source.[product_length_cm], source.[product_height_cm], source.[product_width_cm],
        @batch_id
    );

--Parameter Mapping

Variable Name	                    Direction	 Data Type	 Parameter Name	 Parameter Size
$Package::p_batch_id	            Input	     LONG	     0	             -1