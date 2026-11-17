--1 SCHEMA: bronze (raw data)
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'bronze')
BEGIN
    EXEC (N'CREATE SCHEMA bronze');
END
GO                                   

-- 2. SCHEMA: silver (Cleansed & Standardized Layer)

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'silver')
BEGIN
    EXEC (N'CREATE SCHEMA silver');
END
GO                                   


-- 3. SCHEMA: gold (Analytics Star Schema Layer)

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