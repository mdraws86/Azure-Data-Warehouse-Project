-- Skripts for designing the star scheme
IF OBJECT_ID('dbo.dim_station') IS NOT NULL
BEGIN
    DROP EXTERNAL TABLE dbo.dim_station;
END
CREATE EXTERNAL TABLE dbo.dim_station 
WITH (
    LOCATION = 'dim_station',
    DATA_SOURCE = 'TBD',
    FILE_FORMAT = [SynapseDeliitedTextFormat]
)
AS
SELECT
    ROW_NUMBER over (ORDER BY [station_id]) as station_key,
    [station_id]
    [name]
    [latitude]
    [longitude]
FROM [dbo].[staging_station]
);
GO

IF OBJECT_ID('dbo.dim_date') IS NOT NULL
BEGIN
    DROP EXTERNAL TABLE dbo.dim_date;
END
CREATE EXTERNAL TABLE dbo.dim_date 
WITH (
    LOCATION = 'dim_date',
    DATA_SOURCE = 'TBD',
    FILE_FORMAT = [SynapseDeliitedTextFormat]
)
AS
SELECT
    ROW_NUMBER() OVER (ORDER BY d.[date]) as date_key,
    d.[date],
    DATENAME(dw, d.[date]) as [day_name], -- Source: https://blog.sqlauthority.com/2012/11/25/sql-server-find-weekend-and-weekdays-from-datetime-in-sql-server-2012/
    DATEPART(dw, d.[date]) as [day_of_week], -- Source: https://blog.sqlauthority.com/2012/11/25/sql-server-find-weekend-and-weekdays-from-datetime-in-sql-server-2012/
    DAY(d.[date]) as [day],
    MONTH(d.[date]) as [month],
    YEAR(d.[date]) as [year],
    CHOOSE(DATEPART(dw, d.[date]), 1,0,0,0,0,0,1) as [is_weekend]-- Source: https://blog.sqlauthority.com/2012/11/25/sql-server-find-weekend-and-weekdays-from-datetime-in-sql-server-2012/
FROM (
    SELECT DISTINCT
        CONVERT(DATE, [started_at]) as [date]
    FROM [dbo].[staging_trip]
) as d;
GO

IF OBJECT_ID('dbo.dim_time') IS NOT NULL
BEGIN
    DROP EXTERNAL TABLE dbo.dim_time;
END
CREATE EXTERNAL TABLE dbo.dim_time 
WITH (
    LOCATION = 'dim_time',
    DATA_SOURCE = 'TBD',
    FILE_FORMAT = [SynapseDeliitedTextFormat]
)
AS
SELECT
    ROW_NUMBER() OVER (ORDER BY t.[time]) as [time_key],
    t.[time],
    DATEPART(HOUR, t.[time]) AS [hour],
    DATEPART(MINUTE, t.[time]) as [minute],
    DATEPART(SECOND, t.[time]) as [second]
FROM (
    SELECT DISTINCT
        CAST([started_at] as TIME) as [time]
    FROM [dbo].[staging_trip]
) as t;
GO
