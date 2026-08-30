IF OBJECT_ID('dbo.dim_station') IS NOT NULL
BEGIN
    DROP EXTERNAL TABLE dbo.dim_station;
END
CREATE EXTERNAL TABLE dbo.dim_station 
WITH (
    LOCATION = 'dim_station',
    DATA_SOURCE = rivvystorage_rivvyaccount_dfs_core_windows_net,
    FILE_FORMAT = [SynapseDelimitedTextFormat]
)
AS
SELECT
    ROW_NUMBER() over (ORDER BY [station_id]) as station_key,
    [station_id],
    [name],
    [latitude],
    [longitude]
FROM [dbo].[staging_station]
;
GO