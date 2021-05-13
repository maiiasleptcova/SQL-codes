------------------------  TENANT DATA ------------------------------
SELECT i.TenancyId,
       CASE
         WHEN g.NAME IS NOT NULL THEN g.NAME
         WHEN i.GenericDescription IS NOT NULL THEN i.GenericDescription
       END
       AS NAME,
       'Tenant'
       + Cast(ROW_NUMBER() OVER( partition BY [TenancyId] ORDER BY NAME) AS
       VARCHAR) AS
       Tenant
INTO   #tenant
FROM   (SELECT DISTINCT [TenancyId],
                        [CompanyId],
                        GenericDescription
        FROM   [HubLive].[dbo].[Tenancyparty]
        WHERE  Discriminator = 'TEN'
               AND ( [CompanyId] IS NOT NULL
                      OR GenericDescription IS NOT NULL ))i
       LEFT JOIN [HubLive].[dbo].[Company] g
              ON i.CompanyId = g.Id
WHERE  g.NAME IS NOT NULL
        OR i.GenericDescription IS NOT NULL
ORDER  BY [TenancyId]

SELECT i.TenancyId,
       CASE
         WHEN g.NAME IS NOT NULL THEN g.NAME
         WHEN i.GenericDescription IS NOT NULL THEN i.GenericDescription
       END AS NAME,
       i.CompanyId
INTO   #tenant2
FROM   (SELECT DISTINCT [TenancyId],
                        [CompanyId],
                        GenericDescription
        FROM   [HubLive].[dbo].[Tenancyparty]
        WHERE  Discriminator = 'TEN'
               AND ( [CompanyId] IS NOT NULL
                      OR GenericDescription IS NOT NULL ))i
       LEFT JOIN [HubLive].[dbo].[Company] g
              ON i.CompanyId = g.Id
WHERE  g.NAME IS NOT NULL
        OR i.GenericDescription IS NOT NULL
ORDER  BY [TenancyId]

SELECT TOP 1000 *
FROM   #tenant2

/*
select * from #Tenant
where tenancyID='50845621-2A1D-EB11-A95A-000D3AB2EFEE'

select top 10 *   FROM [HubLive].[dbo].[TenancyParty]
where tenancyID='E259DB5F-2919-EB11-A95A-000D3AB2EFEE'
*/
DECLARE @SQLQUERY2 AS NVARCHAR(max)
DECLARE @PIVOTCOLUMNS2 AS NVARCHAR(max)

SELECT @PIVOTCOLUMNS2 = COALESCE(@PIVOTCOLUMNS2 + ',', '')
                        + Quotename([Tenant])
FROM   (SELECT DISTINCT Tenant
        FROM   #tenant) t

SET @SQLQUERY2=N'SELECT [TenancyId],' + @PIVOTCOLUMNS2
               + ' INTO ##PIVOTTT FROM  #Tenant  PIVOT(MAX([Name])       FOR [Tenant] IN (' + @PIVOTCOLUMNS2
               + ')) AS Q'

--SELECT   @SQLQuery
EXEC SP_EXECUTESQL
  @SQLQUERY2

-----  END OF TENANT DATA 
------ LANDLORD DATA -----------
SELECT i.TenancyId,
       g.NAME,
       'Landlord'
       + Cast(ROW_NUMBER() OVER( partition BY [TenancyId] ORDER BY NAME) AS
       VARCHAR) AS
       Landlord
INTO   #landlord
FROM   (SELECT DISTINCT [TenancyId],
                        [CompanyId]
        FROM   [HubLive].[dbo].[Tenancyparty]
        WHERE  Discriminator = 'LAN'
               AND [CompanyId] IS NOT NULL)i
       INNER JOIN [HubLive].[dbo].[Company] g
               ON i.CompanyId = g.Id
WHERE  g.NAME IS NOT NULL
ORDER  BY [TenancyId]

--DROP TABLE ##PIVOTTT
--DROP TABLE ##PIVOTLL
DECLARE @SQLQUERY AS NVARCHAR(max)
DECLARE @PIVOTCOLUMNS AS NVARCHAR(max)

SELECT @PIVOTCOLUMNS = COALESCE(@PIVOTCOLUMNS + ',', '')
                       + Quotename([Landlord])
FROM   (SELECT DISTINCT [Landlord]
        FROM   #landlord) t

SET @SQLQUERY=N'SELECT [TenancyId],' + @PIVOTCOLUMNS
              + ' INTO ##PIVOTLL FROM  #Landlord  PIVOT(MAX([Name])       FOR [Landlord] IN (' + @PIVOTCOLUMNS
              + ')) AS Q'

--SELECT   @SQLQuery
EXEC SP_EXECUTESQL
  @SQLQUERY

----------------------- END OF LANDLORD DATA ---------------------------------
----------------------- OWNERSHIP DATA -------------------------
--drop table #owner
SELECT
-- top 2000
CASE
  WHEN p.NAME IS NULL THEN n.FirstName + ' ' + n.LastName
  ELSE p.NAME
END                                                     AS NAME,
'Owner'
+ Cast(ROW_NUMBER() OVER( partition BY q.Id, d.OwnershipTenureId,
d.PurchaseDate, d.SellDate ORDER BY p.NAME) AS VARCHAR) AS Owner,
d.PurchaseDate,
d.SellDate,
CASE
  WHEN d.OwnershipTenureId = '044C1D04-E1F7-45F8-A1F7-5DE9EC11930A' THEN
  'Leasehold'
  WHEN d.OwnershipTenureId = '034C1D04-E1F7-45F8-A1F7-5DE9EC11930A' THEN
  'Freehold'
  WHEN d.OwnershipTenureId = '443AC5EC-D48D-4C8E-B849-58B78C07278A' THEN
  'Unknown'
  WHEN d.OwnershipTenureId = '19EE812C-DE27-E611-80C5-005056820A11' THEN
  'Share of Freehold'
END                                                     AS Tenure,
q.Id                                                    AS AssetId
INTO   #owner
FROM   [HubLive].[dbo].Asset q
       LEFT JOIN [HubLive].[dbo].[Ownership] d
              ON q.Id = d.AssetId
       LEFT JOIN [HubLive].[dbo].[Ownershipowner] f
              ON d.Id = f.OwnershipId
       LEFT JOIN [HubLive].[dbo].Assetparty i
              ON i.Id = f.OwnerId
       LEFT JOIN [HubLive].[dbo].[Company] p
              ON i.CompanyId = p.Id
       LEFT JOIN [HubLive].[dbo].[Contact] n
              ON i.ContactID = n.Id
WHERE  isnotcurrent = 0

DECLARE @SQLQUERY3 AS NVARCHAR(max)
DECLARE @PIVOTCOLUMNS3 AS NVARCHAR(max)

SELECT @PIVOTCOLUMNS3 = COALESCE(@PIVOTCOLUMNS3 + ',', '')
                        + Quotename([Owner])
FROM   (SELECT DISTINCT Owner
        FROM   #owner) t

SET @SQLQUERY3=N'SELECT [AssetId], Tenure, PurchaseDate, SellDate, '
               + @PIVOTCOLUMNS3 + ' INTO ##PIVOTOO FROM  #owner  PIVOT(MAX([Name])       FOR [Owner] IN ('
               + @PIVOTCOLUMNS3 + ')) AS Q'

--SELECT   @SQLQuery
EXEC SP_EXECUTESQL
  @SQLQUERY3

--and q.AssetId='87ED9A9B-183D-E611-80C5-005056820A11'
------------------------------  END OF OWNERSHIP DATA -------------------------------
-----------------------------  PUTTING EVERYTHING TOGETHER -------------------------
SELECT
--top 1000
DISTINCT q.Id                                                       AS TenancyId
         ,
         q.AssetId,
         q.LeaseCommencementDate,
         q.LeaseExpiryDate,
         Datediff(year, q.leasecommencementdate, q.leaseexpirydate) AS LeaseLenY
         ,
         Datediff(week, q.leasecommencementdate, q.leaseexpirydate) AS
         LeaseLenW,
         m.Tenant1,
         m.Tenant2,
         m.Tenant3,
         m.Tenant4,
         m.Tenant5,
         k.Landlord1,
         k.Landlord2,
         k.Landlord3,
         t.Owner1,
         t.Owner2,
         t.Owner3,
         t.Owner4,
         t.Tenure,
         t.PurchaseDate,
         t.SellDate
         --, j.FirstName
         --, j.LastName
         ,
         z.Code                                                     AS
         PropertyType,
         s.PropertyName,
         s.PropertyNumber,
         s.Line1,
         s.Line2,
         s.Line3,
         s.Postcode,
         s.City,
         s.County,
         s.uprnkey                                                  AS UPRN,
         s.udprnkey                                                 AS UDPRN,
         CASE
           WHEN LEFT(q.tenancytypeid, 1) = '8' THEN 'Residential'
           WHEN LEFT(q.tenancytypeid, 1) = '9' THEN 'Commercial'
           ELSE NULL
         END                                                        AS
         TenancyType
INTO   #hub
FROM   [HubLive].[dbo].[Tenancy] q
       INNER JOIN [HubLive].[dbo].[Asset] w
               ON q.assetid = w.id
       INNER JOIN [HubLive].[dbo].[Address] s
               ON w.addressid = s.id
       LEFT JOIN [HubLive].[dbo].[Tenancyparty] a
              ON q.id = a.tenancyid
       LEFT JOIN [HubLive].[dbo].[Company] c
              ON a.CompanyId = c.id
       LEFT JOIN [HubLive].[dbo].[Propertytype] z
              ON w.PropertyTypeId = z.Id
       --left join [HubLive].[dbo].[Contact] j
       --on a.ContactId=j.Id
       LEFT JOIN ##pivotll k
              ON q.Id = k.TenancyID
       LEFT JOIN ##pivottt m
              ON q.Id = m.TenancyID
       LEFT JOIN ##pivotoo t
              ON t.AssetID = q.AssetId
WHERE  LEFT(q.tenancytypeid, 1) = '9'
       AND q.Deleted = 0

--and LeaseExpiryDate>GETDATE() 
SELECT
--top 1000
DISTINCT q.Id                                                       AS TenancyId
         ,
         q.AssetId,
         q.LeaseCommencementDate,
         q.LeaseExpiryDate,
         Datediff(year, q.leasecommencementdate, q.leaseexpirydate) AS LeaseLenY
         ,
         Datediff(week, q.leasecommencementdate, q.leaseexpirydate) AS
         LeaseLenW,
         m.NAME                                                     AS Tenant,
         m.CompanyID                                                AS
         TenantCompanyID,
         k.Landlord1,
         k.Landlord2,
         k.Landlord3
         --, t.Owner1
         --, t.Owner2
         --, t.Owner3
         --, t.Owner4
         --,t.Tenure
         --, t.PurchaseDate
         --, t.SellDate
         --, j.FirstName
         --, j.LastName
         ,
         z.Code                                                     AS
         PropertyType,
         s.PropertyName,
         s.PropertyNumber,
         s.Line1,
         s.Line2,
         s.Line3,
         s.Postcode,
         s.City,
         s.County,
         s.uprnkey                                                  AS UPRN,
         s.udprnkey                                                 AS UDPRN,
         CASE
           WHEN LEFT(q.tenancytypeid, 1) = '8' THEN 'Residential'
           WHEN LEFT(q.tenancytypeid, 1) = '9' THEN 'Commercial'
           ELSE NULL
         END                                                        AS
         TenancyType
INTO   #hub2
FROM   [HubLive].[dbo].[Tenancy] q
       INNER JOIN [HubLive].[dbo].[Asset] w
               ON q.assetid = w.id
       INNER JOIN [HubLive].[dbo].[Address] s
               ON w.addressid = s.id
       LEFT JOIN [HubLive].[dbo].[Tenancyparty] a
              ON q.id = a.tenancyid
       LEFT JOIN [HubLive].[dbo].[Company] c
              ON a.CompanyId = c.id
       LEFT JOIN [HubLive].[dbo].[Propertytype] z
              ON w.PropertyTypeId = z.Id
       --left join [HubLive].[dbo].[Contact] j
       --on a.ContactId=j.Id
       LEFT JOIN ##pivotll k
              ON q.Id = k.TenancyID
       LEFT JOIN #tenant2 m
              ON q.Id = m.TenancyID
WHERE  LEFT(q.tenancytypeid, 1) = '9'
       AND q.Deleted = 0
--and LeaseExpiryDate>GETDATE() 