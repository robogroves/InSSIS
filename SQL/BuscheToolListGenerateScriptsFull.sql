USE [master]
GO
/****** Object:  Database [Busche ToolList]    Script Date: 4/20/2018 11:36:41 AM ******/
CREATE DATABASE [Busche ToolList]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'Busche ToolList_Data', FILENAME = N'D:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\Busche ToolList.mdf' , SIZE = 160384KB , MAXSIZE = UNLIMITED, FILEGROWTH = 10%)
 LOG ON 
( NAME = N'Busche ToolList_Log', FILENAME = N'D:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\Busche ToolList_log.ldf' , SIZE = 24384KB , MAXSIZE = UNLIMITED, FILEGROWTH = 10%)
GO
ALTER DATABASE [Busche ToolList] SET COMPATIBILITY_LEVEL = 90
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [Busche ToolList].[dbo].[sp_fulltext_database] @action = 'disable'
end
GO
ALTER DATABASE [Busche ToolList] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [Busche ToolList] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [Busche ToolList] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [Busche ToolList] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [Busche ToolList] SET ARITHABORT OFF 
GO
ALTER DATABASE [Busche ToolList] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [Busche ToolList] SET AUTO_CREATE_STATISTICS ON 
GO
ALTER DATABASE [Busche ToolList] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [Busche ToolList] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [Busche ToolList] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [Busche ToolList] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [Busche ToolList] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [Busche ToolList] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [Busche ToolList] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [Busche ToolList] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [Busche ToolList] SET  DISABLE_BROKER 
GO
ALTER DATABASE [Busche ToolList] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [Busche ToolList] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [Busche ToolList] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [Busche ToolList] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [Busche ToolList] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [Busche ToolList] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [Busche ToolList] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [Busche ToolList] SET RECOVERY SIMPLE 
GO
ALTER DATABASE [Busche ToolList] SET  MULTI_USER 
GO
ALTER DATABASE [Busche ToolList] SET PAGE_VERIFY TORN_PAGE_DETECTION  
GO
ALTER DATABASE [Busche ToolList] SET DB_CHAINING OFF 
GO
ALTER DATABASE [Busche ToolList] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [Busche ToolList] SET TARGET_RECOVERY_TIME = 0 SECONDS 
GO
USE [Busche ToolList]
GO
/****** Object:  User [BUSCHE-SQL\Guest]    Script Date: 4/20/2018 11:36:41 AM ******/
CREATE USER [BUSCHE-SQL\Guest] FOR LOGIN [BUSCHE-SQL\Guest] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [BUSCHE\timeclock]    Script Date: 4/20/2018 11:36:41 AM ******/
CREATE USER [BUSCHE\timeclock] FOR LOGIN [BUSCHE\timeclock] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [BUSCHE\Domain Users]    Script Date: 4/20/2018 11:36:41 AM ******/
CREATE USER [BUSCHE\Domain Users] FOR LOGIN [BUSCHE\Domain Users]
GO
/****** Object:  User [admin]    Script Date: 4/20/2018 11:36:41 AM ******/
CREATE USER [admin] WITHOUT LOGIN WITH DEFAULT_SCHEMA=[dbo]
GO
ALTER ROLE [db_owner] ADD MEMBER [BUSCHE-SQL\Guest]
GO
ALTER ROLE [db_owner] ADD MEMBER [BUSCHE\Domain Users]
GO
ALTER ROLE [db_owner] ADD MEMBER [admin]
GO
/****** Object:  StoredProcedure [dbo].[AllOtherUsage]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AllOtherUsage] 
-- Determine combined other tool list usage of this item 
-- sum up the list of MonthlyUsage's to determine how many of these items we need for all tool lists
-- except the old and new tool lists passed into procedure 
	@cmId nvarchar(50),
	@newProcId int,
	@oldProcId int,
	@result int OUTPUT
AS
BEGIN
SET NOCOUNT ON
Declare @nPc Integer
Declare @Pc Integer
Declare @nC Integer

--     4 items   -- ti.Quantity
--    --------
--     20 parts  -- (ti.QuantityPerCuttingEdge * ti.NumberOfCuttingEdges) 

--     100       -- (tm.AnnualVolume / 12) = how many parts are needed per month

--     4 items       ? items    = MonthlyUsage
--     -------   X  ---------
--     20 parts     100 parts 

--   if 4 items are needed to make 20 parts then 20 items are needed to make 100 parts
-- 	 (ti.Quantity * (tm.AnnualVolume/12)) / (ti.QuantityPerCuttingEdge * ti.NumberOfCuttingEdges) 
    
-- Not part specific  
-- consumable means the item has a tool life
select @nPc = sumMonthlyUsage 
from (
SELECT   
 case 
	when sum(MonthlyUsage) is null then cast(0.0 as decimal(18,2)) 
	else ceiling(sum(MonthlyUsage))
  end as sumMonthlyUsage  
from (
SELECT 
(ti.Quantity * (tm.AnnualVolume/12.0)) / (ti.QuantityPerCuttingEdge * ti.NumberOfCuttingEdges) 
as MonthlyUsage -- how many items are needed to make tm.AnnualVolume/12 parts
FROM [TOOLLIST ITEM] as ti 
inner join [TOOLLIST TOOL] as tt on ti.toolid=tt.toolid
INNER JOIN [TOOLLIST MASTER] as tm ON tt.PROCESSID = tm.PROCESSID 
where tt.PartSpecific = 0 and ti.Consumable = 1 and ti.CRIBTOOLID = @cmId
-- if a tool list is being revised there will be two tool lists in the database
-- only count the items in the original released one and make sure the tool
-- list is still in use 
AND tm.Obsolete = 0 and tm.RevOfProcessID = 0 and tm.Released = 1
AND ti.PROCESSID <> @newProcId AND ti.PROCESSID <> @oldProcId
) as usage
) as sumQ

-- part specific 
-- consumable
select @Pc = sumMonthlyUsage
from (
SELECT   
 case 
	when sum(MonthlyUsage) is null then cast(0.0 as decimal(18,2)) 
	else ceiling(sum(MonthlyUsage))
  end as sumMonthlyUsage  
from
(
SELECT 
(ti.Quantity * (tt.AdjustedVolume/12)) / (ti.QuantityPerCuttingEdge * ti.NumberOfCuttingEdges) 
as MonthlyUsage -- how many items are needed to make tt.AdjustedVolume/12 parts
FROM [TOOLLIST ITEM] as ti 
inner join [TOOLLIST TOOL] as tt on ti.toolid=tt.toolid
INNER JOIN [TOOLLIST MASTER] as tm ON tt.PROCESSID = tm.PROCESSID 
where tt.PartSpecific = 1 and ti.Consumable = 1 and ti.CRIBTOOLID = @cmId 
AND tm.Obsolete = 0 and tm.RevOfProcessID = 0 and tm.Released = 1
AND ti.PROCESSID <> @newProcId AND ti.PROCESSID <> @oldProcId
) as usage
) as sumQ

-- not consumable means the item is not perishable and the quantity field represents the number of the item
-- we need on hand to cnc the part
-- monthly usage is a misnomer in this case
select @nC = sumMonthlyUsage
from (
SELECT   
 case 
	when sum(MonthlyUsage) is null then cast(0.0 as decimal(18,2)) 
	else ceiling(sum(MonthlyUsage))
  end as sumMonthlyUsage  
from (
SELECT ti.Quantity as MonthlyUsage  
FROM [TOOLLIST ITEM] as ti 
inner join [TOOLLIST TOOL] as tt on ti.toolid=tt.toolid
INNER JOIN [TOOLLIST MASTER] as tm ON tt.PROCESSID = tm.PROCESSID 
where ti.Consumable = 0 and ti.CRIBTOOLID = @cmId 
AND tm.Obsolete = 0 and tm.RevOfProcessID = 0 and tm.Released = 1
AND ti.PROCESSID <> @newProcId AND ti.PROCESSID <> @oldProcId
) as usage
) as sumQ

set nocount off
Set @result = @nPc + @Pc + @nC
Select @result 
end


GO
/****** Object:  StoredProcedure [dbo].[bpDistinctToolListItems]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--///////////////////////////////////////////////////////////////////////////////////
-- Generate Distinct ToolList table
--///////////////////////////////////////////////////////////////////////////////////
create PROCEDURE [dbo].[bpDistinctToolListItems] 
AS
BEGIN
	IF
	OBJECT_ID('btDistinctToolListItems') IS NOT NULL
		DROP TABLE btDistinctToolListItems
	select * 
	into btDistinctToolListItems
	from bvDistinctToollistItems
end


GO
/****** Object:  StoredProcedure [dbo].[bpDistinctToolLists]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--///////////////////////////////////////////////////////////////////////////////////
-- Generate Distinct ToolList table
--///////////////////////////////////////////////////////////////////////////////////
create PROCEDURE [dbo].[bpDistinctToolLists] 
AS
BEGIN
	IF
	OBJECT_ID('btDistinctToolLists') IS NOT NULL
		DROP TABLE btDistinctToolLists
	select * 
	into btDistinctToolLists
	from bvDistinctToollists
end

GO
/****** Object:  StoredProcedure [dbo].[bpGetTLReportAccuracy]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROCEDURE [dbo].[bpGetTLReportAccuracy]   
AS
select count(*) ToolListsMultiPnCnt from bvGetToolListsMultiPn

GO
/****** Object:  StoredProcedure [dbo].[bpGetToolBossItemListTBS0]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[bpGetToolBossItemListTBS0]
 @plant int
as
BEGIN
	SELECT     '$ALL$' AS [User], originalprocessid AS Job, 'DEFAULT' AS Machine, '133' AS D_Consumer, CribToolID AS item, '3' AS D_Item, plant
	FROM         dbo.bfToolListItemsInPlant(@plant)
	where toolbossStock = 0
	ORDER BY job, item
END

GO
/****** Object:  StoredProcedure [dbo].[bpGetToolBossItemListTBS1]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[bpGetToolBossItemListTBS1]
 @plant int
as
BEGIN
	SELECT     '$ALL$' AS [User], originalprocessid AS Job, 'DEFAULT' AS Machine, '133' AS D_Consumer, CribToolID AS item, '3' AS D_Item, plant
	FROM         dbo.bfToolListItemsInPlant(@plant)
	where toolbossStock = 1
	ORDER BY job, item
END

GO
/****** Object:  StoredProcedure [dbo].[bpGetToolBossJobList]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROCEDURE [dbo].[bpGetToolBossJobList] 
	-- Add the parameters for the stored procedure here
	@plant int
AS
BEGIN
select * from bfGetToolBossJobList(@plant)
order by Descr
END

GO
/****** Object:  StoredProcedure [dbo].[bpItemsPerPart]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--///////////////////////////////////////////////////////////////////////////////////
-- all toolops and the itemsPerPart multiplier for distinct partnumber,itemnumber pairs
--///////////////////////////////////////////////////////////////////////////////////
create PROCEDURE [dbo].[bpItemsPerPart] 
AS
BEGIN
	SET NOCOUNT ON
	IF
	OBJECT_ID('tempdb.dbo.#btToolOps') IS NOT NULL
		DROP TABLE #btToolOps
	IF
	OBJECT_ID('btItemsPerPart') IS NOT NULL
		DROP TABLE btItemsPerPart

	DECLARE
		  @allToolOps VARCHAR(max)

	select
		partNumber,
		itemNumber,
		itemsPerPart, 
		'<br>' +  tlDescription + ', ' + OpDescription + ', ' + tooldescription + 
		'<br>Quantity Per Tool:' + cast(Quantity as varchar(10)) +
		', Quantity Per Cutting Edge:' + cast(QuantityPerCuttingEdge as varchar(10)) +
		', Number Of Cutting Edges:' + cast(NumberOfCuttingEdges as varchar(10)) +
		'<br>Items Per Part:' + cast(cast(itemsPerPartPerTool as numeric(19,8)) as varchar(50)) as ToolOp
		, RowNum = ROW_NUMBER() OVER (PARTITION BY partNumber,itemNumber ORDER BY 1/0)
		, allToolOps = CAST(NULL AS VARCHAR(max))
	INTO #btToolOps
	from 
	(
		select tid.partNumber,tid.itemnumber,tid.itemsPerPart as itemsPerPartPerTool,
		tis.itemsPerPart,tlDescription,
		opDescription,tooldescription,monthlyUsage,
		itemType,Quantity,AnnualVolume,QuantityPerCuttingEdge,NumberOfCuttingEdges,
		tid.Consumable,PartSpecific,AdjustedVolume
		from 
		(
			select * from bvToolListItemsLv1
			where consumable = 1
			--8407
		)tid
		--32571
		inner join
		(
			--distinct partNumber,itemNumber
			select partNumber, itemNumber,consumable,
			sum(itemsPerPart) as itemsPerPart
			from bvToolListItemsLv1
			group by 
			partNumber, itemNumber,consumable
			having Consumable = 1 
			-- 7050
		) tis
		on
		tid.partNumber=tis.partNumber and
		tid.itemNumber=tis.itemNumber
		--8407
	) tops

	UPDATE #btToolOps
	SET 
		  @allToolOps = allToolOps =
			CASE WHEN RowNum = 1 
				THEN toolOp
				ELSE @allToolOps + '<br>' + toolOp 
			END

	select partNumber,itemNumber,itemsPerPart, 
		max(allToolOps) as toolOps
	into btItemsPerPart
	from #btToolOps
	group by partNumber,itemNumber,itemsPerPart
	-- 7050
end

GO
/****** Object:  StoredProcedure [dbo].[bpObsToolListItems]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-------------------------------------------------
-- Obsolete ToolList items,misc,and fixture detail
-- grouped by item number 
-------------------------------------------------
create PROCEDURE [dbo].[bpObsToolListItems] 
AS
BEGIN
	SET NOCOUNT ON
IF
OBJECT_ID('dbo.btObsToolListItems') IS NOT NULL
	DROP TABLE btObsToolListItems
IF
OBJECT_ID('tempdb.dbo.#btObsOpDesc') IS NOT NULL
	DROP TABLE #btObsOpDesc

DECLARE
      @opDescList VARCHAR(max)

select 
	itemNumber,tlDescription,
	opDescription,tooldescription
    , RowNum = ROW_NUMBER() OVER (PARTITION BY itemNumber ORDER BY 1/0)
    , opDescList = CAST(NULL AS VARCHAR(max))
into #btObsOpDesc
from bvObsToolListItemsLv1
--12 sec



UPDATE #btObsOpDesc
SET 
      @opDescList = opDescList =
        CASE WHEN RowNum = 1 
            THEN tlDescription + ', ' + opDescription + ', '  + toolDescription
            ELSE @opDescList + '<br>' + tlDescription + ', ' + opDescription + ', '  + toolDescription 
        END

-- 14 sec

select 
      itemNumber
    , opDescList = MAX(opDescList) 
into btObsToolListItems
from #btObsOpDesc
GROUP BY itemNumber 
end


GO
/****** Object:  StoredProcedure [dbo].[bpToolListItems]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-------------------------------------------------
-- Active ToolList items,misc,and fixture detail
-- grouped by item number 
-------------------------------------------------
create PROCEDURE [dbo].[bpToolListItems] 
AS
BEGIN
	SET NOCOUNT ON
IF
OBJECT_ID('dbo.btToolListItems') IS NOT NULL
	DROP TABLE btToolListItems
IF
OBJECT_ID('tempdb.dbo.#btOpDesc') IS NOT NULL
	DROP TABLE #btOpDesc

DECLARE
      @opDescList VARCHAR(max)

select 
	itemNumber,tlDescription,
	opDescription,tooldescription
    , RowNum = ROW_NUMBER() OVER (PARTITION BY itemNumber ORDER BY 1/0)
    , opDescList = CAST(NULL AS VARCHAR(max))
into #btOpDesc
from bvToolListItemsLv1
--12 sec


UPDATE #btOpDesc
SET 
      @opDescList = opDescList =
        CASE WHEN RowNum = 1 
            THEN tlDescription + ', ' + opDescription + ', '  + toolDescription
            ELSE @opDescList + '<br>' + tlDescription + ', ' + opDescription + ', '  + toolDescription 
        END

-- 14 sec

select 
      itemNumber
    , opDescList = MAX(opDescList) 
into btToolListItems
from #btOpDesc
GROUP BY itemNumber 
end

GO
/****** Object:  StoredProcedure [dbo].[bpToolListItemsLv2]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
---------------------------------------------
-- simplier version
-- ToolList items that are in plants with Tool 
-- Ops description list
-----------------------------------------------
create Procedure [dbo].[bpToolListItemsLv2] 
as
BEGIN
	SET NOCOUNT ON
	IF
		OBJECT_ID('tempdb.dbo.#btToolOps') IS NOT NULL
		DROP TABLE #btToolOps

	IF
		OBJECT_ID('ToolListItems') IS NOT NULL
		DROP TABLE ToolListItems

	DECLARE
		@allToolOps VARCHAR(max)

	select ti.processId,ti.CribToolID as itemNumber,ti.tooldescription,
	tt.OpDescription,
	(tm.Customer + ' - ' + tm.PartFamily + ' - ' + tm.OperationDescription) tlDescription
	, RowNum = ROW_NUMBER() OVER (PARTITION BY ti.processid,ti.CribToolId ORDER BY 1/0)
	, allToolOps = CAST(NULL AS VARCHAR(max))
	INTO #btToolOps
	FROM [TOOLLIST ITEM] as ti 
	-- when a tool gets deleted the toollist item remains?
	-- we don't want the toollist item if it is not on a toollist tool
	inner join [TOOLLIST TOOL] as tt on ti.toolid=tt.toolid
	inner join [TOOLLIST Master] as tm on tm.ProcessID=ti.ProcessID
	--35080

		update #btToolOps
			set @allToolOps = allToolOps =
				case 
					when RowNum = 1 then tlDescription + ', ' + OpDescription + ', ' + tooldescription
					else @allToolOps + '<br>' + tlDescription + ', ' + OpDescription + ', ' + tooldescription
				end

		select lv1.*,lv2.allToolOps
		into ToolListItems
		from
		(
			select distinct originalprocessid,processid, partNumber, itemNumber
			from bvToolListItemsInPlants 
			--28467
		)lv1
		inner join
		(
			select processId,itemNumber,max(allToolOps) allToolOps
			from 
			#btToolOps
			group by ProcessID,itemNumber
			--27630
		)lv2
		on lv1.processid = lv2.ProcessID
		and lv1.itemNumber = lv2.itemNumber
		--24208

end

GO
/****** Object:  StoredProcedure [dbo].[bpToolListPartItems]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--///////////////////////////////////////////////////////////////////////////////////
-- all toolops and the itemsPerPart multiplier for distinct partnumber,itemnumber pairs
--///////////////////////////////////////////////////////////////////////////////////
create PROCEDURE [dbo].[bpToolListPartItems] 
AS
BEGIN
	SET NOCOUNT ON
	IF
	OBJECT_ID('tempdb.dbo.#btToolOps') IS NOT NULL
		DROP TABLE #btToolOps
	IF
	OBJECT_ID('btToolListPartItems') IS NOT NULL
		DROP TABLE btToolListPartItems

	DECLARE
		  @allToolOps VARCHAR(max)

	select
		partNumber,
		itemNumber,
		itemsPerPart, 
		'<br>' +  tlDescription + ', ' + OpDescription + ', ' + tooldescription + 
		'<br>Quantity Per Tool:' + cast(Quantity as varchar(10)) +
		', Quantity Per Cutting Edge:' + cast(QuantityPerCuttingEdge as varchar(10)) +
		', Number Of Cutting Edges:' + cast(NumberOfCuttingEdges as varchar(10)) +
		'<br>Items Per Part:' + cast(cast(itemsPerPartPerTool as numeric(19,8)) as varchar(50)) as ToolOp
		, RowNum = ROW_NUMBER() OVER (PARTITION BY partNumber,itemNumber ORDER BY 1/0)
		, allToolOps = CAST(NULL AS VARCHAR(max))
	INTO #btToolOps
	from 
	(
		select tid.partNumber,tid.itemnumber,tid.itemsPerPart as itemsPerPartPerTool,
		tis.itemsPerPart,tlDescription,
		opDescription,tooldescription,monthlyUsage,
		itemType,Quantity,AnnualVolume,QuantityPerCuttingEdge,NumberOfCuttingEdges,
		tid.Consumable,PartSpecific,AdjustedVolume
		from 
		(
			select * from bvToolListItemsLv1
			where consumable = 1
			--8407
		)tid
		--32571
		inner join
		(
			--distinct partNumber,itemNumber
			select partNumber, itemNumber,consumable,
			sum(itemsPerPart) as itemsPerPart
			from bvToolListItemsLv1
			group by 
			partNumber, itemNumber,consumable
			having Consumable = 1 
			-- 7050
		) tis
		on
		tid.partNumber=tis.partNumber and
		tid.itemNumber=tis.itemNumber
		--8407
	) tops

	UPDATE #btToolOps
	SET 
		  @allToolOps = allToolOps =
			CASE WHEN RowNum = 1 
				THEN toolOp
				ELSE @allToolOps + '<br>' + toolOp 
			END

	select partNumber,itemNumber,itemsPerPart, 
		max(allToolOps) as toolOps
	into btToolListPartItems
	from #btToolOps
	group by partNumber,itemNumber,itemsPerPart
	-- 7050
end
GO
/****** Object:  StoredProcedure [dbo].[CalcUsage]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[CalcUsage] 
-- Determine tool list usage of this item 
-- sum up the list of MonthlyUsage's to determine how many of these items 
-- we need for a specific tool list
	@cmId nvarchar(50),
	@procId int,
	@result int OUTPUT
AS
BEGIN
SET NOCOUNT ON
Declare @nPc Integer
Declare @Pc Integer
Declare @nC Integer

--     4 items   -- ti.Quantity
--    --------
--     20 parts  -- (ti.QuantityPerCuttingEdge * ti.NumberOfCuttingEdges) 

--     100       -- (tm.AnnualVolume / 12) = how many parts are needed per month

--     4 items       ? items    = MonthlyUsage
--     -------   X  ---------
--     20 parts     100 parts 

--   if 4 items are needed to make 20 parts then 20 items are needed to make 100 parts
-- 	 (ti.Quantity * (tm.AnnualVolume/12)) / (ti.QuantityPerCuttingEdge * ti.NumberOfCuttingEdges) 
    
-- Not part specific  
-- consumable means the item has a tool life
select @nPc = sumMonthlyUsage 
from (
SELECT   
 case 
	when sum(MonthlyUsage) is null then cast(0.0 as decimal(18,2)) 
	else ceiling(sum(MonthlyUsage))
  end as sumMonthlyUsage  
from (
SELECT 
(ti.Quantity * (tm.AnnualVolume/12.0)) / (ti.QuantityPerCuttingEdge * ti.NumberOfCuttingEdges) 
as MonthlyUsage -- how many items are needed to make tm.AnnualVolume/12 parts
FROM [TOOLLIST ITEM] as ti 
inner join [TOOLLIST TOOL] as tt on ti.toolid=tt.toolid
INNER JOIN [TOOLLIST MASTER] as tm ON tt.PROCESSID = tm.PROCESSID 
where tt.PartSpecific = 0 and ti.Consumable = 1 and ti.CRIBTOOLID = @cmId 
AND ti.PROCESSID = @procId 
) as usage
) as sumQ

-- part specific 
-- consumable
select @Pc = sumMonthlyUsage
from (
SELECT   
 case 
	when sum(MonthlyUsage) is null then cast(0.0 as decimal(18,2)) 
	else ceiling(sum(MonthlyUsage))
  end as sumMonthlyUsage  
from
(
SELECT 
(ti.Quantity * (tt.AdjustedVolume/12)) / (ti.QuantityPerCuttingEdge * ti.NumberOfCuttingEdges) 
as MonthlyUsage -- how many items are needed to make tt.AdjustedVolume/12 parts
FROM [TOOLLIST ITEM] as ti 
inner join [TOOLLIST TOOL] as tt on ti.toolid=tt.toolid
INNER JOIN [TOOLLIST MASTER] as tm ON tt.PROCESSID = tm.PROCESSID 
where tt.PartSpecific = 1 and ti.Consumable = 1 and ti.CRIBTOOLID = @cmId 
AND ti.PROCESSID = @procId 
) as usage
) as sumQ

-- not consumable means the item is not perishable and the quantity field represents the number of the item
-- we need on hand to cnc the part
-- monthly usage is a misnomer in this case
select @nC = sumMonthlyUsage
from (
SELECT   
 case 
	when sum(MonthlyUsage) is null then cast(0.0 as decimal(18,2)) 
	else ceiling(sum(MonthlyUsage))
  end as sumMonthlyUsage  
from (
SELECT ti.Quantity as MonthlyUsage  
FROM [TOOLLIST ITEM] as ti 
inner join [TOOLLIST TOOL] as tt on ti.toolid=tt.toolid
INNER JOIN [TOOLLIST MASTER] as tm ON tt.PROCESSID = tm.PROCESSID 
where ti.Consumable = 0 and ti.CRIBTOOLID = @cmId 
AND ti.PROCESSID = @procId 
) as usage
) as sumQ

set nocount off
Set @result = @nPc + @Pc + @nC
Select @result 
end


GO
/****** Object:  StoredProcedure [dbo].[CopyProcessForChanges]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[CopyProcessForChanges] 
	-- Add the parameters for the stored procedure here
	@oldPid Integer
AS
BEGIN
SET NOCOUNT ON

DECLARE @RC int
EXECUTE @RC = [dbo].[CopyProcessMaster] @oldPid
Declare @newPid Integer
Set @newPid = (SELECT max(ProcessID) FROM [TOOLLIST MASTER]) 
EXECUTE @RC = [dbo].[CopyToolListPlants] @oldPid,@newPid
EXECUTE @RC = [dbo].[CopyToolListPartNumbers] @oldPid,@newPid
EXECUTE @RC = [dbo].[CopyToolListMisc] @oldPid,@newPid 
EXECUTE @RC = [dbo].[CopyToolListFixture] @oldPid,@newPid 
EXECUTE @RC = [dbo].[CopyToolListRev] @oldPid,@newPid
EXECUTE @RC = [dbo].[CopyToolListToolsAndItems] @oldPid,@newPid
set nocount off
select processid,itemId, toolId, case when ItemImage is null then 0 else 1 end as itemImage from [toollist item] where  processid = @newPid
END


GO
/****** Object:  StoredProcedure [dbo].[CopyProcessMaster]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[CopyProcessMaster] 
	-- Add the parameters for the stored procedure here
	@pid int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	insert into [ToolList Master] select 
			[PartFamily]
           ,[OperationNumber]
           ,[OperationDescription]
           ,[Obsolete]
           ,[Customer]
           ,[AnnualVolume]
           ,[Released]
           ,[MultiTurret]
           ,@pid
           ,0
           ,[OriginalProcessID]
           ,[FixtureDrawing] from [ToolList Master] where ProcessID=@pid;

END


GO
/****** Object:  StoredProcedure [dbo].[CopyToolListFixture]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[CopyToolListFixture] 
	-- Add the parameters for the stored procedure here
	@oldPid Integer,
	@newPid Integer
AS
BEGIN
insert into [ToolList Fixture] 
SELECT @newPid
      ,[Manufacturer]
      ,[ToolType]
      ,[ToolDescription]
      ,[AdditionalNotes]
      ,[Quantity]
      ,[CribToolID]
      ,[DetailNumber]
      ,[ToolbossStock]
  FROM [ToolList Fixture] WHERE PROCESSID = @oldPid
end


GO
/****** Object:  StoredProcedure [dbo].[CopyToolListMisc]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CopyToolListMisc] 
	-- Add the parameters for the stored procedure here
	@oldPid Integer,
	@newPid Integer
AS
BEGIN
insert into [ToolList Misc] 
SELECT @newPid
      ,[Manufacturer]
      ,[ToolType]
      ,[ToolDescription]
      ,[Consumable]
      ,[QuantityPerCuttingEdge]
      ,[AdditionalNotes]
      ,[NumberofCuttingEdges]
      ,[Quantity]
      ,[CribToolID]
      ,[ToolbossStock]
  FROM [ToolList Misc] WHERE PROCESSID = @oldPid
end


GO
/****** Object:  StoredProcedure [dbo].[CopyToolListPartNumbers]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[CopyToolListPartNumbers] 
	-- Add the parameters for the stored procedure here
	@oldPid Integer,
	@newPid Integer
AS
BEGIN
insert into [ToolList PartNumbers] SELECT @newPid,PartNumbers FROM [TOOLLIST PARTNUMBERS] WHERE PROCESSID = @oldPid
end


GO
/****** Object:  StoredProcedure [dbo].[CopyToolListPlants]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CopyToolListPlants] 
	@oldPid Integer,
	@newPid Integer
AS
BEGIN
insert into [ToolList Plant] SELECT @newPid,plant FROM [TOOLLIST PLANT] WHERE PROCESSID = @oldPid
end


GO
/****** Object:  StoredProcedure [dbo].[CopyToolListRev]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CopyToolListRev] 
	-- Add the parameters for the stored procedure here
	@oldPid Integer,
	@newPid Integer
AS
BEGIN
insert into [ToolList Rev] 
SELECT @newPid
      ,[Revision]
      ,[Revision Description]
      ,[Revision Date]
      ,[Revision By]
  FROM [ToolList Rev] WHERE PROCESSID = @oldPid
end


GO
/****** Object:  StoredProcedure [dbo].[CopyToolListToolsAndItems]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[CopyToolListToolsAndItems] 
	@oldPid Integer,
	@newPid Integer
AS
BEGIN
SET NOCOUNT ON

--DECLARE @oldPid Integer
--set @oldPid = 81
--DECLARE @newPid Integer
--set @newPid = 84
DECLARE @vToolID Integer
DECLARE @vProcessID Integer
DECLARE @vToolNumber Integer
DECLARE @vOpDescription nvarchar(75)
DECLARE @vAlternate bit
DECLARE @vPartSpecific bit
DECLARE @vAdjustedVolume Integer
DECLARE @vToolOrder Integer
DECLARE @vTurret char(1)
DECLARE @vToolLength decimal(18,3)
DECLARE @vOffsetNumber Integer
DECLARE @newToolId Integer
DECLARE @newItemId Integer
DECLARE db_cursor CURSOR FOR  
SELECT * 
  FROM [dbo].[ToolList Tool] WHERE PROCESSID = @oldPid
OPEN db_cursor   
FETCH NEXT FROM db_cursor INTO  
	   @vToolID
      ,@vProcessID
      ,@vToolNumber
      ,@vOpDescription
      ,@vAlternate
      ,@vPartSpecific
      ,@vAdjustedVolume
      ,@vToolOrder
      ,@vTurret
      ,@vToolLength
      ,@vOffsetNumber
WHILE @@FETCH_STATUS = 0   
BEGIN 
--insert 1 tool with new pid
INSERT INTO [TOOLLIST TOOL] SELECT 
      @newPid
      ,@vToolNumber
      ,@vOpDescription
      ,@vAlternate
      ,@vPartSpecific
      ,@vAdjustedVolume
      ,@vToolOrder
      ,@vTurret
      ,@vToolLength
      ,@vOffsetNumber
Set @newToolId = (SELECT IDENT_CURRENT ('TOOLLIST TOOL') AS Current_Identity) 
--insert a copy of all toollist items 
INSERT INTO [ToolList Item] SELECT 
      @newPid
      ,@newToolId
      ,[ToolType]
      ,[ToolDescription]
      ,[Manufacturer]
      ,[Consumable]
      ,[QuantityPerCuttingEdge]
      ,[AdditionalNotes]
      ,[NumberofCuttingEdges]
      ,[Quantity]
      ,[CribToolID]
      ,[Regrindable]
      ,[QtyPerRegrind]
      ,[NumOfRegrinds]
      ,[ParentItem]
      ,[ToolbossStock]
      ,[ItemImage]
  FROM [dbo].[ToolList Item]
WHERE ToolID = @vToolID

--Some tools may be specific to certain part numbers
INSERT INTO [TOOLLIST TOOLPARTNUMBER] SELECT 
       @newToolId
      ,[PartNumber]
  FROM [ToolList ToolPartNumber]
WHERE ToolID = @vToolID


   FETCH NEXT FROM db_cursor INTO 
	   @vToolID
      ,@vProcessID
      ,@vToolNumber
      ,@vOpDescription
      ,@vAlternate
      ,@vPartSpecific
      ,@vAdjustedVolume
      ,@vToolOrder
      ,@vTurret
      ,@vToolLength
      ,@vOffsetNumber
END   

CLOSE db_cursor   
DEALLOCATE db_cursor
End

GO
/****** Object:  StoredProcedure [dbo].[GetCNCState]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetCNCState]
AS
begin
	SELECT * from cncstate 
end

GO
/****** Object:  StoredProcedure [dbo].[GetToolItems]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetToolItems]
AS
begin
	SELECT * from toolitems 
end

GO
/****** Object:  StoredProcedure [dbo].[MultiPN]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[MultiPN]
as
-- start lv 7  - 30 parts
select AddedDesc.Plant, AddedDesc.PartNumber, AddedDesc.Descr from (
-- start lv 6  - 30 parts
select AddedPlant.ProcessID, AddedPlant.Plant, AddedPlant.PartNumber, 
SUBSTRING(TLMaster.Customer + ' - ' + TLMaster.PartFamily + ' - ' + TLMaster.OperationDescription, 1, 70) AS Descr 
from (
-- start lv 5  - 30 parts
select TLPlant.ProcessID, TLPlant.Plant, AddedPN.PartNumber from (
-- start lv 4  - 30 parts
select PN.ProcessID, PN.PartNumbers as PartNumber from (
-- start lv 3  - 30 parts/6 process 
select PartNumberCnt, ProcessID from (
-- start lv 2 - 640 
select count(*) as PartNumberCnt, ProcessID from (
-- start lv 1 - 664
SELECT DISTINCT [ToolList Master].ProcessID, [ToolList PartNumbers].PartNumbers AS PartNumber 
FROM [ToolList Master] LEFT OUTER JOIN
     [ToolList PartNumbers] ON [ToolList Master].ProcessID = [ToolList PartNumbers].ProcessID
WHERE ([ToolList Master].Obsolete = 0) 
-- end lv 1
) as WithPN
group by processId
-- end lv 2
) as CntPN
where CntPN.PartNumberCnt > 1
-- end lv 3
) as MultiPN
left outer join [ToolList PartNumbers] as PN 
ON MultiPN.ProcessID = PN.ProcessID
-- end lv 4
) as AddedPN
left outer join [ToolList Plant] as TLPlant 
ON AddedPN.ProcessID = TLPlant.ProcessID
-- end lv 5
) as AddedPlant
left outer join [ToolList Master] as TLMaster 
ON AddedPlant.ProcessID = TLMaster.ProcessID
-- end lv 6
) as AddedDesc
group by AddedDesc.Plant, AddedDesc.PartNumber, AddedDesc.Descr
order by AddedDesc.Descr
-- end lv 7

GO
/****** Object:  StoredProcedure [dbo].[tmpGetDistinctToolLists]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--///////////////////////////////////////////////////////////////////////////////////
-- Can delete me
--///////////////////////////////////////////////////////////////////////////////////
create PROCEDURE [dbo].[tmpGetDistinctToolLists] 
AS
BEGIN
	select Customer,PartFamily,OperationDescription    
	from bvDistinctToollists
end

GO
/****** Object:  Table [dbo].[ActiveToolLists]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ActiveToolLists](
	[ProcessID] [int] NOT NULL,
	[PartNumber] [nvarchar](50) NOT NULL,
	[Description] [nvarchar](50) NOT NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[btDistinctToolLists]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[btDistinctToolLists](
	[OriginalProcessId] [int] NULL,
	[ProcessId] [int] NULL,
	[Customer] [nvarchar](50) NULL,
	[PartFamily] [nvarchar](50) NULL,
	[OperationDescription] [nvarchar](250) NULL,
	[PartNumber] [nvarchar](50) NULL,
	[Description] [nvarchar](356) NULL,
	[CustPartFamily] [nvarchar](103) NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[btItemsPerPart]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[btItemsPerPart](
	[partNumber] [nvarchar](50) NULL,
	[itemNumber] [nvarchar](50) NULL,
	[itemsPerPart] [numeric](38, 27) NULL,
	[toolOps] [varchar](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[btObsToolListItems]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[btObsToolListItems](
	[itemNumber] [nvarchar](50) NULL,
	[opDescList] [varchar](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[btToolListItems]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[btToolListItems](
	[itemNumber] [nvarchar](50) NULL,
	[opDescList] [varchar](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[btToolListPartItems]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[btToolListPartItems](
	[partNumber] [nvarchar](50) NULL,
	[itemNumber] [nvarchar](50) NULL,
	[itemsPerPart] [numeric](38, 27) NULL,
	[toolOps] [varchar](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[cncstate]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[cncstate](
	[cnc] [nvarchar](50) NOT NULL,
	[date] [datetime] NULL,
	[job] [nvarchar](50) NULL,
	[shift] [int] NULL,
	[cycles] [int] NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[INVENT]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[INVENT](
	[ItemNumber] [varchar](12) NOT NULL,
	[ItemClass] [varchar](15) NULL,
	[UDFGLOBALTOOL] [varchar](20) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[NotifyMe]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[NotifyMe](
	[ToolListUser] [char](50) NOT NULL,
	[DeptMgrApprovalNeeded] [bit] NOT NULL DEFAULT (0),
	[BuyerApprovalNeeded] [bit] NOT NULL DEFAULT (0),
	[BuyerCompleted] [bit] NOT NULL DEFAULT (0)
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[TestImage]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TestImage](
	[Image] [image] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[ToolBoss]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[ToolBoss](
	[PLANT] [int] NOT NULL,
	[DBLOCATION] [char](100) NOT NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[toolitems]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[toolitems](
	[itemnumber] [varchar](12) NOT NULL,
	[description1] [varchar](50) NULL,
	[itemclass] [varchar](15) NOT NULL,
	[UDFGLOBALTOOL] [varchar](20) NOT NULL,
	[cost] [numeric](19, 4) NOT NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[ToolList Change Action Text]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ToolList Change Action Text](
	[ActionItemNumber] [int] NULL,
	[ActionItemText] [nvarchar](250) NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[ToolList Change Actions]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ToolList Change Actions](
	[ActionID] [int] IDENTITY(1,1) NOT NULL,
	[ItemChangeID] [int] NULL,
	[ProcessChangeID] [int] NULL,
	[ActionItem] [int] NULL,
	[Complete] [bit] NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[ToolList Change Disposition]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[ToolList Change Disposition](
	[DispMethods] [char](25) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[ToolList Change Items]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[ToolList Change Items](
	[ItemChangeID] [int] IDENTITY(1,1) NOT NULL,
	[ProcessChangeID] [int] NULL,
	[Type] [char](20) NULL,
	[CribmasterID] [char](20) NULL,
	[NewStatus] [char](50) NULL,
	[NewPlants] [char](20) NULL,
	[OldPlants] [char](20) NULL,
	[NewVolume] [int] NULL,
	[OldVolume] [int] NULL,
	[DispositionMethod] [char](20) NULL,
	[Comments] [nvarchar](100) NULL,
	[Completed] [bit] NULL,
	[Approved] [bit] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[ToolList Change Master]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ToolList Change Master](
	[ProcessChangeID] [int] IDENTITY(1,1) NOT NULL,
	[ProcessID] [int] NULL,
	[Complete] [bit] NULL,
	[Comments] [nvarchar](250) NULL,
	[Engineer] [text] NULL,
	[DateInitiated] [datetime] NULL,
	[DateComplete] [datetime] NULL,
	[Approved] [bit] NULL,
	[InitialRelease] [bit] NULL,
	[OldProcessID] [int] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[ToolList Email]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[ToolList Email](
	[Manager] [char](50) NULL,
	[Buyer] [char](50) NULL,
	[Engineer1] [char](50) NULL,
	[Engineer2] [char](70) NULL,
	[Engineer3] [char](70) NULL,
	[Engineer4] [char](70) NULL,
	[Engineer5] [char](70) NULL,
	[Engineer6] [char](70) NULL,
	[Engineer7] [char](70) NULL,
	[Engineer8] [char](70) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[ToolList Fixture]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ToolList Fixture](
	[ItemID] [int] IDENTITY(1,1) NOT NULL,
	[ProcessID] [int] NULL,
	[Manufacturer] [nvarchar](50) NULL,
	[ToolType] [nvarchar](50) NULL,
	[ToolDescription] [nvarchar](50) NULL,
	[AdditionalNotes] [nvarchar](150) NULL,
	[Quantity] [int] NULL,
	[CribToolID] [nvarchar](50) NULL,
	[DetailNumber] [int] NULL,
	[ToolbossStock] [bit] NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[ToolList Item]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ToolList Item](
	[ItemID] [int] IDENTITY(1,1) NOT NULL,
	[ProcessID] [int] NULL,
	[ToolID] [int] NULL,
	[ToolType] [nvarchar](50) NULL,
	[ToolDescription] [nvarchar](75) NULL,
	[Manufacturer] [nvarchar](50) NULL,
	[Consumable] [bit] NULL,
	[QuantityPerCuttingEdge] [int] NULL,
	[AdditionalNotes] [nvarchar](150) NULL,
	[NumberofCuttingEdges] [int] NULL,
	[Quantity] [int] NULL,
	[CribToolID] [nvarchar](50) NULL,
	[Regrindable] [bit] NULL,
	[QtyPerRegrind] [int] NULL,
	[NumOfRegrinds] [int] NULL,
	[ParentItem] [int] NULL,
	[ToolbossStock] [bit] NULL,
	[ItemImage] [image] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[ToolList Master]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[ToolList Master](
	[ProcessID] [int] IDENTITY(1,1) NOT NULL,
	[PartFamily] [nvarchar](50) NULL,
	[OperationNumber] [int] NULL,
	[OperationDescription] [nvarchar](250) NULL,
	[Obsolete] [bit] NULL,
	[Customer] [nvarchar](50) NULL,
	[AnnualVolume] [int] NULL,
	[Released] [bit] NULL,
	[MultiTurret] [bit] NULL,
	[RevOfProcessID] [int] NULL,
	[RevInProcess] [bit] NULL,
	[OriginalProcessID] [int] NULL,
	[FixtureDrawing] [char](100) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[ToolList Misc]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ToolList Misc](
	[ItemID] [int] IDENTITY(1,1) NOT NULL,
	[ProcessID] [int] NULL,
	[Manufacturer] [nvarchar](50) NULL,
	[ToolType] [nvarchar](50) NULL,
	[ToolDescription] [nvarchar](50) NULL,
	[Consumable] [bit] NULL,
	[QuantityPerCuttingEdge] [int] NULL,
	[AdditionalNotes] [nvarchar](150) NULL,
	[NumberofCuttingEdges] [int] NULL,
	[Quantity] [int] NULL,
	[CribToolID] [nvarchar](50) NULL,
	[ToolbossStock] [bit] NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[ToolList PartNumbers]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ToolList PartNumbers](
	[ProcessID] [int] NULL,
	[PartNumbers] [nvarchar](50) NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[ToolList Plant]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ToolList Plant](
	[ProcessID] [int] NULL,
	[Plant] [int] NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[ToolList Plant List]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ToolList Plant List](
	[Plant] [int] NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[ToolList Rev]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ToolList Rev](
	[ProcessID] [int] NULL,
	[RevisionID] [int] IDENTITY(1,1) NOT NULL,
	[Revision] [int] NULL,
	[Revision Description] [nvarchar](100) NULL,
	[Revision Date] [smalldatetime] NULL,
	[Revision By] [nvarchar](50) NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[ToolList Tool]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[ToolList Tool](
	[ToolID] [int] IDENTITY(1,1) NOT NULL,
	[ProcessID] [int] NULL,
	[ToolNumber] [int] NULL,
	[OpDescription] [nvarchar](75) NULL,
	[Alternate] [bit] NOT NULL,
	[PartSpecific] [bit] NOT NULL,
	[AdjustedVolume] [int] NULL,
	[ToolOrder] [int] NULL,
	[Turret] [char](1) NULL,
	[ToolLength] [decimal](18, 3) NULL,
	[OffsetNumber] [int] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[ToolList Toolboss Stock Items]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[ToolList Toolboss Stock Items](
	[ItemClass] [char](20) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[ToolList ToolPartNumber]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ToolList ToolPartNumber](
	[PartID] [int] IDENTITY(1,1) NOT NULL,
	[ToolID] [int] NULL,
	[PartNumber] [nvarchar](50) NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[ToolList Users]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ToolList Users](
	[Admin] [nvarchar](50) NULL,
	[DeptMgr] [nvarchar](50) NULL,
	[Buyer] [nvarchar](50) NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[ToolList Version]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[ToolList Version](
	[Version] [char](10) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[ToolListItems]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[ToolListItems](
	[originalprocessid] [int] NULL,
	[processid] [int] NULL,
	[partNumber] [nvarchar](50) NULL,
	[itemNumber] [nvarchar](50) NULL,
	[allToolOps] [varchar](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[toollists]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[toollists](
	[Originalprocessid] [int] NULL,
	[processid] [int] NULL,
	[customer] [nvarchar](50) NULL,
	[partfamily] [nvarchar](50) NULL,
	[OperationDescription] [nvarchar](250) NULL,
	[descript] [nvarchar](356) NULL,
	[descr] [nvarchar](103) NULL,
	[partNumber] [nvarchar](50) NULL,
	[Plant] [int] NULL
) ON [PRIMARY]

GO
/****** Object:  View [dbo].[bvToolListItemsLv1]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--////////////////////////////////////////////////
-- Each toolid/item could have a different items
-- per part ratio, but the toolbosses dont currently
-- have an opsdescription in the restrictions2 table
-- so we have to choose the toolids items per part ratio
-- for costing purposes.
-- /////////////////////////////////////////////////
create View [dbo].[bvToolListItemsLv1] 
AS
select lv2.*,ti.itemClass,ti.UDFGLOBALTOOL,ti.cost
from
(
	select tl.partNumber,tl.Description as tlDescription, lv1.*
	from
	(
		SELECT tm.OriginalProcessID, tm.processid,CribToolID as itemNumber,
		tt.ToolID, tt.processid as ttpid, tt.toolNumber,tt.OpDescription, 
		ti.itemid,ti.tooltype,ti.tooldescription,
		Quantity,
		AnnualVolume,
		AdjustedVolume,
		QuantityPerCuttingEdge,
		NumberOfCuttingEdges,
		'item' as itemType,partspecific,
		Consumable, 
		case 
			when toolbossStock is null then 0
			when toolbossStock = 0 then 0
			when toolbossStock = 1 then 1
			else 0
		end as toolbossStock,
		case
			when (Quantity=0) or (NumberofCuttingEdges =0) or (QuantityPerCuttingEdge=0) or
			(Quantity is null) or (NumberofCuttingEdges is null) or (QuantityPerCuttingEdge is null)
				then 0
			when (Consumable = 1)
				then 1/((QuantityPerCuttingEdge/cast( ti.quantity as numeric(19,8)))*NumberofCuttingEdges)
			when Consumable = 0 then 0.0
		end itemsPerPart, 
		case 
			when tt.PartSpecific = 0 and ti.Consumable = 1 then (Quantity * (AnnualVolume/12.0)) / cast((QuantityPerCuttingEdge * NumberOfCuttingEdges) as numeric(19,8)) 
			when tt.PartSpecific = 1 and ti.Consumable = 1  then (ti.Quantity * (tt.AdjustedVolume/12)) / cast((QuantityPerCuttingEdge * NumberOfCuttingEdges) as numeric(19,8)) 
			when ti.Consumable = 0 then ti.Quantity
		end MonthlyUsage,  
		case 
			when tt.PartSpecific = 0 and ti.Consumable = 1 then (ti.Quantity * (tm.AnnualVolume/365.0)) / cast((QuantityPerCuttingEdge * NumberOfCuttingEdges) as numeric(19,8)) 
			when tt.PartSpecific = 1 and ti.Consumable = 1  then (ti.Quantity * (tt.AdjustedVolume/365)) / cast((QuantityPerCuttingEdge * NumberOfCuttingEdges) as numeric(19,8))
			when ti.Consumable = 0 then ti.Quantity/30
		end DailyUsage  
		FROM [TOOLLIST ITEM] as ti 
		-- when a tool gets deleted the toollist item remains?
		inner join [TOOLLIST TOOL] as tt on ti.toolid=tt.toolid
		INNER JOIN 
		(
			-- these are the toollist which are added to the toolbosses
			select tm.* 
			from
			btDistinctToolLists tb
			inner join
			[ToolList Master] tm
			on tb.ProcessId=tm.ProcessID
			--731
		) as tm 
		ON tt.PROCESSID = tm.PROCESSID 
		--30432
	union
		SELECT tm.originalprocessid, tm.processid,CribToolID as itemNumber, 
		0 as ToolID, 0 as ttpid, 0 as toolNumber,'Fixture' as OpDescription, 
		tf.itemid,tf.tooltype,tf.tooldescription,  
		Quantity,AnnualVolume,0 as AdjustedVolume,0 as QuantityPerCuttingEdge,0 as NumberOfCuttingEdges,
		'fixture' as itemType,0 as partspecific, 0 as Consumable, 
		case 
			when toolbossStock is null then 0
			when toolbossStock = 0 then 0
			when toolbossStock = 1 then 1
			else 0
		end as toolbossStock,
		cast(0.0 as numeric(19,8)) itemsPerPart, 
		0 as MonthlyUsage, 0 as DailyUsage
		FROM [TOOLLIST Fixture] as tf 
		INNER JOIN 
		(
			-- these are the toollist which are added to the toolbosses
			select tm.* 
			from
			btDistinctToolLists tb
			inner join
			[ToolList Master] tm
			on tb.ProcessId=tm.ProcessID
			--731
		) as tm 
		ON tf.PROCESSID = tm.PROCESSID 
		--1648
	union
		SELECT tm.OriginalProcessID, tm.processid,CribToolID as itemNumber, 
		0 as ToolID, 0 as ttpid, 0 as toolNumber,'Misc' as OpDescription, 
		m.itemid,m.tooltype,m.tooldescription,  
		Quantity,AnnualVolume,0 as AdjustedVolume,QuantityPerCuttingEdge,NumberOfCuttingEdges,
		'misc' as itemType, 0 as partspecific,m.Consumable, 
		case 
			when toolbossStock is null then 0
			when toolbossStock = 0 then 0
			when toolbossStock = 1 then 1
			else 0
		end as toolbossStock,
		case
			when (Quantity=0) or (NumberofCuttingEdges =0) or (QuantityPerCuttingEdge=0) or
			(Quantity is null) or (NumberofCuttingEdges is null) or (QuantityPerCuttingEdge is null)
				then 0
			when (Consumable = 1)
				then 1/((QuantityPerCuttingEdge/cast( quantity as numeric(19,8)))*NumberofCuttingEdges)
			when Consumable = 0 then 0.0
		end itemsPerPart, 
		case 
			when m.Consumable = 1 then (m.Quantity * (tm.AnnualVolume/12.0)) / cast((QuantityPerCuttingEdge * NumberOfCuttingEdges) as numeric(19,8))
			else m.Quantity
		end MonthlyUsage,  
		case 
			when m.Consumable = 1 then (m.Quantity * (tm.AnnualVolume/365.0)) / cast((QuantityPerCuttingEdge * NumberOfCuttingEdges) as numeric(19,8)) 
			else m.Quantity/30
		end DailyUsage  
		FROM [ToolList Misc] as m 
		INNER JOIN 
		(
			-- these are the toollist which are added to the toolbosses
			select tm.* 
			from
			btDistinctToolLists tb
			inner join
			[ToolList Master] tm
			on tb.ProcessId=tm.ProcessID
			--731
		)  
		as tm 
		ON m.PROCESSID = tm.PROCESSID 
		--371
	--32571
	)lv1
	inner join 
	btDistinctToolLists tl
	on lv1.ProcessID=tl.processid
	--32571
)lv2
-- drop items that are not in the crib
inner join
toolitems ti
on lv2.itemNumber=ti.itemnumber
--32438

GO
/****** Object:  View [dbo].[bvListOfActiveApprovedToolLists]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[bvListOfActiveApprovedToolLists]
AS
	select originalprocessid, lv3.processid, customer,partfamily,OperationDescription,descript,descr,subDescript,subDescr  
	from
	(
		-- add extra fields from toollist master
		select lv1.originalprocessid, lv2.processid,
			customer,partfamily,OperationDescription, 
			SUBSTRING(Customer + ' - ' + PartFamily + ' - ' + OperationDescription, 1, 50) subDescript, 
			SUBSTRING(Customer + ' - ' + PartFamily, 1, 50) subDescr, 
			Customer + ' - ' + PartFamily + ' - ' + OperationDescription as descript, 
			Customer + ' - ' + PartFamily descr, 
		obsolete,released,revinprocess
		from (
			-- There is often multiple tool lists for a single part number because each operation 
			-- performed on a Part has it's own separate tool list.

			-- When a change is made to a tool list the tool list will be duplicated.
			-- The duplicate will contain the originals processid in its revofprocessid
			-- field.
			--
			-- If someone commits this change by pressing the "create change routing" button  
			-- then the revinprocess field of the original Tool list will change to a 1.
			-- Whenever the ToolList program opens up it always looks at the toollist with the
			-- minimum processid if there is more than one toollist with the same original processid.

			--
			-- If you try to open a tool list that a change has been commited but not
			-- approved by a supervisor,ie. revinprocess of 1, you
			-- will get the following message:  There is an uncompleted change..
			-- it may not be opened until that is complete.

			-- If the change is approved the older version of the tool list is
			-- deleted.
			--  
			-- If the "create change routing" button is never pressed and the tool list
			-- is closed the copy of the tool list will be deleted.  
			-- 
			-- If the "create change routing" button is never pressed and the tool list
			-- is not closed the copy of the tool list will remain in the system. In 
			-- this case if someone else opens the tool list another tool list will be 
			-- created from the tool list with the lowest processid and the previous 
			-- copy will be removed from the database.

			--In picking which tool list to use in cases where there is multiple tool lists 
			-- having the same original processed you should always select the minimum processid 
			-- because the tool list with the higher processID has not been approved by a supervisor.
			select OriginalProcessID, min(processid) processid 
			from
			(
				-- A tool list is not ready to go until it is released.  When a tool list is created 
				-- it will be assigned a processed that will not change until it is “Submitted for Initial Release” 
				-- and has been approved.  Until this time its released field will remain equal to 0.  Once a tool 
				-- list has been approved by a supervisor its release field will change to 1 and will never return 
				-- to 0 during it lifetime.
				-- When a tool list is marked as obsolete it will be greyed out in the tool list program and should 
				-- not be added to tool bosses any longer.  It can be activated again by unchecking the obsolete 
				-- checkbox and going through the change routing process.
				select OriginalProcessID, ProcessID
				from [ToolList Master]
				where released = 1 and obsolete = 0
				--756
			) lv1
			group by OriginalProcessID
			-- 733  weed out uncommited/approved toollist changes
			-- all these processids represent toollists that should be added to the toolbosses 
		) as lv1
		left outer join
		[ToolList Master] as lv2
		on
		lv1.processid = lv2.ProcessID
		-- 733
	) lv3 
	inner join
	(
		-- There will be items on the tool list copies also but we will disregard these by selecting the min(processid)
		-- of the originalprocessid tool list chain.  Only the min(processid) is selected from the lv3 query and the 
		-- left INNER join will ensure no unapproved toollist items gets included here.
		-- All released tool lists have at least one item so this check is probably not necessary to ensure the 
		-- tool lists have items.
		select distinct processid
		from
		(
			select distinct processid 
			from [ToolList Item]
			union
			select distinct processid 
			from [ToolList Misc]
			union
			select distinct processid 
			from [ToolList Fixture]
			--814
		) as lv1
		-- 814
	) lv4
	on lv3.ProcessID = lv4.ProcessID
	-- try to exclude original process id chains that have no items 
	-- All released tool lists have at least one item so this check is probably not needed.


GO
/****** Object:  View [dbo].[bvToolListsAssignedPN]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create VIEW [dbo].[bvToolListsAssignedPN]
AS
		-- Pick only one part number for each active and approved toollist
		select lv1.Originalprocessid,lv1.processid, 
			customer,partfamily,OperationDescription,descript,descr,subDescript,subDescr,partNumber 
		from
		(
			select * from bvListOfActiveApprovedToolLists
			-- 733  
		) lv1
		inner join
		(
			-- Engineering sometimes adds more than one part number on a tool list
			-- we must pick one and drop the rest.  Tool lists with multiple Part numbers
			-- will show up on the Multi PN Tool List report. 
			select  ProcessID, MAX(PartNumbers) AS PartNumber
			FROM   [ToolList PartNumbers]
			GROUP BY ProcessID
		) lv2
		on lv1.ProcessID = lv2.ProcessID
		-- tool lists with no part numbers assigned have been dropped
		--732

GO
/****** Object:  View [dbo].[bvToolListsInPlants]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create VIEW [dbo].[bvToolListsInPlants]
AS
	select lv1.Originalprocessid,lv1.processid, 
		lv1.customer,lv1.partfamily,lv1.OperationDescription,
		lv1.descript,lv1.descr,	
		lv1.subDescript,lv1.subDescr,
		lv1.partNumber,tp.Plant 

	from
	( 
		select * from bvToolListsAssignedPN
		--732
	) lv1
	INNER JOIN
	[ToolList Plant] AS tp 
	ON lv1.ProcessID = tp.ProcessID

GO
/****** Object:  View [dbo].[bvToolListItemsInPlants]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--///////////////////////////////////////////////////////////////////////////////
-- This view does not take into consideration the [ToolList Toolboss Stock Items]
-- table which lists the item classes to be stocked in the toolbosses. See
-- bvToolBossItemsInPlants to determine items to be stocked in the ToolBosses.
-- This list would be appropriate to list restrictions for the Cribmaster if you
-- grouped the recordset on all fields except plant.
--///////////////////////////////////////////////////////////////////////////////
create view [dbo].[bvToolListItemsInPlants]
as
select distinct tl.originalprocessid,tl.processid,tl.descript,tl.partNumber,tl.plant,
lv1.itemNumber,lv1.itemClass,lv1.UDFGLOBALTOOL,lv1.toolbossStock  
from bvToolListsInPlants tl
inner join
bvToolListItemsLv1 lv1
ON tl.processid = lv1.ProcessID
where lv1.UDFGLOBALTOOL <> 'YES'
--27838
union
	-- 796 select count(*) from bvToolListsInPlants
	select tl.originalprocessid,tl.processid,tl.descript,tl.partNumber,tl.plant
	,ti.itemNumber, ti.itemclass, ti.UDFGLOBALTOOL, 0 as toolbossStock 
	FROM  toolitems ti
	CROSS JOIN
	bvToolListsInPlants tl
	WHERE (ti.UDFGLOBALTOOL = 'YES')

GO
/****** Object:  View [dbo].[bvToolListItemsLv2]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
---------------------------------------------
-- simplier version
-- ToolList items that are in plants with Tool 
-- Ops description list
-----------------------------------------------
create view [dbo].[bvToolListItemsLv2] 
as
-- ToolList items that are in plants with Tool
SELECT originalprocessid,processid, partNumber, itemNumber,
	isnull(SUBSTRING(
		opDesclist.xmlDoc.value('.', 'varchar(max)'),
		6, 10000
	),'Misc,Fixture, or Global') AS ToolOps
FROM  
(
	select distinct originalprocessid,processid, partNumber, itemNumber
	from bvToolListItemsInPlants 
	--28333
)
tli
--28328
cross apply(
	select ',<br>' +  tlDescription + ', ' + ca1.OpDescription + ', ' + tooldescription as ListItem
	from 
	(
			select ti.processId,ti.CribToolID as itemNumber,ti.tooldescription,
			tt.OpDescription,
			(tm.Customer + '/' + tm.PartFamily + '/' + tm.OperationDescription) tlDescription
			FROM [TOOLLIST ITEM] as ti 
			-- when a tool gets deleted the toollist item remains?
			-- we don't want the toollist item if it is not on a toollist tool
			inner join [TOOLLIST TOOL] as tt on ti.toolid=tt.toolid
			inner join [TOOLLIST Master] as tm on tm.ProcessID=ti.ProcessID
			--34946
	) ca1
	where tli.processId=ca1.processId and tli.itemNumber=ca1.itemNumber
	order by ca1.OpDescription
	for xml path(''), type
) as opDesclist(xmlDoc)
--28328


GO
/****** Object:  View [dbo].[bvDistinctToolLists]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[bvDistinctToolLists]
as
-- Remove duplicates only differing in plant
select OriginalProcessId,ProcessId,
Customer,PartFamily,OperationDescription,PartNumber,descript Description,descr CustPartFamily
from
bvToolListsInPlants
group by 
OriginalProcessId,ProcessId,
Customer,PartFamily,OperationDescription,PartNumber,Descript,descr


GO
/****** Object:  View [dbo].[VMonthlyUsage]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create View [dbo].[VMonthlyUsage] 
-- Determine combined tool list usage of this item 
AS
	SELECT CribToolID,tm.processid,(tm.Customer + '/' + tm.PartFamily + '/' + tm.OperationDescription) tlDescription , 
	tt.ToolID, ti.itemid,ti.tooldescription,tt.OpDescription,	 
	 case 
		when tt.PartSpecific = 0 and ti.Consumable = 1 then (ti.Quantity * (tm.AnnualVolume/12.0)) / (ti.QuantityPerCuttingEdge * ti.NumberOfCuttingEdges) 
		when tt.PartSpecific = 1 and ti.Consumable = 1  then (ti.Quantity * (tt.AdjustedVolume/12)) / (ti.QuantityPerCuttingEdge * ti.NumberOfCuttingEdges) 
		when ti.Consumable = 0 then ti.Quantity
	  end MonthlyUsage  
	FROM [TOOLLIST ITEM] as ti 
	inner join [TOOLLIST TOOL] as tt on ti.toolid=tt.toolid
	INNER JOIN 
	(
		select tmin.* from 
		bvDistinctToolLists tl
		inner join
		[ToolList Master] tmin
		on tl.ProcessId = tmin.processid
		--731
	)tm
	ON tt.PROCESSID = tm.PROCESSID 
--30467	


GO
/****** Object:  View [dbo].[VTBMonthlyUsage]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create View [dbo].[VTBMonthlyUsage] 
as
select 
	ISNULL(lv1.CribToolID,'none') as CribToolID,
	case 
		when TLMonthlyUsage is null then cast(0.0 as decimal(18,2)) 
		else cast(TLMonthlyUsage as decimal(18,2)) 
	end as TLMonthlyUsage, 
	isnull(SUBSTRING(
		list.xmlDoc.value('.', 'varchar(max)'),
		6, 10000
	),'Misc,Fixture,or Global') AS ToolLists
from
(
	select CribToolID, cast(sum(MonthlyUsage) as decimal(18,2)) TLMonthlyUsage
	from VMonthlyUsage vmu
	group by cribtoolid
) lv1
cross apply(
	select ',<br>'+ rVMonthlyUsage.DescUsage as ListItem
	from 
	(
		select CribToolID,tlDescription, sum(MonthlyUsage) MonthlyUsage,
		 tlDescription + ', ' + OpDescription + ', ' + 'Usage:' + cast(cast(sum(MonthlyUsage) as decimal(18,2)) as varchar(max)) 
		as DescUsage 
		from VMonthlyUsage vmu
		group by CribToolID,tlDescription,OpDescription,tooldescription
	) rVMonthlyUsage
	where lv1.cribtoolid=rVMonthlyUsage.cribtoolid
	order by rVMonthlyUsage.DescUsage
	for xml path(''), type
) as list(xmlDoc)

GO
/****** Object:  View [dbo].[bvMonthlyUsageLv1]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--/////////////////////////////////////////
-- Determine tool list items monthly usage 
--/////////////////////////////////////////
create View [dbo].[bvMonthlyUsageLv1] 
-- Determine combined tool list usage of this item 
AS
	SELECT CribToolID,tm.processid,(tm.Customer + '/' + tm.PartFamily + '/' + tm.OperationDescription) tlDescription , 
	tt.ToolID, ti.itemid,ti.tooldescription,tt.OpDescription,	 
	 case 
		when tt.PartSpecific = 0 and ti.Consumable = 1 then (ti.Quantity * (tm.AnnualVolume/12.0)) / (ti.QuantityPerCuttingEdge * ti.NumberOfCuttingEdges) 
		when tt.PartSpecific = 1 and ti.Consumable = 1  then (ti.Quantity * (tt.AdjustedVolume/12)) / (ti.QuantityPerCuttingEdge * ti.NumberOfCuttingEdges) 
		when ti.Consumable = 0 then ti.Quantity
	  end MonthlyUsage  
	FROM [TOOLLIST ITEM] as ti 
	inner join [TOOLLIST TOOL] as tt on ti.toolid=tt.toolid
	INNER JOIN 
	(
		select tmin.* from 
		bvDistinctToolLists tl
		inner join
		[ToolList Master] tmin
		on tl.ProcessId = tmin.processid
		--731
	)tm
	ON tt.PROCESSID = tm.PROCESSID 
--30467	

GO
/****** Object:  View [dbo].[bvMonthlyUsageLv2]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--///////////////////////////////////////////
-- Summary of tool list items monthly usage 
--///////////////////////////////////////////
create View [dbo].[bvMonthlyUsageLv2] 
as
select 
	ISNULL(lv1.CribToolID,'none') as CribToolID,
	case 
		when TLMonthlyUsage is null then cast(0.0 as decimal(18,2)) 
		else cast(TLMonthlyUsage as decimal(18,2)) 
	end as TLMonthlyUsage, 
	isnull(SUBSTRING(
		list.xmlDoc.value('.', 'varchar(max)'),
		6, 10000
	),'Misc,Fixture,or Global') AS ToolLists
from
(
	select CribToolID, cast(sum(MonthlyUsage) as decimal(18,2)) TLMonthlyUsage
	from bvMonthlyUsageLv1 vmu
	group by cribtoolid
) lv1
cross apply(
	select ',<br>'+ rVMonthlyUsage.DescUsage as ListItem
	from 
	(
		select CribToolID,tlDescription, sum(MonthlyUsage) MonthlyUsage,
		 tlDescription + ', ' + OpDescription + ', ' + 'Usage:' + cast(cast(sum(MonthlyUsage) as decimal(18,2)) as varchar(max)) 
		as DescUsage 
		from bvMonthlyUsageLv1 vmu
		group by CribToolID,tlDescription,OpDescription,tooldescription
		--1787
	) rVMonthlyUsage
	where lv1.cribtoolid=rVMonthlyUsage.cribtoolid
	order by rVMonthlyUsage.DescUsage
	for xml path(''), type
) as list(xmlDoc)

GO
/****** Object:  View [dbo].[bvObsMonthlyUsageLv1]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--///////////////////////////////////////////////////
-- Determine obsolete tool list items monthly usage 
--///////////////////////////////////////////////////
create View [dbo].[bvObsMonthlyUsageLv1] 
AS
	SELECT CribToolID,tm.processid,(tm.Customer + '/' + tm.PartFamily + '/' + tm.OperationDescription) tlDescription , 
	tt.ToolID, ti.itemid,ti.tooldescription,tt.OpDescription,	 
	 case 
		when tt.PartSpecific = 0 and ti.Consumable = 1 then (ti.Quantity * (tm.AnnualVolume/12.0)) / (ti.QuantityPerCuttingEdge * ti.NumberOfCuttingEdges) 
		when tt.PartSpecific = 1 and ti.Consumable = 1  then (ti.Quantity * (tt.AdjustedVolume/12)) / (ti.QuantityPerCuttingEdge * ti.NumberOfCuttingEdges) 
		when ti.Consumable = 0 then ti.Quantity
	  end MonthlyUsage  
	FROM [TOOLLIST ITEM] as ti 
	inner join [TOOLLIST TOOL] as tt on ti.toolid=tt.toolid
	INNER JOIN 
	(
		select tmin.* from 
		bvObsoleteToolLists tl
		inner join
		[ToolList Master] tmin
		on tl.ProcessId = tmin.processid
		--40
	)tm
	ON tt.PROCESSID = tm.PROCESSID 
--1852	

GO
/****** Object:  View [dbo].[bvObsMonthlyUsageLv2]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--///////////////////////////////////////////////////
-- Summary of obsolete tool list items monthly usage 
--///////////////////////////////////////////////////
create View [dbo].[bvObsMonthlyUsageLv2] 
as
select 
	ISNULL(lv1.CribToolID,'none') as CribToolID,
	case 
		when TLMonthlyUsage is null then cast(0.0 as decimal(18,2)) 
		else cast(TLMonthlyUsage as decimal(18,2)) 
	end as TLMonthlyUsage, 
	isnull(SUBSTRING(
		list.xmlDoc.value('.', 'varchar(max)'),
		6, 10000
	),'Misc,Fixture,or Global') AS ToolLists
from
(
	select CribToolID, cast(sum(MonthlyUsage) as decimal(18,2)) TLMonthlyUsage
	from bvObsMonthlyUsageLv1 vmu
	group by cribtoolid
) lv1
cross apply(
	select ',<br>'+ rVMonthlyUsage.DescUsage as ListItem
	from 
	(
		select CribToolID,tlDescription, sum(MonthlyUsage) MonthlyUsage,
		 tlDescription + ', ' + OpDescription + ', ' + 'Usage:' + cast(cast(sum(MonthlyUsage) as decimal(18,2)) as varchar(max)) 
		as DescUsage 
		from bvObsMonthlyUsageLv1 vmu
		group by CribToolID,tlDescription,OpDescription,tooldescription
		--1787
	) rVMonthlyUsage
	where lv1.cribtoolid=rVMonthlyUsage.cribtoolid
	order by rVMonthlyUsage.DescUsage
	for xml path(''), type
) as list(xmlDoc)



GO
/****** Object:  View [dbo].[bvGetToolListsMultiPn]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create View [dbo].[bvGetToolListsMultiPn]
AS
select lv7.ProcessID,
SUBSTRING(Customer + ' - ' + PartFamily + ' - ' + OperationDescription, 1, 50) descript
from
(
	select lv5.processid,count(*) cnt from
	(
		select originalprocessid, lv3.processid, tldescript as descript 
		from
		(
			-- 718 items
			select lv1.originalprocessid, lv2.processid, obsolete,released,revinprocess,
			SUBSTRING(Customer + ' - ' + PartFamily + ' - ' + OperationDescription, 1, 50) tldescript 
			from (
				select OriginalProcessID, min(processid) processid 
				from [ToolList Master]
				group by OriginalProcessID
				-- 769
			) as lv1
			left outer join
			[ToolList Master] as lv2
			on
			lv1.processid = lv2.ProcessID
			where released = 1 and Obsolete = 0 
		) lv3 
		left outer join
		(
			-- processid with items --
			select distinct processid
			from
			(
				select distinct processid 
				from [ToolList Item]
				union
				select distinct processid 
				from [ToolList Misc]
				union
				select distinct processid 
				from [ToolList Fixture]
			) as lv1
		) lv4
		on lv3.ProcessID = lv4.ProcessID
		where
		 lv4.ProcessID is not null
	) lv5
	--718
	left join
	[ToolList PartNumbers] lv6
	on lv5.ProcessID = lv6.ProcessID
	group by lv5.processid 
	having count(*) >1
) lv6
left join
[ToolList Master] lv7
on
lv6.processid = lv7.processid

GO
/****** Object:  View [dbo].[bvToolListsMultiPn]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[bvToolListsMultiPn]
as
	select bvTL.ProcessID,bvTL.descript,
		SUBSTRING(
			list.xmlDoc.value('.', 'varchar(max)'),
			3, 10000
		) AS PartNumbers,
		SUBSTRING(
			list2.xmlDoc.value('.', 'varchar(max)'),
			3, 10000
		) AS Plants
	from bvGetToolListsMultiPn bvTL
	cross apply(
		select ', '+ PN.PartNumbers as ListItem
		from 
		(
			select * from [ToolList PartNumbers]  
		) PN
		where bvTL.ProcessID=PN.ProcessID
		order by PN.PartNumbers
		for xml path(''), type
	) as list(xmlDoc)
	cross apply(
		select ', '+ Cast(Plant.Plant as varchar) as ListItem
		from 
		(
			select * from [ToolList Plant]  
		) Plant
		where bvTL.ProcessID=Plant.ProcessID
		order by Plant.Plant
		for xml path(''), type
	) as list2(xmlDoc)

GO
/****** Object:  View [dbo].[bvToolBossJobList]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[bvToolBossJobList]
as
		select 
		OriginalProcessID AS JobNumber, 
		subDescript as Descr, 
	--	SUBSTRING(Customer + ' - ' + PartFamily + ' - ' + OperationDescription, 1, 50) descript, 
		partNumber as alias, 
		Plant,
		'SSIS' AS CreatedBy, 
		'6/9/2011' AS DATECREATED, 
		'6/9/2011' AS DATELASTMODIFIED, 
		'SSIS' AS LASTMODIFIEDBY, 
		1 AS JOBENABLE, 
		0 AS DATERANGEENABLE
		from bvToolListsInPlants
		--803

GO
/****** Object:  UserDefinedFunction [dbo].[bfGetToolBossJobList]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create FUNCTION [dbo].[bfGetToolBossJobList]
(  
 @plant int
)
RETURNS TABLE 
AS
RETURN
select * from bvToolBossJobList
where plant = @plant


GO
/****** Object:  View [dbo].[bvToolListItemsLv2byPart]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
---------------------------------------------
-- Monthly Toollist items usage detail 
-- Consumable items only
-- costs are based on annualvolume field
-----------------------------------------------
create view [dbo].[bvToolListItemsLv2byPart] 
as
SELECT partNumber, itemNumber,itemsPerPart,monthlyCost,dailyCost,
	isnull(SUBSTRING(
		opDesclist.xmlDoc.value('.', 'varchar(max)'),
		5, 10000
	),'Misc,Fixture, or Global') AS ToolOps
FROM  
(
	select partNumber, itemNumber,consumable,
	sum(itemsPerPart) as itemsPerPart,
	sum(monthlyUsage*cost) monthlyCost,sum(dailyUsage*cost) dailyCost
	from bvToolListItemsLv1
	group by 
	partNumber, itemNumber,consumable
	having Consumable = 1 
	-- 7085
	--24361
)
tli
--28328
cross apply(
	select '<br>' +  tlDescription + ', ' + ca1.OpDescription + ', ' + tooldescription + 
	'<br>Item Type:' + cast(ItemType as varchar(10)),
	', Consumable:' + cast(Consumable as varchar(10)),
	', PartSpecific:' + cast(PartSpecific as varchar(10)),
	', Quantity Per Tool:' + cast(Quantity as varchar(10)),
	'<br>Annual Volume:' + cast(AnnualVolume as varchar(10)),
	', Adjusted Volume:' + cast(AdjustedVolume as varchar(10)),
	', Quantity Per Cutting Edge:' + cast(QuantityPerCuttingEdge as varchar(10)),
	', Number Of Cutting Edges:' + cast(NumberOfCuttingEdges as varchar(10)),
	'<br>Items Per Part:' + cast(cast(itemsPerPart as numeric(19,8)) as varchar(50)),
	'<br>Monthly Usage:' + cast(cast(monthlyUsage as numeric(19,8)) as varchar(50)) as ListItem
	from 
	(
		select partNumber,itemnumber,tlDescription,
		opDescription,tooldescription,monthlyUsage,
		itemType,Quantity,AnnualVolume,QuantityPerCuttingEdge,NumberOfCuttingEdges,
		Consumable,PartSpecific,AdjustedVolume
		from bvToolListItemsLv1
		--32571
	) ca1
	where tli.partNumber=ca1.partNumber and tli.itemNumber=ca1.itemNumber
	order by ca1.OpDescription
	for xml path(''), type
) as opDesclist(xmlDoc)
--26361
--56sec

GO
/****** Object:  View [dbo].[bvToolListItemsLv3byPart]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-------------------------------------------------
-- PartNumber daily and monthy 
-- budgeted tool cost
-------------------------------------------------
create view [dbo].[bvToolListItemsLv3byPart] 
as
select partNumber,sum(monthlyCost) monthlyCost,sum(dailyCost) dailyCost
from 
bvToolListItemsLv2byPart
group by partNumber
--531
-- 1min 50 sec

GO
/****** Object:  View [dbo].[bvToolListItemsLv2byItem]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-------------------------------------------------
-- Active ToolList items,misc,and fixture detail
-- grouped by item number 
-------------------------------------------------
create view [dbo].[bvToolListItemsLv2byItem] 
as
SELECT itemNumber,monthlyUsage,dailyUsage,
	isnull(SUBSTRING(
		opDesclist.xmlDoc.value('.', 'varchar(max)'),
		5, 10000
	),'Misc,Fixture, or Global') AS ToolOps
FROM  
(
	select itemNumber,sum(monthlyUsage) monthlyUsage,sum(dailyUsage) dailyUsage
	from bvToolListItemsLv1
	group by 
	itemNumber 
	--4652
)
tli
cross apply(
	select '<br>' +  tlDescription + ', ' + ca1.OpDescription + 
	', ' + tooldescription as ListItem
	from 
	(
		select partNumber,itemnumber,tlDescription,
		opDescription,tooldescription,itemsPerPart
		from bvToolListItemsLv1
		--32571
	) ca1
	where tli.itemNumber=ca1.itemNumber
	order by ca1.OpDescription
	for xml path(''), type
) as opDesclist(xmlDoc)
--4652
--56sec

GO
/****** Object:  UserDefinedFunction [dbo].[bfToolListsInPlant]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create FUNCTION [dbo].[bfToolListsInPlant]
(  
 @plant int
)
RETURNS TABLE 
AS
RETURN
	select * from bvToolListsInPlants
	where plant = @plant

GO
/****** Object:  View [dbo].[bvObsToolListItemsLv1]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-------------------------------------------------
-- Obsolete ToolList items,misc,and fixture detail
-------------------------------------------------
create View [dbo].[bvObsToolListItemsLv1] 
AS
	SELECT tm.OriginalProcessID, tm.processid,CribToolID as itemNumber, (tm.Customer + ' / ' + tm.PartFamily + ' / ' + tm.OperationDescription) tlDescription,
	tt.ToolID, tt.processid as ttpid, tt.toolNumber,tt.OpDescription, 
	ti.itemid,ti.tooltype,ti.tooldescription,  
	 case 
		when tt.PartSpecific = 0 and ti.Consumable = 1 then (ti.Quantity * (tm.AnnualVolume/12.0)) / (ti.QuantityPerCuttingEdge * ti.NumberOfCuttingEdges) 
		when tt.PartSpecific = 1 and ti.Consumable = 1  then (ti.Quantity * (tt.AdjustedVolume/12)) / (ti.QuantityPerCuttingEdge * ti.NumberOfCuttingEdges) 
		when ti.Consumable = 0 then ti.Quantity
	  end MonthlyUsage  
	FROM [TOOLLIST ITEM] as ti 
	-- when a tool gets deleted the toollist item remains sometimes?
	inner join [TOOLLIST TOOL] as tt on ti.toolid=tt.toolid
	INNER JOIN 
	(
		-- these are obsolete toollists
		select * 
		from
		[ToolList Master] tm
		where Obsolete = 1
		--43
	) as tm 
	ON tt.PROCESSID = tm.PROCESSID 
	--1925
union
	SELECT tm.originalprocessid, tm.processid,CribToolID as itemNumber, (tm.Customer + ' / ' + tm.PartFamily + ' / ' + tm.OperationDescription) tlDescription,
	0 as ToolID, 0 as ttpid, 0 as toolNumber,'Fixture' as OpDescription, 
	tf.itemid,tf.tooltype,tf.tooldescription,  
	0 as MonthlyUsage  
	FROM [TOOLLIST Fixture] as tf 
	INNER JOIN 
	(
		-- these are obsolete toollists
		select * 
		from
		[ToolList Master] tm
		where Obsolete = 1
		--43
	) as tm 
	ON tf.PROCESSID = tm.PROCESSID 
	--48
union
	SELECT tm.OriginalProcessID, tm.processid,CribToolID as itemNumber, (tm.Customer + ' / ' + tm.PartFamily + ' / ' + tm.OperationDescription) tlDescription,
	0 as ToolID, 0 as ttpid, 0 as toolNumber,'Misc' as OpDescription, 
	m.itemid,m.tooltype,m.tooldescription,  
	 case 
		when m.Consumable = 1 then (m.Quantity * (tm.AnnualVolume/12.0)) / (m.QuantityPerCuttingEdge * m.NumberOfCuttingEdges) 
		else m.Quantity
	  end MonthlyUsage  
	FROM [ToolList Misc] as m 
	INNER JOIN 
	(
		-- these are obsolete toollists
		select * 
		from
		[ToolList Master] tm
		where Obsolete = 1
		--43
	)  
	as tm 
	ON m.PROCESSID = tm.PROCESSID 
	--370
--1983


GO
/****** Object:  View [dbo].[bvObsToolListItemsLv2]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-------------------------------------------------
-- Obsolete ToolList items,misc,and fixture detail
-- grouped by item 
-------------------------------------------------
create view [dbo].[bvObsToolListItemsLv2] 
as
SELECT itemNumber,monthlyUsage,
	isnull(SUBSTRING(
		opDesclist.xmlDoc.value('.', 'varchar(max)'),
		5, 10000
	),'Misc,Fixture, or Global') AS ToolOps
FROM  
(
	select itemNumber,sum(monthlyUsage) monthlyUsage
	from bvObsToolListItemsLv1
	group by 
	itemNumber 
	--24374
)
tli
--28328
cross apply(
	select '<br>' +  tlDescription + ', ' + ca1.OpDescription + 
	', ' + tooldescription as ListItem
	from 
	(
		select itemnumber,tlDescription,
		opDescription,tooldescription,monthlyUsage
		from bvObsToolListItemsLv1
		--1983
	) ca1
	where tli.itemNumber=ca1.itemNumber
	order by tlDescription,ca1.OpDescription
	for xml path(''), type
) as opDesclist(xmlDoc)

GO
/****** Object:  UserDefinedFunction [dbo].[bfToolListItemsInPlant]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create function [dbo].[bfToolListItemsInPlant]
(  
 @plant int
)
RETURNS TABLE 
AS
RETURN
select *
from
bvToolListItemsInPlants
where plant = @plant

GO
/****** Object:  View [dbo].[bvToolListItemsInPlantsNew]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[bvToolListItemsInPlantsNew]
as
select distinct tl.originalprocessid,tl.processid,tl.descript,tl.partNumber,tl.plant,
lv1.itemNumber,lv1.itemClass,lv1.UDFGLOBALTOOL,lv1.toolbossStock  
from bvToolListsInPlants tl
inner join
bvToolListItemsLv1 lv1
ON tl.processid = lv1.ProcessID
where lv1.UDFGLOBALTOOL <> 'YES'
--27838
union
	-- 796 select count(*) from bvToolListsInPlants
	select tl.originalprocessid,tl.processid,tl.descript,tl.partNumber,tl.plant
	,ti.itemNumber, ti.itemclass, ti.UDFGLOBALTOOL, 0 as toolbossStock 
	FROM  toolitems ti
	CROSS JOIN
	bvToolListsInPlants tl
	WHERE (ti.UDFGLOBALTOOL = 'YES')
	--2391
--30229

GO
/****** Object:  View [dbo].[bvToolBossItemsInPlants]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[bvToolBossItemsInPlants] 
as
-- toollists items that have a category that is to be stocked in the toolbosses
-- or are marked 

	select '$ALL$' AS [User], originalprocessid AS Job, 'DEFAULT' AS Machine, '133' AS D_Consumer, itemNumber AS item, '3' AS D_Item, plant 
	from
	(
			select originalprocessid,processid,descript,partNumber,plant,
			itemNumber,lv1.itemClass,UDFGLOBALTOOL,toolbossStock  
			from
			(
				select * from bvToolListItemsInPlants
				where toolbossstock=0 and UDFGLOBALTOOL <> 'YES'
				--27791
			) lv1
			inner join
			[ToolList Toolboss Stock Items] tbs
			on lv1.itemClass=tbs.ItemClass
			--14347
		union
			-- stocked in toolboss no matter the item
			-- class
			SELECT *
			from
			bvToolListItemsInPlants
			where toolbossstock=1 and UDFGLOBALTOOL <> 'YES'
			--17
		union
			-- add these global items to all tool lists 
			select *
			from
			bvToolListItemsInPlants
			where UDFGLOBALTOOL = 'YES'
			--2388
	--16752
	--16752
) lv2

GO
/****** Object:  UserDefinedFunction [dbo].[bfToolBossItemsInPlant]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create function [dbo].[bfToolBossItemsInPlant]
(  
 @plant int
)
RETURNS TABLE 
AS
RETURN
select * from bvToolBossItemsInPlants
where plant = @plant

GO
/****** Object:  View [dbo].[bvDistinctToolListItems]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[bvDistinctToolListItems]
as
-- Remove duplicates only differing in plant
select OriginalProcessId,ProcessId,
Descript,partNumber,itemnumber,itemclass,udfglobaltool,toolbossstock
from
bvToolListItemsInPlants
group by 
OriginalProcessId,ProcessId,
Descript,partNumber,itemnumber,itemclass,udfglobaltool,toolbossstock
--731

GO
/****** Object:  View [dbo].[bvAllTListsForPN]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[bvAllTListsForPN]
as
select partNumber,
case 
	when toollists is null then 'none'
	else toollists
end
as toollists
from
(
	select one.PartNumbers as partNumber,
	SUBSTRING(
		toollists.xmlDoc.value('.', 'varchar(max)'),
		6, 10000
	) AS toolLists
	from 
	(
		-- one part Number
		select distinct(partNumbers) as partNumbers from [ToolList PartNumbers]
	)one
	cross apply(
		-- many toollists
		select ',<br>'+ many.fullDescr as ListItem
		from 
		(
			-- one partNumber many toollists
			select pn.PartNumbers, 
			tm.processid,tm.Customer+' - '+tm.PartFamily+' - '+tm.OperationDescription 
			+ '<br>( origPid:' + ltrim(str(tm.ProcessID))
			+ ', Pid: ' + ltrim(str(tm.OriginalProcessID)) + ' )' as fullDescr
			from [ToolList Master] tm
			inner join
			[ToolList PartNumbers] pn
			on tm.processid=pn.ProcessID
		) many
		where one.partNumbers=many.partNumbers
		order by many.fullDescr
		for xml path(''), type
	) as toollists(xmlDoc)
) lv1


GO
/****** Object:  View [dbo].[bvGetActiveToolLists]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create VIEW [dbo].[bvGetActiveToolLists]
AS
	select lv8.processId,partNumber, 
			SUBSTRING(Customer + ' - ' + PartFamily + ' - ' + OperationDescription, 1, 50) descript 
	from
	(
		-- GOAL: pick only one process id to represent each part number without
		-- loosing any part numbers from the list.
		select max(processid) as processId,partNumber from
		(
			select lv5.processid,PartNumbers as partNumber from
			(
				select originalprocessid, lv3.processid  
				from
				(
					-- 718 items
					select lv1.originalprocessid, lv2.processid, obsolete,released,revinprocess
					from (
						-- sometimes 5 or more toollists have the same original processid this could be
						-- because the tool list program did not delete the old one's properly
						-- but in a common case where there is a rev in process I have chosen the min(processid)
						-- to be the one used. At this point there could still be part numbers represented by
						-- more than one original processid.
						select OriginalProcessID, min(processid) processid 
						from
						(
							-- There is nothing to prevent a new tool list from being made with a part number
							-- that is the same as another tool list.  In the scenario where there is more than
							-- one tool list with the same part numbers the tool lists could have different
							-- original process ids.  So be careful in your effort to not exclude some part numbers
							-- from the list
							-- each "rev" of a part number can have a different tool list with a different original processid
							-- and some revs can be obsolete or not released so be careful to include at least one processid
							-- for all part numbers
							select OriginalProcessID, ProcessID 
							from [ToolList Master]
							where released = 1 and Obsolete = 0 
							-- all part numbers that have any process ids that are released and not obsolete
							-- should be represented here
							-- 764
						) lv1
						group by OriginalProcessID
						-- 725
					) as lv1
					left outer join
					[ToolList Master] as lv2
					on
					lv1.processid = lv2.ProcessID
					-- 725
				) lv3 
				inner join
				(
					-- processid with items --
					select distinct processid
					from
					(
						select distinct processid 
						from [ToolList Item]
						union
						select distinct processid 
						from [ToolList Misc]
						union
						select distinct processid 
						from [ToolList Fixture]
					) as lv1
				) lv4
				on lv3.ProcessID = lv4.ProcessID
				-- try to exclude original process id chains that have no items 
				-- without loosing any part numbers in the process
				-- remember we chose the min process id in each origninal process id chain
				-- to be the representative process id for that original process id / part number chain.
				-- Theoretically we could drop some part numbers here if the min process id had no items
				-- on it but a later process id did have items.
				where lv4.ProcessID is not null
				-- 725  In my test all process ids that made it through this far had items on them
			) lv5
			--718
			inner join
			[ToolList PartNumbers] lv6
			on lv5.ProcessID = lv6.ProcessID
			-- 728  
			-- This shows that there is more than one part number associated with some original
			-- process id tool chain, or the process id that we picked to represent the original process id
			-- chain had multiple part numbers while another later one may not have.  Or no original
			-- process id chain have multiple part numbers but there is more than one original process id
			-- chain with the same part number. There could also be some original process id chains with
			-- no part number associated with it. In any case we must pick one process id to represent 
			-- each part number I have chosen the max process id because this represented the most recently
			-- revised active tool list that has that part number. 
		) lv7
		group by partNumber
		-- 529
		-- At this point we do not have duplicate part numbers and we have chosen which process id to 
		-- represent it
	) lv8
	left outer join
	[ToolList Master] as lv9
	on
	lv8.processid = lv9.ProcessID
	-- 529 
	-- We should now have picked the process id that we want to represent a part number
	-- Hopefully all part numbers with a valid tool list are on this list

GO
/****** Object:  View [dbo].[VObsMonthlyUsage]    Script Date: 4/20/2018 11:36:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create View [dbo].[VObsMonthlyUsage] 
-- Determine combined tool list usage of this item 
AS
	SELECT CribToolID,tm.processid,(tm.Customer + '/' + tm.PartFamily + '/' + tm.OperationDescription) tlDescription , 
	tt.ToolID, ti.itemid,ti.tooldescription,tt.OpDescription,	 
	 case 
		when tt.PartSpecific = 0 and ti.Consumable = 1 then (ti.Quantity * (tm.AnnualVolume/12.0)) / (ti.QuantityPerCuttingEdge * ti.NumberOfCuttingEdges) 
		when tt.PartSpecific = 1 and ti.Consumable = 1  then (ti.Quantity * (tt.AdjustedVolume/12)) / (ti.QuantityPerCuttingEdge * ti.NumberOfCuttingEdges) 
		when ti.Consumable = 0 then ti.Quantity
	  end MonthlyUsage  
	FROM [TOOLLIST ITEM] as ti 
	inner join [TOOLLIST TOOL] as tt on ti.toolid=tt.toolid
	INNER JOIN 
	(
		select tmin.* from 
		bvListOfObsoleteToolLists tl
		inner join
		[ToolList Master] tmin
		on tl.ProcessId = tmin.processid
		--40
	)tm
	ON tt.PROCESSID = tm.PROCESSID 
--30467	


GO
USE [master]
GO
ALTER DATABASE [Busche ToolList] SET  READ_WRITE 
GO
