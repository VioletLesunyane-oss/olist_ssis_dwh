USE [olist_dwh];
GO

-- 1. dim_date (-1 Unknown)
SET IDENTITY_INSERT [gold].[dim_date] ON;
IF NOT EXISTS (SELECT 1 FROM [gold].[dim_date] WHERE [date_key] = -1)
BEGIN
    INSERT INTO [gold].[dim_date] ([date_key], [full_date], [calendar_year], [calendar_quarter], [calendar_month], [month_name], [year_month], [day_of_month], [day_of_week], [day_name], [is_weekend], [dwh_batch_id])
    VALUES (-1, '1900-01-01', 1900, 1, 1, N'Unknown', N'1900-01', 1, 1, N'Unknown', 0, -1);
END
SET IDENTITY_INSERT [gold].[dim_date] OFF;
GO

-- 2. dim_geography (-1 Unknown — MUST run before dim_customer & dim_seller)
SET IDENTITY_INSERT [gold].[dim_geography] ON;
IF NOT EXISTS (SELECT 1 FROM [gold].[dim_geography] WHERE [geography_key] = -1)
BEGIN
    INSERT INTO [gold].[dim_geography] ([geography_key], [zip_code_prefix], [latitude], [longitude], [city], [state], [dwh_batch_id])
    VALUES (-1, N'Unknown', NULL, NULL, N'Unknown', N'Unknown', -1);
END
SET IDENTITY_INSERT [gold].[dim_geography] OFF;
GO

-- 3. dim_customer (-1 Unknown)
SET IDENTITY_INSERT [gold].[dim_customer] ON;
IF NOT EXISTS (SELECT 1 FROM [gold].[dim_customer] WHERE [customer_key] = -1)
BEGIN
    INSERT INTO [gold].[dim_customer] ([customer_key], [customer_unique_id], [geography_key], [customer_city], [customer_state], [valid_from], [valid_to], [is_current], [dwh_batch_id])
    VALUES (-1, N'Unknown', -1, N'Unknown', N'Unknown', '1900-01-01', '9999-12-31', 1, -1);
END
SET IDENTITY_INSERT [gold].[dim_customer] OFF;
GO

-- 4. dim_product (-1 Unknown)
SET IDENTITY_INSERT [gold].[dim_product] ON;
IF NOT EXISTS (SELECT 1 FROM [gold].[dim_product] WHERE [product_key] = -1)
BEGIN
    INSERT INTO [gold].[dim_product] ([product_key], [product_id], [product_category_name], [product_category_name_english], [dwh_batch_id])
    VALUES (-1, N'Unknown', N'Unknown', N'Unknown', -1);
END
SET IDENTITY_INSERT [gold].[dim_product] OFF;
GO

-- 5. dim_seller (-1 Unknown)
SET IDENTITY_INSERT [gold].[dim_seller] ON;
IF NOT EXISTS (SELECT 1 FROM [gold].[dim_seller] WHERE [seller_key] = -1)
BEGIN
    INSERT INTO [gold].[dim_seller] ([seller_key], [seller_id], [geography_key], [seller_city], [seller_state], [dwh_batch_id])
    VALUES (-1, N'Unknown', -1, N'Unknown', N'Unknown', -1);
END
SET IDENTITY_INSERT [gold].[dim_seller] OFF;
GO

-- 6. dim_order_status (-1 Unknown)
SET IDENTITY_INSERT [gold].[dim_order_status] ON;
IF NOT EXISTS (SELECT 1 FROM [gold].[dim_order_status] WHERE [order_status_key] = -1)
BEGIN
    INSERT INTO [gold].[dim_order_status] ([order_status_key], [order_status], [is_delivered], [dwh_batch_id])
    VALUES (-1, N'Unknown', 0, -1);
END
SET IDENTITY_INSERT [gold].[dim_order_status] OFF;
GO

-- 7. dim_payment_type (-1 Unknown)
SET IDENTITY_INSERT [gold].[dim_payment_type] ON;
IF NOT EXISTS (SELECT 1 FROM [gold].[dim_payment_type] WHERE [payment_type_key] = -1)
BEGIN
    INSERT INTO [gold].[dim_payment_type] ([payment_type_key], [payment_type], [dwh_batch_id])
    VALUES (-1, N'Unknown', -1);
END
SET IDENTITY_INSERT [gold].[dim_payment_type] OFF;
GO
