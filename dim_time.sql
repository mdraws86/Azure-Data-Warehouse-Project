-- I decided to split datetimes into dim_date and dim_time tables. For example, the business questions are about time of day partly.
-- It is also quicker to have an isolated dim_date if we want to answer questions regarding dates only.
IF OBJECT_ID('dbo.dim_time') IS NOT NULL
BEGIN
    DROP EXTERNAL TABLE dbo.dim_time;
END
CREATE EXTERNAL TABLE dbo.dim_time 
WITH (
    LOCATION = 'dim_time',
    DATA_SOURCE = rivvystorage_rivvyaccount_dfs_core_windows_net,
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
    WHEN DATEPART(HOUR, t.[time]) >= 5 and DATEPART(HOUR, t.[time]) < 12 THEN
        'Morning'
    WHEN DATEPART(HOUR, t.[time]) >= 12 and DATEPART(HOUR, t.[time]) < 17 THEN
        'Afternoon'
    WHEN DATEPART(HOUR, t.[time]) >= 17 and DATEPART(HOUR, t.[time]) < 21 THEN
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