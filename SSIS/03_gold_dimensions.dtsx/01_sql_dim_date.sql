DECLARE @batch_id INT = ?;
DECLARE @current_date DATE = '2016-01-01';
DECLARE @end_date DATE = '2019-12-31';

WHILE @current_date <= @end_date
BEGIN
    IF NOT EXISTS (SELECT 1 FROM [gold].[dim_date] WHERE [full_date] = @current_date)
    BEGIN
        INSERT INTO [gold].[dim_date] (
            [full_date], [calendar_year], [calendar_quarter], [calendar_month],
            [month_name], [year_month], [day_of_month], [day_of_week],
            [day_name], [is_weekend], [dwh_batch_id]
        )
        VALUES (
            @current_date,
            DATEPART(YEAR, @current_date),
            DATEPART(QUARTER, @current_date),
            DATEPART(MONTH, @current_date),
            DATENAME(MONTH, @current_date),
            FORMAT(@current_date, 'yyyy-MM'),
            DATEPART(DAY, @current_date),
            ((DATEPART(WEEKDAY, @current_date) + @@DATEFIRST - 2) % 7) + 1,
            DATENAME(WEEKDAY, @current_date),
            CASE WHEN (((DATEPART(WEEKDAY, @current_date) + @@DATEFIRST - 2) % 7) + 1) IN (6, 7) THEN 1 ELSE 0 END,
            @batch_id
        );
    END;
    SET @current_date = DATEADD(DAY, 1, @current_date);
END;

--Parameter Mapping

Variable Name	                    Direction	 Data Type	 Parameter Name	 Parameter Size
$Package::p_batch_id	            Input	     LONG	     0	             -1