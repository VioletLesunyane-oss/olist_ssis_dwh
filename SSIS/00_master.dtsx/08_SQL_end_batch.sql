-- 01. General
    --1.1. SQL Statement
UPDATE [etl].[batch_log]
SET [end_ts] = SYSDATETIME()
WHERE [batch_id] = ?;

--02. Parameter Mapping
Variable Name	   Direction	Data Type	 Parameter Name	  Parameter Size
user::batch_id	   Input	    LONG	     0	             -1