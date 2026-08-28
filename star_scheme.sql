-- Skripts for designing the star scheme

-- Create file format
IF NOT EXISTS (SELECT * FROM sys.external_file_formats WHERE name = 'SynapseDelimitedTextFormat') 
    CREATE EXTERNAL FILE FORMAT [SynapseDelimitedTextFormat] 
    WITH ( FORMAT_TYPE = DELIMITEDTEXT ,
           FORMAT_OPTIONS (
             FIELD_TERMINATOR = ',',
             USE_TYPE_DEFAULT = FALSE
            ))
GO

IF NOT EXISTS (SELECT * FROM sys.external_data_sources WHERE name = '<TBD>_<TBD>_dfs_core_windows_net') 
    CREATE EXTERNAL DATA SOURCE [<TBD>_<TBD>_dfs_core_windows_net] 
    WITH (
        LOCATION = 'abfss://<TBD>@<TBD>.dfs.core.windows.net' 
    )
GO

-- dim_station
IF OBJECT_ID('dbo.dim_station') IS NOT NULL
BEGIN
    DROP EXTERNAL TABLE dbo.dim_station;
END
CREATE EXTERNAL TABLE dbo.dim_station 
WITH (
    LOCATION = 'dim_station',
    DATA_SOURCE = '<TBD>',
    FILE_FORMAT = [SynapseDelimitedTextFormat]
)
AS
SELECT
    ROW_NUMBER() over (ORDER BY [station_id]) as station_key,
    [station_id]
    [name]
    [latitude]
    [longitude]
FROM [dbo].[staging_station]
);
GO

-- dim_date
IF OBJECT_ID('dbo.dim_date') IS NOT NULL
BEGIN
    DROP EXTERNAL TABLE dbo.dim_date;
END
CREATE EXTERNAL TABLE dbo.dim_date 
WITH (
    LOCATION = 'dim_date',
    DATA_SOURCE = '<TBD>',
    FILE_FORMAT = [SynapseDelimitedTextFormat]
)
AS
SELECT
    CAST(CONVERT(varchar(8), d.[date], 112) as BIGINT) as date_key, -- Source: https://stackoverflow.com/questions/41353285/sql-server-date-format-yyyymmdd
    d.[date],
    DATENAME(dw, d.[date]) as [day_name], -- Source: https://blog.sqlauthority.com/2012/11/25/sql-server-find-weekend-and-weekdays-from-datetime-in-sql-server-2012/
    DATEPART(dw, d.[date]) as [day_of_week], -- Source: https://blog.sqlauthority.com/2012/11/25/sql-server-find-weekend-and-weekdays-from-datetime-in-sql-server-2012/
    DAY(d.[date]) as [day],
    MONTH(d.[date]) as [month],
    DATEPART(quarter, d.[date]) as [quarter],-- Source: https://blog.sqlauthority.com/2012/11/25/sql-server-find-weekend-and-weekdays-from-datetime-in-sql-server-2012/
    YEAR(d.[date]) as [year],
    CHOOSE(DATEPART(dw, d.[date]), 1,0,0,0,0,0,1) as [is_weekend]-- Source: https://blog.sqlauthority.com/2012/11/25/sql-server-find-weekend-and-weekdays-from-datetime-in-sql-server-2012/
FROM (
    SELECT DISTINCT
        all_dates.[date]
    FROM (
        SELECT DISTINCT
            CONVERT(DATE, [started_at]) as [date]
        FROM [dbo].[staging_trip]
        UNION
        SELECT DISTINCT
            CONVERT(DATE, [ended_at]) as [date]
        FROM [dbo].[staging_trip]
        UNION
        SELECT DISTINCT
            [date]
        FROM [dbo].[staging_payment]
    ) all_dates
) as d;
GO

-- dim_time
IF OBJECT_ID('dbo.dim_time') IS NOT NULL
BEGIN
    DROP EXTERNAL TABLE dbo.dim_time;
END
CREATE EXTERNAL TABLE dbo.dim_time 
WITH (
    LOCATION = 'dim_time',
    DATA_SOURCE = '<TBD>',
    FILE_FORMAT = [SynapseDelimitedTextFormat]
)
AS
SELECT
    ROW_NUMBER() OVER (ORDER BY t.[time]) as [time_key],
    t.[time],
    DATEPART(HOUR, t.[time]) AS [hour],
    DATEPART(MINUTE, t.[time]) as [minute],
    DATEPART(SECOND, t.[time]) as [second],
    CASE
    WHEN t.[hour] >= 5 and t.[hour] < 12 THEN
        'Morning'
    WHEN t.[hour] >= 12 and t.[hour] < 17 THEN
        'Afternoon'
    WHEN t.[hour] >= 17 and t.[hour] < 21 THEN
        'Evening'
    ELSE
        'Night'
    END as [time_of_day]
FROM (
    SELECT DISTINCT
        all_time.[time]
    FROM (
    SELECT DISTINCT
        CAST([started_at] as TIME) as [time]
    FROM [dbo].[staging_trip]
    UNION
    SELECT DISTINCT
        CAST([ended_at] as TIME) as [time]
    FROM [dbo].[staging_trip]
    ) all_time
) as t;
GO

-- dim_account
IF OBJECT_ID('dbo.dim_account') IS NOT NULL
BEGIN
    DROP EXTERNAL TABLE dbo.dim_account;
END
CREATE EXTERNAL TABLE dbo.dim_account 
WITH (
    LOCATION = 'dim_account',
    DATA_SOURCE = '<TBD>',
    FILE_FORMAT = [SynapseDelimitedTextFormat]
)
AS
SELECT
    ROW_NUMBER() OVER (ORDER BY [account_number]) as [account_key],
    [account_number],
    [member],
    [start_date],
    [end_date]
FROM [dbo].[staging_account]
;
GO

-- dim_rider
IF OBJECT_ID('dbo.dim_rider') IS NOT NULL
BEGIN
    DROP EXTERNAL TABLE dbo.dim_rider;
END
CREATE EXTERNAL TABLE dbo.dim_rider 
WITH (
    LOCATION = 'dim_rider',
    DATA_SOURCE = '<TBD>',
    FILE_FORMAT = [SynapseDelimitedTextFormat]
)
AS
SELECT
    ROW_NUMBER() OVER (ORDER BY [rider_id]) as [rider_key],
    [rider_id],
    [first] as [first_name],
    [last] as [last_name],
    [birthday],
    [account_number]
FROM [dbo].[staging_rider]
;
GO

-- FACT TABLES

-- fact_trip
IF OBJECT_ID('dbo.fact_trip') IS NOT NULL
BEGIN
    DROP EXTERNAL TABLE dbo.fact_trip;
END
CREATE EXTERNAL TABLE dbo.fact_trip 
WITH (
    LOCATION = 'fact_trip',
    DATA_SOURCE = '<TBD>',
    FILE_FORMAT = [SynapseDelimitedTextFormat]
)
AS
SELECT
    t.[trip_id] as [trip_key],
    t.[rideable_type],
    sa.[date_key] as [start_date_key],
    ea.[date_key] as [end_date_key],
    st.[time_key] as [start_time_key],
    et.[time_key] as [end_time_key],
    ss.[station_key] as [start_station_key],
    se.[station_key] as [end_station_key],
    r.[rider_key],
    a.[account_key],
    DATEDIFF(yy, r.[birthday], sa.[date]) as [age_rider], -- Source: https://learn.microsoft.com/en-us/sql/t-sql/functions/datediff-transact-sql?view=sql-server-ver17
    DATEDIFF(second, t.[started_at], t.[ended_at]) / 3600.0 as [trip_duration_hours]
FROM [dbo].[staging_trip] t
left join [dbo].[dim_date] sa
    on CONVERT(DATE, t.[started_at]) = sa.[date]
left join [dbo].[dim_date] ea
    on CONVERT(DATE, t.[ended_at]) = ea.[date]
left join [dbo].[dim_time] st
    on DATEPART(HOUR, t.[started_at]) = st.[hour]
    and DATEPART(MINUTE, t.[started_at]) = st.[minute]
    and DATEPART(SECOND, t.[started_at]) = st.[second]
left join [dbo].[dim_time] et
    on DATEPART(HOUR, t.[ended_at]) = et.[hour]
    and DATEPART(MINUTE, t.[ended_at]) = et.[minute]
    and DATEPART(SECOND, t.[ended_at]) = et.[second]
left join [dbo].[dim_station] ss
    on t.start_station_id = ss.station_id
left join [dbo].[dim_station] es
    on t.end_station_id = es.station_id
left join [dbo].[dim_rider] r
    on t.[member_id] = r.[rider_id]
left join [dbo].[dim_account] a
    on r.[account_number] = a.[account_number]
;
GO

-- fact_payment
IF OBJECT_ID('dbo.fact_payment') IS NOT NULL
BEGIN
    DROP EXTERNAL TABLE dbo.fact_payment;
END
CREATE EXTERNAL TABLE dbo.fact_payment 
WITH (
    LOCATION = 'fact_payment',
    DATA_SOURCE = '<TBD>',
    FILE_FORMAT = [SynapseDelimitedTextFormat]
)
AS
SELECT
    p.[payment_id] as [payment_key],
    d.[date_key],
    a.[account_key],
    DATEDIFF(yy, r.[birthday], a.[start_date]) as [age_rider_account_start],
    p.[amount]
FROM [dbo].[staging_payment] p
left join [dbo].[dim_date] d
    on p.[date] = d.[date]
left join [dbo].[dim_account] a
    on p.[account_number] = a.[account_number]
left join [dbo].[dim_rider] r
    on p.[account_number] = r.[account_number]
;
GO