-- ============================================================================
-- PROJECT: Olist E-Commerce Data Warehouse
-- SCRIPT:  00_create_database.sql
-- PURPOSE: Initializes the [olist_dwh] data warehouse database on the SQL
--          Server instance using a re-runnable IF NOT EXISTS guard.
-- ============================================================================

-- ============================================================================
-- 1. DATABASE INITIALIZATION: olist_dwh
-- ============================================================================
IF NOT EXISTS (SELECT 1 FROM sys.databases    
               WHERE name = N'olist_dwh')     
BEGIN                                          
    CREATE DATABASE olist_dwh;                 
END;
GO

