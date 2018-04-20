bvListOfActiveApprovedToolLists.sql
USE [Busche ToolList]
GO

/****** Object:  View [dbo].[bvListOfActiveApprovedToolLists]    Script Date: 4/19/2018 12:35:14 PM ******/
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