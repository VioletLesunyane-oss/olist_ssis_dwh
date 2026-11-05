-- 01_create_schemas
-- Everything below is created inside olist_dwh

USE olist_dwh;                       
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'bronze')
BEGIN
    EXEC (N'CREATE SCHEMA bronze');
END
GO                                   

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'silver')
BEGIN
    EXEC (N'CREATE SCHEMA silver');
END
GO                                   

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'gold')
BEGIN
    EXEC (N'CREATE SCHEMA gold');
END
GO  

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'elt')
BEGIN
    EXEC (N'CREATE SCHEMA etl');
END
GO  
