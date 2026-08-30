IF OBJECT_ID('dbo.dim_date') IS NOT NULL
BEGIN
    DROP EXTERNAL TABLE dbo.dim_date;
END
CREATE EXTERNAL TABLE dbo.dim_date 
WITH (
    LOCATION = 'dim_date',
    DATA_SOURCE = rivvystorage_rivvyaccount_dfs_core_windows_net,
    FILE_FORMAT = [SynapseDelimitedTextFormat]
)
AS
SELECT
    CAST(CONVERT(varchar(8), CONVERT(DATE, d.[date]), 112) as BIGINT) as date_key, -- Source: https://stackoverflow.com/questions/41353285/sql-server-date-format-yyyymmdd
    d.[date],
    DATENAME(dw, CONVERT(DATE, d.[date])) as [day_name], -- Source: https://blog.sqlauthority.com/2012/11/25/sql-server-find-weekend-and-weekdays-from-datetime-in-sql-server-2012/
    DATEPART(dw, CONVERT(DATE, d.[date])) as [day_of_week], -- Source: https://blog.sqlauthority.com/2012/11/25/sql-server-find-weekend-and-weekdays-from-datetime-in-sql-server-2012/
    DAY(CONVERT(DATE, d.[date])) as [day],
    MONTH(CONVERT(DATE, d.[date])) as [month],
    DATEPART(quarter, CONVERT(DATE, d.[date])) as [quarter],-- Source: https://blog.sqlauthority.com/2012/11/25/sql-server-find-weekend-and-weekdays-from-datetime-in-sql-server-2012/
    YEAR(CONVERT(DATE, d.[date])) as [year],
    CHOOSE(DATEPART(dw, CONVERT(DATE, d.[date])), 1,0,0,0,0,0,1) as [is_weekend]-- Source: https://blog.sqlauthority.com/2012/11/25/sql-server-find-weekend-and-weekdays-from-datetime-in-sql-server-2012/
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