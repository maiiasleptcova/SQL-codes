 /* Selecting and numbering district names */
 
 select Row_Number() over (order BY district_name) as RN
       ,DISTRICT_NAME 
 into #distr_name
 from( 
 Select * 
FROM OPENQUERY([D0-SQL14-08], 
'SELECT  distinct district_name
FROM [GeoSpatial].[sde].[LANDREGISTRY_NSD_AND_CCOD_ALL_PLY] 
where district_name is not null
 ') [Loc] )l

--EXEC tempdb.dbo.sp_help N'#distr_name';

 /*Declaring and setting the variables*/
declare @TSQL varchar(8000), @Counter int, @Total int , @District as varchar(70)
set @Counter = 308
--set @Total = 175
set @Total = (Select count(*) from #distr_name )
/*

 /* Create table  */
 
DROP TABLE [LandReg].[dbo].[CCODLeasesSameBuilding2]

CREATE TABLE [LandReg].[dbo].[CCODLeasesSameBuilding2]
(      Title_Freehold varchar(18)
      ,Title_Leasehold_Inside varchar(18)
	  ,District_name varchar(70)
	  )
*/

 /* Starting the loop */
while @Counter < @Total  + 1
begin

set @District= (select DISTRICT_NAME from #distr_name where RN = @Counter)


 /* Spacial join via openquery, add results to a temp table */
SELECT  @TSQL = 'Select * 
INTO ##Temp
FROM OPENQUERY([D0-SQL14-08], 
''SELECT a.TITLE_NO as Title_Freehold
       ,b.TITLE_NO as Title_Leasehold_Inside
	   ,a.District_Name
FROM [GeoSpatial].[sde].[LANDREGISTRY_NSD_AND_CCOD_ALL_PLY] a 
    ,[GeoSpatial].[sde].[LANDREGISTRY_NSD_AND_CCOD_ALL_PLY] b 
where a.tenure=''''freehold''''
  and a.shape.STContains(b.shape) = 1
  and b.tenure <>''''freehold''''
  and a.district_name = ''''' + replace(@District,char(39),char(39)+char(39)+char(39)+char(39)) + ''''' 
  and b.district_name = ''''' + replace(@District,char(39),char(39)+char(39)+char(39)+char(39)) + '''''
  and a.pty_addr not like ''''Land%''''
  and b.pty_addr not like ''''Land%''''
  '' )' 
EXEC (@TSQL)

 /* Insert from temp table to permanent table */
INSERT INTO [LandReg].[dbo].[CCODLeasesSameBuilding2] (
	Title_Freehold 
	,Title_Leasehold_Inside 
	,District_name)
SELECT 
    Title_Freehold 
	,Title_Leasehold_Inside 
	,District_name
FROM 
    ##Temp

-- drop temp table for loop to continue
DROP table ##Temp

set  @Counter = @Counter + 1
end


