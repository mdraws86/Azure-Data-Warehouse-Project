IF OBJECT_ID('dbo.dim_rider') IS NOT NULL
BEGIN
    DROP EXTERNAL TABLE dbo.dim_rider;
END
CREATE EXTERNAL TABLE dbo.dim_rider 
WITH (
    LOCATION = 'dim_rider',
    DATA_SOURCE = rivvystorage_rivvyaccount_dfs_core_windows_net,
    FILE_FORMAT = [SynapseDelimitedTextFormat]
)
AS
SELECT
    ROW_NUMBER() OVER (ORDER BY [rider_id]) as [rider_key],
    [rider_id],
    [first] as [first_name],
    [last] as [last_name],
    [birthday],
    [is_member],
    CONVERT(DATE, [account_start_date]) as [account_start_date],
    CONVERT(DATE, [account_end_date]) as [account_end_date]
FROM [dbo].[staging_rider]
;
GO