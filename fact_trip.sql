IF OBJECT_ID('dbo.fact_trip') IS NOT NULL
BEGIN
    DROP EXTERNAL TABLE dbo.fact_trip;
END
GO 

CREATE EXTERNAL TABLE dbo.fact_trip 
WITH (
    LOCATION = 'fact_trip',
    DATA_SOURCE = rivvystorage_rivvyaccount_dfs_core_windows_net,
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
    es.[station_key] as [end_station_key],
    r.[rider_key],
    DATEDIFF(yy, r.[birthday], sa.[date]) as [age_rider], -- Source: https://learn.microsoft.com/en-us/sql/t-sql/functions/datediff-transact-sql?view=sql-server-ver17
    DATEDIFF(second, CONVERT(DATETIME2, t.[started_at]), CONVERT(DATETIME2, t.[ended_at])) / 3600.0 as [trip_duration_hours]
FROM [dbo].[staging_trip] t
left join [dbo].[dim_date] sa
    on CONVERT(DATE, CONVERT(DATE, t.[started_at])) = sa.[date]
left join [dbo].[dim_date] ea
    on CONVERT(DATE, CONVERT(DATE, t.[ended_at])) = ea.[date]
left join [dbo].[dim_time] st
    on DATEPART(HOUR, CONVERT(DATETIME2, t.[started_at])) = st.[hour]
    and DATEPART(MINUTE, CONVERT(DATETIME2, t.[started_at])) = st.[minute]
    and DATEPART(SECOND, CONVERT(DATETIME2, t.[started_at])) = st.[second]
left join [dbo].[dim_time] et
    on DATEPART(HOUR, CONVERT(DATETIME2, t.[ended_at])) = et.[hour]
    and DATEPART(MINUTE, CONVERT(DATETIME2, t.[ended_at])) = et.[minute]
    and DATEPART(SECOND, CONVERT(DATETIME2, t.[ended_at])) = et.[second]
left join [dbo].[dim_station] ss
    on t.start_station_id = ss.station_id
left join [dbo].[dim_station] es
    on t.end_station_id = es.station_id
left join [dbo].[dim_rider] r
    on t.[rider_id] = r.[rider_id]
;
GO