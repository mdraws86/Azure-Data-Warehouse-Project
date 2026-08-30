IF OBJECT_ID('dbo.fact_payment') IS NOT NULL
BEGIN
    DROP EXTERNAL TABLE dbo.fact_payment;
END
CREATE EXTERNAL TABLE dbo.fact_payment 
WITH (
    LOCATION = 'fact_payment',
    DATA_SOURCE = rivvystorage_rivvyaccount_dfs_core_windows_net,
    FILE_FORMAT = [SynapseDelimitedTextFormat]
)
AS
SELECT
    p.[payment_id] as [payment_key],
    d.[date_key],
    r.[rider_key],
    DATEDIFF(yy, r.[birthday], r.[account_start_date]) as [age_rider_account_start],
    p.[amount]
FROM [dbo].[staging_payment] p
left join [dbo].[dim_date] d
    on p.[date] = d.[date]
left join [dbo].[dim_rider] r
    on p.[rider_id] = r.[rider_id]
;
GO