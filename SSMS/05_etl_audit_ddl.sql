USE [olist_dwh];
GO

-- ============================================================================
-- 1. TABLE: etl.batch_log
-- PURPOSE: Tracks the macro execution state of the single master orchestration 
--          package (00_master.dtsx). Each run generates a unique batch_id.
-- ============================================================================

IF NOT EXISTS (SELECT 1
               FROM [olist_dwh].[sys].[tables]  AS t
               JOIN [olist_dwh].[sys].[schemas] AS s ON s.[schema_id] = t.[schema_id]
               WHERE s.[name] = N'etl' AND t.[name] = N'batch_log')
BEGIN
    CREATE TABLE [olist_dwh].[etl].[batch_log]
    (
        [batch_id] INT IDENTITY(1,1) NOT NULL CONSTRAINT pk_etl_batch_log PRIMARY KEY,  -- generates new id per run
        [start_ts] DATETIME2    NOT NULL CONSTRAINT [df_batch_log_start_ts] DEFAULT SYSDATETIME(), -- run start
        [end_ts]   DATETIME2    NULL,                                                              -- filled when the run ends
        [status]   NVARCHAR(20) NOT NULL CONSTRAINT [df_etl_batch_log_status]   DEFAULT N'RUNNING',    -- running / succeeded / failed
        CONSTRAINT [ck_etl_batch_log_status] CHECK ([status] IN (N'RUNNING', N'SUCCEEDED', N'FAILED'))
    );
END
GO

-- ================================================================================
-- 2. TABLE: etl.load_log
-- PURPOSE: Reconciles row counts per individual file/table across execution steps.
--          Captures data lineage metrics (rows read, written, and errored).
-- ================================================================================
IF NOT EXISTS (SELECT 1
               FROM [olist_dwh].[sys].[tables]  AS t
               JOIN [olist_dwh].[sys].[schemas] AS s ON s.[schema_id] = t.[schema_id]
               WHERE s.[name] = N'etl' AND t.[name] = N'load_log')
BEGIN
    CREATE TABLE [olist_dwh].[etl].[load_log]
    (
        [load_log_id]  INT IDENTITY(1,1) CONSTRAINT pk_etl_load_log PRIMARY KEY,
        [batch_id]     INT           NOT NULL,                                                   -- run that did the load
        [package_name] NVARCHAR(260) NOT NULL,                                                   -- e.g. 01_bronze_load.dtsx
        [table_name]   NVARCHAR(200) NOT NULL,                                                   -- e.g. bronze.olist_orders
        [rows_read]    INT           NULL,                                                       -- rows read from the source
        [rows_written] INT           NULL,                                                       -- rows inserted into the target
        [rows_error]   INT           NULL,                                                       -- rows sent to etl.error_rows
        [load_ts]      DATETIME2     NOT NULL CONSTRAINT [df_load_log_ts] DEFAULT SYSDATETIME()  -- when logged
    );
END
GO

-- ===============================================================================
-- 3. TABLE: etl.error_rows
-- PURPOSE: Captures rejected, failed-to-cast, or structurally broken data rows
--          during pipelines (Phase 2/Silver layer splits). Prevents silent drops.
-- ===============================================================================
IF NOT EXISTS (SELECT 1
               FROM [olist_dwh].[sys].[tables]  AS t
               JOIN [olist_dwh].[sys].[schemas] AS s ON s.[schema_id] = t.[schema_id]
               WHERE s.[name] = N'etl' AND t.[name] = N'error_rows')
BEGIN
    CREATE TABLE [olist_dwh].[etl].[error_rows]
    (
        [error_row_id] INT IDENTITY(1,1) CONSTRAINT pk_etl_error_rows PRIMARY KEY,
        [batch_id]     INT            NOT NULL,   -- run that rejected the row
        [table_name]   NVARCHAR(200)  NOT NULL,   -- target table, e.g. silver.orders
        [error_code]   INT            NULL,       -- SSIS ErrorCode
        [error_column] NVARCHAR(200)  NULL,       -- column (or SSIS column id) that failed
        [raw_row]      NVARCHAR(MAX)  NULL,        -- the rejected row as text
        [logged_ts]    DATETIME2      NOT NULL DEFAULT SYSDATETIME(), 
        CONSTRAINT fk_etl_error_row_batch_id FOREIGN KEY (batch_id) REFERENCES etl.batch_log(batch_id)
    );
END
GO
