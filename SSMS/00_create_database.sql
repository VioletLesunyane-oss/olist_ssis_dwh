-- 00_create_database
IF NOT EXISTS (SELECT 1 FROM sys.databases    
               WHERE name = N'olist_dwh')     
BEGIN                                          
    CREATE DATABASE olist_dwh;                 
END;
GO
