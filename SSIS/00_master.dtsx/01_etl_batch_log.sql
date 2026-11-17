--01. Execute SQL Task - etl_batch_log
INSERT INTO etl.batch_log ([status])
OUTPUT INSERTED.batch_id
VALUES (N'RUNNING');

--02. Parameter Mapping
Variable Name	   Direction	Data Type	 Parameter Name	  Parameter Size
user::batch_id	   Input	    LONG	     0	             -1

--03. Result set
Result name    Variable name
0              user::batch_id