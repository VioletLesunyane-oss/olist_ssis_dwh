-- ============================================================================
-- SCRIPT:  01_create_schemas.sql
-- PURPOSE: Initializes the four Medallion Architecture schemas (bronze, silver,
--          gold, and etl) inside [olist_dwh] using re-runnable IF NOT EXISTS
--          guards, and verifies that all four schemas exist.
-- ============================================================================
-- Everything below is created inside olist_dwh

USE olist_dwh;                       
GO

-- ============================================================================
-- 1. SCHEMA: bronze (Raw Landing Layer)
-- ============================================================================
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'bronze')
BEGIN
    EXEC (N'CREATE SCHEMA bronze');
END
GO                                   

-- ============================================================================
-- 2. SCHEMA: silver (Cleansed & Standardized Layer)
-- ============================================================================
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'silver')
BEGIN
    EXEC (N'CREATE SCHEMA silver');
END
GO                                   

-- ============================================================================
-- 3. SCHEMA: gold (Analytics Star Schema Layer)
-- ============================================================================
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'gold')
BEGIN
    EXEC (N'CREATE SCHEMA gold');
END
GO  

-- ============================================================================
-- 4. SCHEMA: etl (Audit Logging & Error Quarantine Layer)
-- ============================================================================
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'elt')
BEGIN
    EXEC (N'CREATE SCHEMA etl');
END
GO  

-- ============================================================================
-- VERIFICATION: Schemas Overview (Expects 4 Rows)
-- ============================================================================
SELECT name AS schema_name                     
FROM sys.schemas
WHERE name IN (N'bronze', N'silver', N'gold', N'etl');
GO

