USE [m2mdata01]
GO
/****** Object:  View [dbo].[beinmast]    Script Date: 4/24/2018 7:54:15 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ******************************************************************************************

	-- **********************************************************************************************************************************************************
	-- Create new view and instead of trigger based on the renamed table.
	
	CREATE VIEW [dbo].[beinmast]
	AS
	SELECT     *, dbo.BeGetItemOnHandQuantity(fac, fpartno, frev) AS fonhand, dbo.GetItemInspectionQuantity(fac, fpartno, frev) AS fqtyinspec, 
	                      dbo.GetItemNonNetQuantity(fac, fpartno, frev) AS fnonnetqty, dbo.GetItemInProcessQuantity(fac, fpartno, frev) AS fproqty, 
	                      dbo.GetItemOnOrderQuantity(fac, fpartno, frev) AS fonorder, dbo.GetItemCommittedQuantity(fac, fpartno, frev) AS fbook, dbo.GetItemLastIssueDate(fac, 
	                      fpartno, frev) AS flastiss, dbo.GetItemLastReceiptDate(fac, fpartno, frev) AS flastrcpt, dbo.GetItemMTDIssues(fac, fpartno, frev, GETDATE()) AS fmtdiss, 
	                      dbo.GetItemYTDIssues(fac, fpartno, frev, GETDATE()) AS fytdiss, dbo.GetItemMTDReceipts(fac, fpartno, frev, GETDATE()) AS fmtdrcpt, 
	                      dbo.GetItemYTDReceipts(fac, fpartno, frev, GETDATE()) AS fytdrcpt
	FROM         dbo.inmastx


GO
/****** Object:  View [dbo].[bebkord]    Script Date: 4/24/2018 7:54:15 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ******************************************************************************************
	-- **********************************************************************************************************************************************************
	-- Sales Backorder View
	CREATE VIEW [dbo].[bebkord]
	AS
		SELECT  SOMast.fSONo, SOMast.fCompany, SOMast.fCustNo, SOMast.fSORev, SORels.fDueDate, 
		SORels.fOrderQty, soitem.finumber,soitem.fprodcl, sorels.frelease, SORels.fPartNo, sorels.fpartRev AS frev, 
		sorels.fcudrev,sorels.fcloc, 
		SOITEM.FAC, 
		CASE WHEN beinmast.fluseudrev IS NOT NULL AND beinmast.fluseudrev = 1 THEN sorels.fcudrev ELSE sorels.fpartrev END AS fcdisprev, 
		SOItem.fDesc, SPACE( 12) AS fpoitem, SPACE( 6) AS fjobno, SPACE( 9) AS fquoteno, 
		sorels.fpartno AS fcpartno, SPACE( 2) AS fcprodcl, 
		0.00 AS fnunit01, 0.00 AS fnunit02, 0.00 AS fnunit03, 0.00 AS fnunit04, 0.00 AS fnunit05, 
		0.00 AS fnunit06, 0.00 AS fnunit07, 0.00 AS fnunit08, 0.00 AS fnunit09, 0.00 AS fnunit10, 
		0.00 AS fnunit11, 0.00 AS fnunit12, 
		0.00 AS fnprice01, 0.00 AS fnprice02, 0.00 AS fnprice03, 0.00 AS fnprice04, 0.00 AS fnprice05, 
		0.00 AS fnprice06, 0.00 AS fnprice07, 0.00 AS fnprice08, 0.00 AS fnprice09, 0.00 AS fnprice10, 
		0.00 AS fnprice11, 0.00 AS fnprice12, 0.00 AS fnblcap, 0.00 AS fnblmanhr, 0.00 AS fnblprice, 
		0.00 AS fnblprofit, 0.00 AS fnqucap, 0.00 AS fnqumanhr, 0.00 AS fnquprice, 0.00 AS fnquprofit, 
		SPACE(2) AS fcprodclass, SPACE(35) AS fccompany, 
		SORels.fShipBook + SORels.fShipBuy + SORels.fShipMake AS fnShiptQty, 
		SORels.fOrderQty - (SORels.fShipBook + SORels.fShipBuy + SORels.fShipMake) AS fnBOQty, 
		ROUND((SORels.fOrderQty - (SORels.fShipBook + SORels.fShipBuy + SORels.fShipMake)) * SORels.fUNetPrice,2) AS fnBOAmt, 
		CASE WHEN BeInMast.fOnHand IS NULL THEN 00000000.00000 ELSE BeInMast.fOnHand END AS fnOnHand,
		CASE WHEN (dbo.BeGetPcsReqByDate(soitem.fac,SORels.fPartNo, sorels.fpartRev,sorels.fDueDate) IS NULL) OR 
				  (BeInMast.fOnHand IS NULL) THEN 
						00000000.00000 
					ELSE 
						dbo.BeGetPcsReqByDate(soitem.fac,SORels.fPartNo, sorels.fpartRev,sorels.fDueDate) - BeInMast.fOnHand
		 END AS ReqQty 
		FROM sorels 
		JOIN SoMast 
		ON SOMast.fSONo = SORels.fSONo 
		JOIN SoItem 
		ON SoItem.fSONo = SoRels.fSONo AND SoItem.fInumber = SoRels.fInumber 
		LEFT OUTER JOIN BeInMast 
		ON SOITEM.fPartNo = BeInMast.fPartNo 
		AND SOITEM.fpartRev = BeInMast.fRev 
		AND SOITEM.fac = BeInMast.fac 
		WHERE SOMast.fStatus = 'OPEN' 
		AND fMasterRel = 0 AND SOItem.fShipItem =  1 
		AND fOrderQty > (fShipBook + fShipBuy + fShipMake)  



GO
/****** Object:  View [dbo].[MA_JobLaborActual]    Script Date: 4/24/2018 7:54:15 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



----------------------------------------------------------------------------------------------
-- MA_JobLaborActual returns job labor actual hours / costs, totalled by job and operation #
-- Note: we use CONVERT(DECIMAL(17,5), ...) to avoid LinqToSql overflow warnings.
----------------------------------------------------------------------------------------------
create view [dbo].[MA_JobLaborActual] as
select fjobno as JobNo
		,foperno as OperationNo
	    ,CONVERT(DECIMAL(17,5), sum(case when FCODE1='S' then ladetail.ftotpcost else 0 end)) as ActualSetupCost
	    ,CONVERT(DECIMAL(17,5), sum(case when FCODE1='S' then ladetail.ftotocost else 0 end)) as ActualSetupOverhead
	    ,CONVERT(DECIMAL(17,5), sum(case when FCODE1='S' then CONVERT(DECIMAL(17,5),DATEDIFF(ss, ladetail.fsdatetime, ladetail.fedatetime))/3600 else 0 end)) as ActualSetupHours
	    ,CONVERT(DECIMAL(17,5), sum(case when FCODE1='P' then ladetail.ftotpcost else 0 end)) as ActualProdCost
	    ,CONVERT(DECIMAL(17,5), sum(case when FCODE1='P' then ladetail.ftotocost else 0 end)) as ActualProdOverhead	    
	    ,CONVERT(DECIMAL(17,5), sum(case when FCODE1='P' then CONVERT(DECIMAL(17,5),DATEDIFF(ss, ladetail.fsdatetime, ladetail.fedatetime))/3600 else 0 end)) as ActualProdHours	    
from ladetail
where fstatus <> 'H'
group by fjobno, foperno

GO
/****** Object:  View [dbo].[MA_JobLaborSummary]    Script Date: 4/24/2018 7:54:15 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


----------------------------------------------------------------------------------------------
-- MA_JobLaborSummary returns estimated and actual labor hours / costs / qty / etc information
-- for all non-subcontracting job operations, totalled by job and operation #
-- Note: we use CONVERT(DECIMAL(17,5), ...) to avoid LinqToSql overflow warnings.
----------------------------------------------------------------------------------------------
create view [dbo].[MA_JobLaborSummary] as
select fjobno as JobNo
		,foperno as OperationNo
		,fpro_id as WorkCenterId
		,inwork.fcpro_name as WorkCenterName
		,inwork.fdept as WorkCenterDept
		,foperqty as RequiredQuantity
		,fnqty_comp as CompletedQuantity
		,fsetuptime as EstimatedSetupHours
		--,fsetup_tim as ActualSetupHours
		,ISNULL(ActualSetupHours,0) as ActualSetupHours
		,ISNULL(CONVERT(DECIMAL(17,5), fuprodtime * foperqty) ,0) as EstimatedProdHours		
		--,fprod_tim as ActualProdHours
		,ISNULL(ActualProdHours,0) as ActualProdHours
		,ISNULL(CONVERT(DECIMAL(17,5), fuprodtime * foperqty * fulabcost),0) as EstimatedProdCost
		,ISNULL(ActualProdCost,0) as ActualProdCost		
		,ISNULL(fsetuptime * fulabcost,0) as EstimatedSetupCost
		,ISNULL(ActualSetupCost,0) as ActualSetupCost
		,ISNULL(CONVERT(DECIMAL(17,5), (fuprodtime * foperqty + fsetuptime) * fuovrhdcos),0) as EstimatedOverheadCost
		,ISNULL(ActualSetupOverhead + ActualProdOverhead,0) as ActualOverheadCost
		,fopermemo as Description
from jodrtg
left join inwork on jodrtg.fpro_id = inwork.fcpro_id AND jodrtg.fac = inwork.fac
left join MA_JobLaborActual on jodrtg.fjobno = MA_JobLaborActual.JobNo and jodrtg.foperno = MA_JobLaborActual.OperationNo
where LEFT(fPro_ID , 3)<>'sub' 

-- Bring in job splitting costs from OCDIST
union all select
	fjob_so as JobNo
	,-1 as OperationNo
	,'Job Split' as WorkCenterId
	,'Job Split' as WorkCenterName
	,'n/a' as WorkCenterDept
	,0 as RequiredQuantity
	,0 as CompletedQuantity
	,0 as EstimatedSetupHours
	,0 as ActualSetupHours
	,0 as EstimatedProdHours
	,0 as ActualProdHours
	,0 as EstimatedProdCost
	,ISNULL(CONVERT(DECIMAL(17,5),sum(CASE WHEN FCJOSPLT = 'L' then fnamount else 0 end)),0) As ActualProdCost
	,0 as EstimatedSetupCost
	,0 as ActualSetupCost
	,0 as EstimatedOverheadCost
	,ISNULL(CONVERT(DECIMAL(17,5),sum(CASE WHEN FCJOSPLT = 'O' then fnamount else 0 end)),0) As ActualOverheadCost
	,MIN(fcomment) as Description
from ocdist 	
where ocdist.fcjosplt<>''
group by fjob_so


GO
/****** Object:  View [dbo].[MA_JobSubConActual]    Script Date: 4/24/2018 7:54:15 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


----------------------------------------------------------------------------------------------
-- MA_JobSubConActual returns job sub-contracting actual costs, totalled by job and operation #
-- Note: we use CONVERT(DECIMAL(17,5), ...) to avoid LinqToSql overflow warnings.
----------------------------------------------------------------------------------------------
create view [dbo].[MA_JobSubConActual] as
select fjobno as JobNo
		,foperno as OperationNo		
	    ,CONVERT(DECIMAL(17,5), SUM(rcitem.fucost)) as ActualReceiverUnitCost	    	    
	    ,CONVERT(DECIMAL(17,5), SUM(rcitem.fqtyrecv)) ActualReceiverQuantity	
	     -- We only want to consider the APITEM price if the APMAST has a status of F, P, or U; otherwise we return null, as if the invoice didn't yet exist
	    ,case when apmast.fcstatus in ('F', 'P', 'U') then  CONVERT(DECIMAL(17,5), SUM(apitem.fprice)) else null end ActualInvoiceCost		    
from JODRTG
join poitem on poitem.fjokey=jodrtg.fjobno and poitem.fjoopno = jodrtg.foperno
join rcmast on poitem.fpono = rcmast.fpono 
join rcitem on rcmast.freceiver = rcitem.freceiver and rcitem.fjokey = jodrtg.fjobno
left join apitem on apitem.frecvkey = rcitem.freceiver + rcitem.fitemno 
left join apmast on apmast.fvendno + apmast.fcinvoice = apitem.fcinvkey
where LEFT(fPro_ID , 3)='sub'
group by fjobno, foperno, apmast.fcstatus

GO
/****** Object:  View [dbo].[MA_JobSubConSummary]    Script Date: 4/24/2018 7:54:15 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


----------------------------------------------------------------------------------------------
-- MA_JobSubConSummary returns estimated and actual sub-contracting hours / costs / qty / etc information
-- for all subcontracting based job operations, totalled by job and operation #
-- Note: we use CONVERT(DECIMAL(17,5), ...) to avoid LinqToSql overflow warnings.
----------------------------------------------------------------------------------------------
create view [dbo].[MA_JobSubConSummary] as
select fjobno as JobNo
		,foperno as OperationNo
		,fpro_id as WorkCenterId
		,inwork.fcpro_name as WorkCenterName
		,foperqty as RequiredQuantity
		,fnqty_comp as CompletedQuantity
		,fpono as PurchaseOrderNumber
		,ISNULL(ActualReceiverQuantity,0) as ReceiverQuantity
		,felpstime as EstimatedDays		
		,ISNULL(CONVERT(DECIMAL(17,5), ffixcost + (fusubcost * foperqty)),0)  as EstimatedSubContractingCost	
		-- Use the actual invoice cost if available as its more accurate;  otherwise settle for the receiver cost
		,ISNULL(ISNULL(ActualInvoiceCost, ffixcost + ISNULL(ActualReceiverUnitCost * ActualReceiverQuantity ,0)),0) as ActualSubContractingCost	
		,fopermemo as Description
from JODRTG
left join MA_JobSubConActual on JODRTG.fjobno = MA_JobSubConActual.JobNo and JODRTG.foperno=MA_JobSubConActual.OperationNo
left join inwork on jodrtg.fpro_id = inwork.fcpro_id AND jodrtg.fac = inwork.fac
where LEFT(fPro_ID , 3)='sub'

GO
/****** Object:  View [dbo].[MA_JobMaterialDetail]    Script Date: 4/24/2018 7:54:15 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


----------------------------------------------------------------------------------------------
-- MA_JobMaterialDetail returns material detail records (including source data) from a variety of tables
-- Note: we use CONVERT(DECIMAL(17,5), ...) to avoid LinqToSql overflow warnings.
-- Warning:  This is an expensive view to execute - it hits a LOT of tables
----------------------------------------------------------------------------------------------
create view [dbo].[MA_JobMaterialDetail] as

-- Inventory issues and transfers to this job 
SELECT	
	ftojob as JobNo
	,fpartno as PartNo
	,fcpartrev as PartRev
	,fac as Facility
	,fdate as TransDate
	,'INTRAN' as TableSource
	,case when FTYPE ='I' then 'Inventory Issue' when FTYPE ='T' then 'Inventory Transfer (to)' end as Source
	,ISNULL(CONVERT(DECIMAL(17,5), case when FTYPE ='I' then -fqty else fqty end) ,0) as ActualQuantity
	,ISNULL(CONVERT(DECIMAL(17,5), fmatl * case when FTYPE ='I' then -fqty else fqty  end),0) as ActualMaterialCost
	,ISNULL(CONVERT(DECIMAL(17,5), flabor * case when FTYPE ='I' then -fqty else fqty  end),0) as ActualLaborCost
	,ISNULL(CONVERT(DECIMAL(17,5), fovrhd * case when FTYPE ='I' then -fqty else fqty  end),0) as ActualOverheadCost	
FROM INTRAN
where (FTYPE='I' or FTYPE='T')

-- Transfers from this job 
UNION ALL SELECT	
	ffromjob as JobNo
	,fpartno as PartNo
	,fcpartrev as PartRev
	,fac as Facility
	,fdate as TransDate
	,'INTRAN' as TableSource
	,'Inventory Transfer (from)' as Source
	,ISNULL(CONVERT(DECIMAL(17,5), -fqty),0) as ActualQuantity
	,ISNULL(CONVERT(DECIMAL(17,5), fmatl * -fqty),0) as ActualMaterialCost
	,ISNULL(CONVERT(DECIMAL(17,5), flabor * -fqty),0) as ActualLaborCost
	,ISNULL(CONVERT(DECIMAL(17,5), fovrhd * -fqty),0) as ActualOverheadCost	
FROM INTRAN
where FTYPE='T'

-- RECEIVER sourced costs (for buy items)
UNION ALL SELECT 
	fjobno as JobNo
	,fbompart as PartNo
	,fbomrev as PartRev
	,cfac as Facility
	,ISNULL(finvdate, fdaterecv) as TransDate
	,case when apmast.fcinvoice is null or apmast.fcstatus not in ('F', 'P', 'U') then 'RCITEM' else 'APITEM' end as TableSource
	,case when apmast.fcinvoice is null or apmast.fcstatus not in ('F', 'P', 'U') then 'PO: ' + rcmast.fpono +'; Receiver: ' + rcmast.freceiver
							            else 'PO: ' + rcmast.fpono +'; Receiver: ' + rcmast.freceiver + '; Invoice: ' + apmast.fcinvoice end as Source	
	,ISNULL(CONVERT(DECIMAL(17,5), rcitem.fqtyrecv),0) ActualQuantity	
	,ISNULL(case when apmast.fcstatus is null or apmast.fcstatus not in ('F', 'P', 'U') then 		  
			 -- Use the receiver price if the AP Invoice doesn't exist or isn't in the desired status
			 CONVERT(DECIMAL(17,5), rcitem.fqtyrecv * rcitem.fucost)		 
		  else 
		     -- otherwise use the invoice price as its more accurate
		     CONVERT(DECIMAL(17,5), apitem.fprice) 			 
		  end,0) as ActualMaterialCost
	 ,0 as ActualLaborCost
	 ,0 as ActualOverheadCost
from JODBOM
join poitem on poitem.fjokey=jodbom.fjobno and poitem.fpartno = jodbom.fbompart and poitem.frev=jodbom.fbomrev and poitem.fac = jodbom.cfac
join rcmast on poitem.fpono = rcmast.fpono
join rcitem on rcmast.freceiver = rcitem.freceiver and rcitem.fjokey = jodbom.fjobno and rcitem.fpartno = jodbom.fbompart and rcitem.fpartrev=jodbom.fbomrev and rcitem.fac = jodbom.cfac
left join apitem on apitem.frecvkey = rcitem.freceiver + rcitem.fitemno 
left join apmast on apmast.fvendno + apmast.fcinvoice = apitem.fcinvkey
where fbomsource='B' 

-- SHIP sourced costs (for buy items that have been returned)
UNION ALL SELECT 
	JOMAST.FJOBNO as JobNo
	,childPOItem.fpartno as PartNo
	,childPOItem.frev as PartRev
	,childPOItem.fac as Facility
	,isnull(finvdate, fshipdate) as TransDate
	,case when apmast.fcinvoice is null or apmast.fcstatus not in ('F', 'P', 'U') then 'SHITEM' else 'APITEM' end as TableSource
	,case when apmast.fcinvoice is null or apmast.fcstatus not in ('F', 'P', 'U') then 'PO: ' + childPOItem.fpono +'; Shipper: ' + shmast.fshipno
																				  else 'PO: ' + childPOItem.fpono +'; Shipper: ' + shmast.fshipno + '; Invoice: ' + apmast.fcinvoice end as Source	

	,ISNULL(CONVERT(DECIMAL(17,5), -fshipqty),0) as ActualQuantity
	,ISNULL(case when apmast.fcstatus is null or apmast.fcstatus not in ('F', 'P', 'U') then 		  
			 -- Use the PO price if the AP Invoice doesn't exist or isn't in the desired status
			 CONVERT(DECIMAL(17,5), -childPOItem.fnorgucost * fshipqty)		 
		  else 
		     -- otherwise use the invoice price as its more accurate
		     CONVERT(DECIMAL(17,5), -apitem.fprice) 			 
		  end, 0) as ActualMaterialCost
	 ,0 as ActualLaborCost
	 ,0 as ActualOverheadCost
FROM jomast
join poitem parentPOItem on jomast.fjobno = parentPOItem.fjokey 
join poitem childPOItem on parentPOItem.fpono = childPOItem.fparentpo AND parentPOItem.fitemno = childPOItem.fparentitm AND parentPOItem.frelsno = childPOItem.fparentrls 
join shitem on shitem.fcpokey = childPOItem.fpono + childPOItem.fitemno + childPOItem.frelsno 
join shmast on shmast.fshipno = shitem.fshipno AND LTRIM(RTRIM(shmast.fConfirm)) = 'Y' 
left join apitem on apitem.fpokey = childPOItem.fpono + childPOItem.fitemno + childPOItem.frelsno 
left join apmast on apmast.fvendno + apmast.fcinvoice = apitem.fcinvkey


GO
/****** Object:  View [dbo].[MA_JobMaterialActual]    Script Date: 4/24/2018 7:54:15 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

----------------------------------------------------------------------------------------------
-- MA_JobMaterialActual returns actual material costs / qty information group by job / part
-- Note: we use CONVERT(DECIMAL(17,5), ...) to avoid LinqToSql overflow warnings.
----------------------------------------------------------------------------------------------
create view [dbo].[MA_JobMaterialActual] as

select 
	JobNo
	,PartNo
	,PartRev
	,Facility
	,ISNULL(CONVERT(DECIMAL(17,5), sum(ActualQuantity)),0)  as ActualQuantity
	,ISNULL(CONVERT(DECIMAL(17,5), sum(ActualMaterialCost)),0)  as ActualMaterialCost
	,ISNULL(CONVERT(DECIMAL(17,5), sum(ActualLaborCost)),0)  as ActualLaborCost
	,ISNULL(CONVERT(DECIMAL(17,5), sum(ActualOverheadCost)),0)  as ActualOverheadCost
from MA_JobMaterialDetail 
group by JobNo, PartNo, PartRev, Facility


GO
/****** Object:  View [dbo].[MA_JobMaterialSummary]    Script Date: 4/24/2018 7:54:15 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


----------------------------------------------------------------------------------------------
-- MA_JobLaborSummary returns estimated and actual labor hours / costs / qty / etc information
-- for all non-subcontracting job operations, totalled by job and operation #
-- Note: we use CONVERT(DECIMAL(17,5), ...) to avoid LinqToSql overflow warnings.
----------------------------------------------------------------------------------------------
create view [dbo].[MA_JobMaterialSummary] as
-- Gather estimates and actuals based on the expected BOM (jodbom)	     
select 
	jodbom.fjobno as JobNo
	,jodbom.fsub_job as SubJobNo
	,jodbom.fbompart as PartNo
	,jodbom.fbomrev as PartRev
	,jodbom.cfac as PartFac
	,jodbom.fbomsource as PartSource
	,inmastx.fsource as PartSourceFromItemMaster
	,jodbom.fbomdesc as PartDescription
	-- MA_JobMaterialActual - Actual quantity / cost 
	,ISNULL(MA_JobMaterialActual.ActualQuantity,0) as ActualQuantity
	,ISNULL(MA_JobMaterialActual.ActualMaterialCost,0) as ActualMaterialCost
	,ISNULL(MA_JobMaterialActual.ActualLaborCost,0) as ActualLaborCost
	,ISNULL(MA_JobMaterialActual.ActualOverheadCost,0) as ActualOverheadCost
	-- jodbom - Estimated quantity / cost 
	,ISNULL(CONVERT(DECIMAL(17,5), sum(jodbom.forigqty * fquantity)),0) as EstimatedQuantity			
	,ISNULL(CONVERT(DECIMAL(17,5), sum(jodbom.fmatlcost * forigqty * fquantity)),0) as EstimatedMaterialCost	
	,ISNULL(CONVERT(DECIMAL(17,5), sum(jodbom.flabcost * forigqty * fquantity)),0) as EstimatedLaborCost	
	,ISNULL(CONVERT(DECIMAL(17,5), sum(jodbom.fovrhdcost * forigqty * fquantity)),0) as EstimatedOverheadCost	
	,ISNULL(CONVERT(DECIMAL(17,5), sum(jodbom.fbomlcost * forigqty * fquantity)),0) as EstimatedLaborComponentCost	
	,ISNULL(CONVERT(DECIMAL(17,5), sum(jodbom.fbomocost * forigqty * fquantity)),0) as EstimatedOverheadComponentCost	
	-- inmastx - Inventory cost (standard or average)
	,ISNULL(CONVERT(DECIMAL(17,5), sum(inmastx.flabcost * jodbom.factqty * fquantity)),0) as InventoryStdLaborCost
	,ISNULL(CONVERT(DECIMAL(17,5), sum(inmastx.f2labcost * jodbom.factqty * fquantity)),0) as InventoryAvgLaborCost	
	,ISNULL(CONVERT(DECIMAL(17,5), sum(inmastx.fmatlcost * jodbom.factqty * fquantity)),0) as InventoryStdMaterialCost
	,ISNULL(CONVERT(DECIMAL(17,5), sum(inmastx.f2matlcost * jodbom.factqty * fquantity)),0) as InventoryAvgMaterialCost	
	,ISNULL(CONVERT(DECIMAL(17,5), sum(inmastx.fovhdcost * jodbom.factqty * fquantity)),0) as InventoryStdOverheadCost
	,ISNULL(CONVERT(DECIMAL(17,5), sum(inmastx.f2ovhdcost * jodbom.factqty * fquantity)),0) as InventoryAvgOverheadCost		
	,jodbom.fbommeas as UnitOfMeasure
from jodbom
join inmastx on inmastx.fpartno = jodbom.fbompart and 
			    inmastx.frev = jodbom.fbomrev and 
			    inmastx.fac = jodbom.cfac
join jomast on jodbom.fjobno = jomast.fjobno
left join MA_JobMaterialActual  on jodbom.fjobno = MA_JobMaterialActual.JobNo and 
								   jodbom.fbompart = MA_JobMaterialActual.PartNo and 
								   jodbom.fbomrev = MA_JobMaterialActual.PartRev and
								   jodbom.cfac = MA_JobMaterialActual.Facility
								   
group by jodbom.fjobno, fsub_job, fbompart, fbomrev, cfac, fbomsource, inmastx.fsource, fbomdesc, fbommeas,
	     ActualQuantity,ActualMaterialCost, ActualLaborCost, ActualOverheadCost

-- Add any actual materials that were added to the job but weren't in the BOM (jodbom)	     
union all select 
	MA_JobMaterialActual.JobNo as JobNo
	,null as SubJobNo
	,MA_JobMaterialActual.PartNo as PartNo
	,MA_JobMaterialActual.PartRev as PartRev
	,MA_JobMaterialActual.Facility as PartFac
	,inmastx.fsource as PartSource
	,inmastx.fsource as PartSourceFromItemMaster
	,inmastx.fdescript as PartDescription
	-- MA_JobMaterialActual - Actual quantity / cost 
	,ISNULL(MA_JobMaterialActual.ActualQuantity,0) as ActualQuantity	
	,ISNULL(MA_JobMaterialActual.ActualMaterialCost,0) as ActualMaterialCost	
	,ISNULL(MA_JobMaterialActual.ActualLaborCost,0) as ActualLaborCost	
	,ISNULL(MA_JobMaterialActual.ActualOverheadCost,0) as ActualOverheadCost
	-- No estimates available
	,0 as EstimatedQuantity	
	,0 as EstimatedMaterialCost
	,0 as EstimatedLaborCost
	,0 as EstimatedOverheadCost
	,0 as EstimatedLaborComponentCost
	,0 as EstimatedOverheadComponentCost
	-- inmastx - Inventory cost (standard or average)
	-- inmastx - Inventory cost (standard or average)
	,ISNULL(CONVERT(DECIMAL(17,5), sum(inmastx.flabcost * fquantity)),0) as InventoryStdLaborCost
	,ISNULL(CONVERT(DECIMAL(17,5), sum(inmastx.f2labcost * fquantity)),0) as InventoryAvgLaborCost	
	,ISNULL(CONVERT(DECIMAL(17,5), sum(inmastx.fmatlcost * fquantity)),0) as InventoryStdMaterialCost
	,ISNULL(CONVERT(DECIMAL(17,5), sum(inmastx.f2matlcost * fquantity)),0) as InventoryAvgMaterialCost	
	,ISNULL(CONVERT(DECIMAL(17,5), sum(inmastx.fovhdcost * fquantity)),0) as InventoryStdOverheadCost
	,ISNULL(CONVERT(DECIMAL(17,5), sum(inmastx.f2ovhdcost * fquantity)),0) as InventoryAvgOverheadCost		
	,inmastx.fmeasure as UnitOfMeasure
from MA_JobMaterialActual
join jomast on MA_JobMaterialActual.JobNo = jomast.fjobno
join inmastx on  inmastx.fpartno= MA_JobMaterialActual.PartNo and 
				 inmastx.frev = MA_JobMaterialActual.PartRev and
				 inmastx.fac = MA_JobMaterialActual.Facility
left join jodbom  on jodbom.fjobno = MA_JobMaterialActual.JobNo and 
					 jodbom.fbompart = MA_JobMaterialActual.PartNo and 
					 jodbom.fbomrev = MA_JobMaterialActual.PartRev and
					 jodbom.cfac = MA_JobMaterialActual.Facility
where jodbom.fjobno is null
group by JobNo, PartNo, PartRev,Facility ,fsource, inmastx.fdescript, inmastx.fmeasure,
	     ActualQuantity,ActualMaterialCost, ActualLaborCost, ActualOverheadCost	     



GO
/****** Object:  View [dbo].[inmast]    Script Date: 4/24/2018 7:54:15 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ******************************************************************************************

	-- **********************************************************************************************************************************************************
	-- Create new view and instead of trigger based on the renamed table.
	
	CREATE VIEW [dbo].[inmast]
	AS
	SELECT     *, dbo.GetItemOnHandQuantity(fac, fpartno, frev) AS fonhand, dbo.GetItemInspectionQuantity(fac, fpartno, frev) AS fqtyinspec, 
	                      dbo.GetItemNonNetQuantity(fac, fpartno, frev) AS fnonnetqty, dbo.GetItemInProcessQuantity(fac, fpartno, frev) AS fproqty, 
	                      dbo.GetItemOnOrderQuantity(fac, fpartno, frev) AS fonorder, dbo.GetItemCommittedQuantity(fac, fpartno, frev) AS fbook, dbo.GetItemLastIssueDate(fac, 
	                      fpartno, frev) AS flastiss, dbo.GetItemLastReceiptDate(fac, fpartno, frev) AS flastrcpt, dbo.GetItemMTDIssues(fac, fpartno, frev, GETDATE()) AS fmtdiss, 
	                      dbo.GetItemYTDIssues(fac, fpartno, frev, GETDATE()) AS fytdiss, dbo.GetItemMTDReceipts(fac, fpartno, frev, GETDATE()) AS fmtdrcpt, 
	                      dbo.GetItemYTDReceipts(fac, fpartno, frev, GETDATE()) AS fytdrcpt
	FROM         dbo.inmastx
GO
/****** Object:  View [dbo].[Labor - 2]    Script Date: 4/24/2018 7:54:15 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[Labor - 2]
AS
SELECT     TOP (100) PERCENT '' AS ItemNumber, '' AS UserNumber, 0 AS Qty, 0 AS UnitCost, dbo.ladetail.fdate AS Date, '' AS ItemDescription, '' AS TBJobNumber, '' AS Plant, 
  dbo.jomast.fjob_name AS JobName, dbo.inmast.fpartno as PartNumber, dbo.inmast.f2totcost AS PartPrice, dbo.ladetail.fcompqty AS CompletedQty
FROM         dbo.jomast INNER JOIN
                      dbo.ladetail ON dbo.jomast.fjobno = dbo.ladetail.fjobno INNER JOIN
                      dbo.inmast ON dbo.jomast.fpartno = dbo.inmast.fpartno AND dbo.jomast.fpartrev = dbo.inmast.frev
WHERE     (dbo.ladetail.fdate > CONVERT(DATETIME, '2007-01-01 00:00:00', 102)) AND (dbo.jomast.fitype = '1') AND (NOT (dbo.jomast.fpartno LIKE '%LATHE%')) AND 
                      (NOT (dbo.jomast.fpartno LIKE '%MILL%')) AND (NOT (dbo.jomast.fpartno LIKE '%DEBURR%')) AND (NOT (dbo.jomast.fpartno LIKE '%PRECUT%')) AND 
                      (NOT (dbo.jomast.fpartno LIKE 'TOOL GRINDING'))


GO
/****** Object:  View [dbo].[Labor - 1]    Script Date: 4/24/2018 7:54:15 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[Labor - 1]
AS
SELECT     TOP (100) PERCENT '' AS ItemNumber, '' AS UserNumber, 0 AS Qty, 0 AS UnitCost, dbo.ladetail.fdate AS Date, '' AS ItemDescription, '' AS TBJobNumber, '' AS Plant, 
                      dbo.jomast.fjob_name AS JobName, dbo.inmast.f2totcost AS PartPrice, dbo.ladetail.fcompqty AS CompletedQty
FROM         dbo.jomast INNER JOIN
                      dbo.ladetail ON dbo.jomast.fjobno = dbo.ladetail.fjobno INNER JOIN
                      dbo.inmast ON dbo.jomast.fpartno = dbo.inmast.fpartno AND dbo.jomast.fpartrev = dbo.inmast.frev
WHERE     (dbo.ladetail.fdate > CONVERT(DATETIME, '2007-01-01 00:00:00', 102)) AND (dbo.jomast.fitype = '1') AND (NOT (dbo.jomast.fpartno LIKE '%LATHE%')) AND 
                      (NOT (dbo.jomast.fpartno LIKE '%MILL%')) AND (NOT (dbo.jomast.fpartno LIKE '%DEBURR%')) AND (NOT (dbo.jomast.fpartno LIKE '%PRECUT%')) AND 
                      (NOT (dbo.jomast.fpartno LIKE 'TOOL GRINDING'))

GO
/****** Object:  View [dbo].[Labor - JT]    Script Date: 4/24/2018 7:54:15 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[Labor - JT]
AS
SELECT DISTINCT TOP (100) PERCENT dbo.jomast.fjob_name AS JobName, dbo.jomast.fpartno
FROM         dbo.jomast INNER JOIN
                      dbo.ladetail ON dbo.jomast.fjobno = dbo.ladetail.fjobno INNER JOIN
                      dbo.inmast ON dbo.jomast.fpartno = dbo.inmast.fpartno AND dbo.jomast.fpartrev = dbo.inmast.frev
WHERE     (dbo.ladetail.fdate > CONVERT(DATETIME, '2007-01-01 00:00:00', 102)) AND (dbo.jomast.fitype = '1') AND (NOT (dbo.jomast.fpartno LIKE '%LATHE%')) 
                      AND (NOT (dbo.jomast.fpartno LIKE '%MILL%')) AND (NOT (dbo.jomast.fpartno LIKE '%DEBURR%')) AND (NOT (dbo.jomast.fpartno LIKE '%PRECUT%')) 
                      AND (NOT (dbo.jomast.fpartno LIKE 'TOOL GRINDING'))


GO
/****** Object:  View [dbo].[Material Cost Per Part]    Script Date: 4/24/2018 7:54:15 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[Material Cost Per Part]
AS
SELECT     dbo.inboms.fparent, dbo.inboms.fparentrev, SUM(dbo.inboms.fqty * dbo.inmast.fprice) AS [Material Cost]
FROM         dbo.inmast INNER JOIN
                      dbo.inboms ON dbo.inmast.fpartno = dbo.inboms.fcomponent AND dbo.inmast.frev = dbo.inboms.fcomprev
GROUP BY dbo.inboms.fparent, dbo.inboms.fparentrev


GO
/****** Object:  View [dbo].[Combine Jobs]    Script Date: 4/24/2018 7:54:15 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[Combine Jobs]
AS
SELECT     JobNumber, Descr, Alias, 2 AS Plant
FROM         dbo.Jobs2
UNION ALL
SELECT     JobNumber, Descr, Alias, 3 AS Plant
FROM         dbo.Jobs3
UNION ALL
SELECT     JobNumber, Descr, Alias, 5 AS Plant
FROM         dbo.Jobs5
UNION ALL
SELECT     JobNumber, Descr, Alias, 6 AS Plant
FROM         dbo.Jobs6
UNION ALL
SELECT     JobNumber, Descr, Alias, 7 AS Plant
FROM         dbo.Jobs7
UNION ALL
SELECT     JobNumber, Descr, Alias, 8 AS Plant
FROM         dbo.Jobs8


GO
/****** Object:  View [dbo].[Combine Transactions]    Script Date: 4/24/2018 7:54:15 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[Combine Transactions]
AS
SELECT     dbo.TransactionLog2.TransCode, dbo.TransactionLog2.ItemNumber, dbo.TransactionLog2.JobNumber, dbo.TransactionLog2.Qty, 
                      dbo.TransactionLog2.UNITCOST, dbo.TransactionLog2.TranStartDateTime, dbo.TransactionLog2.UserNumber, dbo.Users2.Descr, 2 AS Plant
FROM         dbo.TransactionLog2 INNER JOIN
                      dbo.Users2 ON dbo.TransactionLog2.UserNumber = dbo.Users2.UserNumber
WHERE     (YEAR(dbo.TransactionLog2.TranStartDateTime) > 2005)
UNION ALL
SELECT     dbo.TransactionLog3.TransCode, dbo.TransactionLog3.ItemNumber, dbo.TransactionLog3.JobNumber, dbo.TransactionLog3.Qty, 
                      dbo.TransactionLog3.UNITCOST, dbo.TransactionLog3.TranStartDateTime, dbo.TransactionLog3.UserNumber, dbo.Users3.Descr, 3 AS Plant
FROM         dbo.TransactionLog3 INNER JOIN
                      dbo.Users3 ON dbo.TransactionLog3.UserNumber = dbo.Users3.UserNumber
WHERE     (YEAR(dbo.TransactionLog3.TranStartDateTime) > 2005)
UNION ALL
SELECT     dbo.TransactionLog5.TransCode, dbo.TransactionLog5.ItemNumber, dbo.TransactionLog5.JobNumber, dbo.TransactionLog5.Qty, 
                      dbo.TransactionLog5.UNITCOST, dbo.TransactionLog5.TranStartDateTime, dbo.TransactionLog5.UserNumber, dbo.Users5.Descr, 5 AS Plant
FROM         dbo.TransactionLog5 INNER JOIN
                      dbo.Users5 ON dbo.TransactionLog5.UserNumber = dbo.Users5.UserNumber
WHERE     (YEAR(dbo.TransactionLog5.TranStartDateTime) > 2005)
UNION ALL
SELECT     dbo.TransactionLog6.TransCode, dbo.TransactionLog6.ItemNumber, dbo.TransactionLog6.JobNumber, dbo.TransactionLog6.Qty, 
                      dbo.TransactionLog6.UNITCOST, dbo.TransactionLog6.TranStartDateTime, dbo.TransactionLog6.UserNumber, dbo.Users6.Descr, 6 AS Plant
FROM         dbo.TransactionLog6 INNER JOIN
                      dbo.Users6 ON dbo.TransactionLog6.UserNumber = dbo.Users6.UserNumber
WHERE     (YEAR(dbo.TransactionLog6.TranStartDateTime) > 2005)
UNION ALL
SELECT     dbo.TransactionLog7.TransCode, dbo.TransactionLog7.ItemNumber, dbo.TransactionLog7.JobNumber, dbo.TransactionLog7.Qty, 
                      dbo.TransactionLog7.UNITCOST, dbo.TransactionLog7.TranStartDateTime, dbo.TransactionLog7.UserNumber, dbo.Users7.Descr, 7 AS Plant
FROM         dbo.TransactionLog7 INNER JOIN
                      dbo.Users7 ON dbo.TransactionLog7.UserNumber = dbo.Users7.UserNumber
WHERE     (YEAR(dbo.TransactionLog7.TranStartDateTime) > 2005)
UNION ALL
SELECT     dbo.TransactionLog8.TransCode, dbo.TransactionLog8.ItemNumber, dbo.TransactionLog8.JobNumber, dbo.TransactionLog8.Qty, 
                      dbo.TransactionLog8.UNITCOST, dbo.TransactionLog8.TranStartDateTime, dbo.TransactionLog8.UserNumber, dbo.Users8.Descr, 8 AS Plant
FROM         dbo.TransactionLog8 INNER JOIN
                      dbo.Users8 ON dbo.TransactionLog8.UserNumber = dbo.Users8.UserNumber
WHERE     (YEAR(dbo.TransactionLog8.TranStartDateTime) > 2005)


GO
/****** Object:  View [dbo].[Tooling - 1 Rev A]    Script Date: 4/24/2018 7:54:15 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[Tooling - 1 Rev A]
AS
SELECT     dbo.[Combine Transactions].ItemNumber, dbo.[Combine Transactions].UserNumber, dbo.[Combine Transactions].Qty, 
                      dbo.[Combine Transactions].UNITCOST, dbo.[Combine Transactions].TranStartDateTime AS Date, 
                      dbo.[Combine Transactions].Descr AS ItemDescription, dbo.[Combine Transactions].JobNumber AS TBJobNumber, dbo.[Combine Transactions].Plant, 
                      dbo.[Combine Jobs].Alias AS JobName, 0 AS PartPrice, 0 AS CompletedQty
FROM         dbo.[Combine Transactions] INNER JOIN
                      dbo.[Combine Jobs] ON dbo.[Combine Transactions].JobNumber = dbo.[Combine Jobs].JobNumber
WHERE     (dbo.[Combine Transactions].TransCode = N'WN')


GO
/****** Object:  View [dbo].[Tooling - 1]    Script Date: 4/24/2018 7:54:15 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[Tooling - 1]
AS
SELECT     dbo.[Combine Transactions].ItemNumber, dbo.[Combine Transactions].UserNumber, dbo.[Combine Transactions].Qty, 
                      dbo.[Combine Transactions].UNITCOST, { fn WEEK(dbo.[Combine Transactions].TranStartDateTime) } AS Week, 
                      dbo.[Combine Transactions].TranStartDateTime, dbo.[Combine Transactions].Descr, YEAR(dbo.[Combine Transactions].TranStartDateTime) AS YEAR, 
                      dbo.[Combine Transactions].JobNumber, dbo.[Combine Transactions].Plant, dbo.[Combine Jobs].Alias
FROM         dbo.[Combine Transactions] INNER JOIN
                      dbo.[Combine Jobs] ON dbo.[Combine Transactions].JobNumber = dbo.[Combine Jobs].JobNumber AND 
                      dbo.[Combine Transactions].Plant = dbo.[Combine Jobs].Plant
WHERE     (dbo.[Combine Transactions].TransCode = N'WN')


GO
/****** Object:  View [dbo].[ShNoInvc]    Script Date: 4/24/2018 7:54:15 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[ShNoInvc] 
AS 
SELECT b.fshipno AS SHIPNO 
FROM ( SELECT shitem.fsokey 
FROM shitem Join sorels 
ON sorels.fsono = substring(shitem.fsokey,1,6) 
and sorels.finumber = substring(shitem.fsokey,7,3) 
and sorels.frelease = substring(shitem.fsokey,10,3) 
and sorels.flinvcposs = 1 AND sorels.fmasterrel = 0 AND sorels.fcpbtype = '' 
UNION ALL SELECT '' AS fsokey ) A 
Join dbo.shitem B 
ON b.fsokey=a.fsokey And b.flInvcPoss = 1 and b.fitemtype <> 'M' 
Group By b.fshipno 

GO
/****** Object:  View [dbo].[ShIInvc]    Script Date: 4/24/2018 7:54:15 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[ShIInvc] 
AS 
SELECT shmast.fshipno, shmast.fshipdate, shmast.fcnumber, shmast.fbl_lading, shmast.ftype, shmast.fno_boxes, shmast.fshipwght, shmast.fcjobno, 
shmast.fcpono, shmast.fcvendno, shmast.fcsono, shmast.fcsorev, slcdpm.fcompany, slcdpm.fcontact, slcdpm.fphone, SUBSTRING(slcdpm.fmstreet,1,40) AS fstreet, 
slcdpm.fcity, slcdpm.fstate, slcdpm.fzip, slcdpm.fcountry, shitem.fenumber, shitem.fpartno, 
(CASE WHEN inmast.fluseudrev = 1 THEN Shitem.fcudrev ELSE Shitem.frev END) AS frev, shitem.fac, shitem.fshipqty, shitem.finvqty, 
SUBSTRING(shitem.fmdescript,1,35) AS fdescr, SHITEM.Identity_Column 
FROM ShNoInvc 
INNER JOIN SHMAST ON SHMAST.FSHIPNO = ShNoInvc.SHIPNO and (shmast.fcNumber <> '') and (shmast.fconfirm = 'Y') AND shmast.flisinv <> 1 AND shmast.ftype not in ('VE','JO') 
INNER JOIN SHITEM ON shitem.fshipno = ShNoInvc.shipno and shitem.fitemtype <> 'M' And shitem.fShipqty>shitem.finvqty 
INNER JOIN SLCDPMX SLCDPM ON SLCDPM.FCUSTNO=SHMAST.FCNUMBER 
LEFT JOIN INMASTX INMAST ON inmast.fpartno=shitem.fpartno AND inmast.frev = shitem.frev AND inmast.fac = shitem.fac 

GO
/****** Object:  View [dbo].[Tooling - 1 Rev B]    Script Date: 4/24/2018 7:54:15 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[Tooling - 1 Rev B]
AS
SELECT     dbo.[Combine Transactions].ItemNumber, dbo.[Combine Transactions].UserNumber, dbo.[Combine Transactions].Qty, 
                      dbo.[Combine Transactions].UNITCOST, dbo.[Combine Transactions].TranStartDateTime AS Date, 
                      dbo.[Combine Transactions].Descr AS ItemDescription, dbo.[Combine Transactions].JobNumber AS TBJobNumber, dbo.[Combine Transactions].Plant, 
                      dbo.JobTranslation.JobName, 0 AS PartPrice, 0 AS CompletedQty
FROM         dbo.[Combine Transactions] INNER JOIN
                      dbo.JobTranslation ON dbo.[Combine Transactions].JobNumber = dbo.JobTranslation.TBJobNumber AND 
                      dbo.[Combine Transactions].Plant = dbo.JobTranslation.Plant
WHERE     (dbo.[Combine Transactions].TransCode = N'WN')


GO
/****** Object:  View [dbo].[Grouped Tooling & Labor]    Script Date: 4/24/2018 7:54:15 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[Grouped Tooling & Labor]
AS
SELECT     ItemNumber, UserNumber, Qty, UnitCost, Date, ItemDescription, TBJobNumber, Plant, JobName, PartPrice, CompletedQty
FROM         dbo.[Labor - 1]
UNION ALL
SELECT     TOP (100) PERCENT ItemNumber, UserNumber, Qty, UNITCOST, Date, ItemDescription, TBJobNumber, Plant, JobName, PartPrice, CompletedQty
FROM         dbo.[Tooling - 1 Rev B]
ORDER BY Date DESC

GO
/****** Object:  View [dbo].[Grouped Tooling & Labor Rev A]    Script Date: 4/24/2018 7:54:15 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[Grouped Tooling & Labor Rev A]
AS
SELECT     ItemNumber, UserNumber, Qty, UnitCost, Date, ItemDescription, TBJobNumber, Plant, JobName, PartPrice, CompletedQty
FROM         dbo.[Labor - 1]
UNION ALL
SELECT     TOP (100) PERCENT ItemNumber, UserNumber, Qty, UNITCOST, Date, ItemDescription, TBJobNumber, Plant, JobName, PartPrice, CompletedQty
FROM         dbo.[Tooling - 1 Rev B]
ORDER BY Date DESC
GO
/****** Object:  View [dbo].[accountingyears]    Script Date: 4/24/2018 7:54:15 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[accountingyears]
AS
SELECT glrule.fcname, MIN(glrule.fdstart) AS min_fdstart, 
    MAX(glrule.fdend) AS max_fdend, MAX(glrule.fnnumber) 
    AS max_fnnumber, MIN(glrule.fcstatus) AS min_fcstatus, glrule.identity_column
FROM glrule
GROUP BY glrule.fcname, glrule.identity_column

GO
/****** Object:  View [dbo].[APPAIDTODATE]    Script Date: 4/24/2018 7:54:15 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[APPAIDTODATE]
AS
SELECT 	Apmast.fvendno+Apmast.fcinvoice 			AS fcinvkey,
	SUM(Glcshi.fncashamt+Glcshi.fnadjamt+Glcshi.fndiscount) AS amount,
	SUM(Glcshi.fncashamt) 					AS cashamt, 
	SUM(Glcshi.fndiscount) 					AS discount,
	SUM(Glcshi.fnadjamt) 					AS adjust
FROM 	apmast
	JOIN glcshi ON (apmast.fcinvoice = glcshi.fcinvoice)
	JOIN glcshm ON (apmast.fvendno = glcshm.fcnameid AND glcshi.fccashnum = glcshm.fccashnum)
WHERE 	Glcshm.fcpayclass = 'P'
  AND 	Glcshi.fcpayclass = 'P'
  AND   Apmast.fcstatus <> 'F'
GROUP BY Apmast.fvendno+Apmast.fcinvoice

GO
/****** Object:  View [dbo].[apvend]    Script Date: 4/24/2018 7:54:15 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ******************************************************************************************

	-- **********************************************************************************************************************************************************
	-- Create new view and instead of trigger based on the renamed table.		
	CREATE VIEW [dbo].[apvend]
	AS
	SELECT     *, dbo.GetVendLastPayment(fvendno) AS flpayment, dbo.GetVendLastPayDate(fvendno) AS flpaydate, dbo.GetVendYTDPurchases(fvendno, GETDATE()) 
	                      AS fytdpur, dbo.GetVendorBalance(fvendno) AS fbal
	FROM         dbo.apvendx
GO
/****** Object:  View [dbo].[ARPAIDTODATE]    Script Date: 4/24/2018 7:54:15 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[ARPAIDTODATE]
AS
SELECT 	Armast.fcinvoice 						AS fcinvoice,
	SUM(Glcshi.fncashamt+Glcshi.fnadjamt+Glcshi.fndiscount) 	AS amount,
	SUM(Glcshi.fncashamt) 						AS cashamt, 
	SUM(Glcshi.fndiscount) 						AS discount,
	SUM(Glcshi.fnadjamt) 						AS adjust
FROM 	armast
	JOIN glcshi ON (armast.fcinvoice = glcshi.fcinvoice)
	JOIN glcshm ON (glcshi.fccashnum = glcshm.fccashnum)
WHERE 	Glcshm.fcpayclass = 'R'
  AND 	Glcshi.fcpayclass = 'R'
  AND 	Glcshm.fcstatus = 'P'
  AND 	Armast.fcstatus = 'P'
  AND 	Glcshi.fctype <> 'C'
  AND 	Glcshi.fctype <> 'B'
GROUP BY Armast.fcinvoice

GO
/****** Object:  View [dbo].[bvActiveJobNoToolListWeek]    Script Date: 4/24/2018 7:54:15 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view [dbo].[bvActiveJobNoToolListWeek]   
AS
select * from dbo.bfActiveJobNoToolListWeek()

GO
/****** Object:  View [dbo].[bvDistinctMonthToolLife]    Script Date: 4/24/2018 7:54:15 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--///////////////////////////////////////////////////////////////////////////////////
-- Creates a recordset of distinct yearMonth values in the btMonthToolLife table
--///////////////////////////////////////////////////////////////////////////////////
create view [dbo].[bvDistinctMonthToolLife] 
AS
select distinct yearMonth from btMonthToolLife

GO
/****** Object:  View [dbo].[bvDistinctPartNumberItems]    Script Date: 4/24/2018 7:54:15 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[bvDistinctPartNumberItems]
as
-- Remove duplicates only differing in plant
select distinct PartNumber,itemNumber
from
btDistinctToollistitems

GO
/****** Object:  View [dbo].[bvDistinctPartNumbers]    Script Date: 4/24/2018 7:54:15 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[bvDistinctPartNumbers]
as
-- Remove duplicates only differing in plant
select distinct PartNumber
from
toollists

GO
/****** Object:  View [dbo].[bvDistinctToolLists]    Script Date: 4/24/2018 7:54:15 AM ******/
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
toollists
group by 
OriginalProcessId,ProcessId,
Customer,PartFamily,OperationDescription,PartNumber,Descript,descr

GO
/****** Object:  View [dbo].[bvGetPnDescript]    Script Date: 4/24/2018 7:54:15 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[bvGetPnDescript]
AS
-- add description for the latest rev
select lv1.fpartno,fdescript
from (
	select fpartno, max(frev) as frev
	from inmastx
	group by fpartno
) as lv1 left outer join
inmastx 
on lv1.fpartno = inmastx.fpartno
and lv1.frev = inmastx.frev

GO
/****** Object:  View [dbo].[bvItemIssued]    Script Date: 4/24/2018 7:54:15 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--///////////////////////////////////////////////////////////////////////////////////
-- For each translog items create a record containing newIssuedTotQty,newIssuedTotCost,
-- rwkIssuedTotQty,rwkIssuedTotCost, issuedTotQty,issuedTotCost
--///////////////////////////////////////////////////////////////////////////////////
create view [dbo].[bvItemIssued] 
AS
	select 
	case 
		when new.PartNumber is null then rwk.PartNumber
		else new.PartNumber
	end partNumber,
	case 
		when new.ItemNumber is null then SUBSTRING(rwk.ItemNumber,1,len(rwk.ItemNumber)-1)
		else new.ItemNumber
	end newItemNumber,
	case 
		when rwk.ItemNumber is null then new.ItemNumber + 'R'
		else rwk.ItemNumber 
	end rwkItemNumber,
	case
		when new.newIssuedTotQty is null then 0
		else new.newIssuedTotQty
	end newIssuedTotQty,
	case
		when new.newIssuedTotCost is null then 0.0
		else new.newIssuedTotCost
	end newIssuedTotCost,
	case
		when rwk.rwkIssuedTotQty is null then 0
		else rwk.rwkIssuedTotQty
	end rwkIssuedTotQty,
	case
		when rwk.rwkIssuedTotCost is null then 0.0
		else rwk.rwkIssuedTotCost
	end rwkIssuedTotCost
	from
	(
		select partNumber,itemNumber,
		sum(qty) newIssuedTotQty, sum(qty*unitCost) newIssuedTotCost 
		from btTransLogMonth
		group by partNumber,ItemNumber
		having ItemNumber <> '' and ItemNumber <> '.'
		and itemNumber not like '%R'
		--2613
	)new
	full join
	(
		select partNumber,itemNumber,
		sum(qty) rwkIssuedTotQty, sum(qty*unitCost) rwkIssuedTotCost 
		from btTransLogMonth
		group by partNumber,ItemNumber
		having ItemNumber <> '' and ItemNumber <> '.'
		and itemNumber like '%R'
		--80
	)rwk
	--2693
	on
	new.PartNumber=rwk.partNumber and
	new.ItemNumber=SUBSTRING(rwk.ItemNumber,1,len(rwk.ItemNumber)-1)
	--2672


GO
/****** Object:  View [dbo].[bvNoValueAddSalesOrToolAllowanceWeek]    Script Date: 4/24/2018 7:54:15 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[bvNoValueAddSalesOrToolAllowanceWeek]
as
select * from bfNoValueAddSalesOrToolAllowanceWeek() 

GO
/****** Object:  View [dbo].[bvNoValueAddSalesWeek]    Script Date: 4/24/2018 7:54:15 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[bvNoValueAddSalesWeek]
as
select * from bfNoValueAddSalesWeek() 
GO
/****** Object:  View [dbo].[bvNoVendorCostWeek]    Script Date: 4/24/2018 7:54:15 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[bvNoVendorCostWeek]
as 
select * from  bfNoVendorCostWeek()


GO
/****** Object:  View [dbo].[bvPartDescr]    Script Date: 4/24/2018 7:54:15 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[bvPartDescr]
as
	-- add toollists to summary
	select lv1.*, tl.toollists
	from
	( 
		select dtl.PartNumber,Customer,PartFamily,CustPartFamily
		from
		(
			-- pick a toollist to represent all those associated
			-- with a partNumber
			select partNumber,max(originalProcessId) maxOrigPID
			from toollists 
			group by partNumber
			-- 529
		) tlm
		inner join
		(
			select 	* from bvDistinctToolLists 
			-- 729
		) dtl	
		on
		tlm.maxOrigPID=dtl.originalprocessid
	) lv1
	inner join
	pntoollists tl
	on lv1.partNumber= tl.partNumber

GO
/****** Object:  View [dbo].[Downtime Prep BCRAW]    Script Date: 4/24/2018 7:54:15 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[Downtime Prep BCRAW]
AS
SELECT        TOP (100) PERCENT RIGHT(fjobno, 10) AS Jobnumber, DATEADD(mi, CAST(RIGHT(ftime, 2) AS NUMERIC), DATEADD(hh, CAST(LEFT(ftime, 2) AS numeric), frdate)) 
                         AS Expr1, fclot, RIGHT(LEFT(fempno, 5), 4) AS EmpNumber, CAST(SUBSTRING(foperno, 2, 3) AS numeric) AS foperno, frdate
FROM            dbo.bcraw
WHERE        (RIGHT(fjobno, 10) = 'I3393-0000' OR
                         RIGHT(fjobno, 10) = 'I3394-0000' OR
                         RIGHT(fjobno, 10) = 'I3395-0000' OR
                         RIGHT(fjobno, 10) = 'I3396-0000' OR
                         RIGHT(fjobno, 10) = 'I3397-0000' OR
                         RIGHT(fjobno, 10) = 'I4180-0000' OR
                         RIGHT(fjobno, 10) = 'I4911-0000' OR
                         RIGHT(fjobno, 10) = 'I4912-0000' OR
                         RIGHT(fjobno, 10) = 'I4913-0000' OR
                         RIGHT(fjobno, 10) = 'I4914-0000' OR
                         RIGHT(fjobno, 10) = 'I4915-0000' OR
                         RIGHT(fjobno, 10) = 'I4916-0000' OR
                         RIGHT(fjobno, 10) = 'I4917-0000' OR
                         RIGHT(fjobno, 10) = 'IA869-0000' OR
                         RIGHT(fjobno, 10) = 'IB238-0000' OR
                         RIGHT(fjobno, 10) = 'IB239-0000' OR
                         RIGHT(fjobno, 10) = 'IB240-0000' OR
                         RIGHT(fjobno, 10) = 'IB241-0000' OR
                         RIGHT(fjobno, 10) = 'IB242-0000' OR
                         RIGHT(fjobno, 10) = 'IB243-0000' OR
                         RIGHT(fjobno, 10) = 'IC064-0000' OR
                         RIGHT(fjobno, 10) = 'IC065-0000' OR
                         RIGHT(fjobno, 10) = 'IC066-0000' OR
                         RIGHT(fjobno, 10) = 'IC056-0000' OR
                         RIGHT(fjobno, 10) = 'IC067-0000' OR
                         RIGHT(fjobno, 10) = 'IC068-0000' OR
                         RIGHT(fjobno, 10) = 'IC069-0000' OR
                         RIGHT(fjobno, 10) = 'ID193-0000' OR
                         RIGHT(fjobno, 10) = 'ID194-0000' OR
                         RIGHT(fjobno, 10) = 'ID195-0000' OR
                         RIGHT(fjobno, 10) = 'ID196-0000' OR
                         RIGHT(fjobno, 10) = 'ID197-0000' OR
                         RIGHT(fjobno, 10) = 'ID198-0000' OR
                         RIGHT(fjobno, 10) = 'ID199-0000' OR
                         RIGHT(fjobno, 10) = 'IE406-0000' OR
                         RIGHT(fjobno, 10) = 'IE407-0000' OR
                         RIGHT(fjobno, 10) = 'IE408-0000' OR
                         RIGHT(fjobno, 10) = 'IE409-0000' OR
                         RIGHT(fjobno, 10) = 'IE410-0000' OR
                         RIGHT(fjobno, 10) = 'IE411-0000' OR
                         RIGHT(fjobno, 10) = 'IE412-0000' OR
                         RIGHT(fjobno, 10) = 'IF515-0000' OR
                         RIGHT(fjobno, 10) = 'IF516-0000' OR
                         RIGHT(fjobno, 10) = 'IF517-0000' OR
                         RIGHT(fjobno, 10) = 'IF518-0000' OR
                         RIGHT(fjobno, 10) = 'IF519-0000' OR
                         RIGHT(fjobno, 10) = 'IF520-0000' OR
                         RIGHT(fjobno, 10) = 'IF521-0000' OR
                         RIGHT(fjobno, 10) = 'IG639-0000' OR
                         RIGHT(fjobno, 10) = 'IG640-0000' OR
                         RIGHT(fjobno, 10) = 'IG641-0000' OR
                         RIGHT(fjobno, 10) = 'IG642-0000' OR
                         RIGHT(fjobno, 10) = 'IG643-0000' OR
                         RIGHT(fjobno, 10) = 'IG644-0000' OR
                         RIGHT(fjobno, 10) = 'IG645-0000' OR
                         RIGHT(fjobno, 10) = 'IG646-0000' OR
                         RIGHT(fjobno, 10) = 'IH339-0000' OR
                         RIGHT(fjobno, 10) = 'IH340-0000' OR
                         RIGHT(fjobno, 10) = 'IH341-0000' OR
                         RIGHT(fjobno, 10) = 'IH342-0000' OR
                         RIGHT(fjobno, 10) = 'IH356-0000' OR
                         RIGHT(fjobno, 10) = 'IH381-0000' OR
                         RIGHT(fjobno, 10) = 'IH399-0000' OR
                         RIGHT(fjobno, 10) = 'IH400-0000' OR
                         RIGHT(fjobno, 10) = 'II379-0000' OR
                         RIGHT(fjobno, 10) = 'II380-0000' OR
                         RIGHT(fjobno, 10) = 'II381-0000' OR
                         RIGHT(fjobno, 10) = 'II382-0000' OR
                         RIGHT(fjobno, 10) = 'II383-0000' OR
                         RIGHT(fjobno, 10) = 'II384-0000' OR
                         RIGHT(fjobno, 10) = 'II385-0000' OR
                         RIGHT(fjobno, 10) = 'II386-0000' OR
                         RIGHT(fjobno, 10) = 'IJ747-0000' OR
                         RIGHT(fjobno, 10) = 'IJ748-0000' OR
                         RIGHT(fjobno, 10) = 'IJ749-0000' OR
                         RIGHT(fjobno, 10) = 'IJ750-0000' OR
                         RIGHT(fjobno, 10) = 'IJ751-0000' OR
                         RIGHT(fjobno, 10) = 'IJ752-0000' OR
                         RIGHT(fjobno, 10) = 'IJ753-0000' OR
                         RIGHT(fjobno, 10) = 'IJ754-0000' OR
                         RIGHT(fjobno, 10) = 'IK546-0000' OR
                         RIGHT(fjobno, 10) = 'IK547-0000' OR
                         RIGHT(fjobno, 10) = 'IK548-0000' OR
                         RIGHT(fjobno, 10) = 'IK549-0000' OR
                         RIGHT(fjobno, 10) = 'IK550-0000' OR
                         RIGHT(fjobno, 10) = 'IK551-0000' OR
                         RIGHT(fjobno, 10) = 'IK552-0000' OR
                         RIGHT(fjobno, 10) = 'IK553-0000' OR
                         RIGHT(fjobno, 10) = 'IM048-0000' OR
                         RIGHT(fjobno, 10) = 'IM049-0000' OR
                         RIGHT(fjobno, 10) = 'IM050-0000' OR
                         RIGHT(fjobno, 10) = 'IM051-0000' OR
                         RIGHT(fjobno, 10) = 'IM052-0000' OR
                         RIGHT(fjobno, 10) = 'IM053-0000' OR
                         RIGHT(fjobno, 10) = 'IM054-0000' OR
                         RIGHT(fjobno, 10) = 'IM055-0000' OR
                         RIGHT(fjobno, 10) = 'IN087-0000' OR
                         RIGHT(fjobno, 10) = 'IN088-0000' OR
                         RIGHT(fjobno, 10) = 'IN089-0000' OR
                         RIGHT(fjobno, 10) = 'IN090-0000' OR
                         RIGHT(fjobno, 10) = 'IN091-0000' OR
                         RIGHT(fjobno, 10) = 'IN092-0000' OR
                         RIGHT(fjobno, 10) = 'IN093-0000' OR
                         RIGHT(fjobno, 10) = 'IN094-0000' OR
                         RIGHT(fjobno, 10) = 'IO235-0000' OR
                         RIGHT(fjobno, 10) = 'IO236-0000' OR
                         RIGHT(fjobno, 10) = 'IO237-0000' OR
                         RIGHT(fjobno, 10) = 'IO238-0000' OR
                         RIGHT(fjobno, 10) = 'IO239-0000' OR
                         RIGHT(fjobno, 10) = 'IO240-0000' OR
                         RIGHT(fjobno, 10) = 'IO241-0000' OR
                         RIGHT(fjobno, 10) = 'IO242-0000' OR
                         RIGHT(fjobno, 10) = 'IP345-0000' OR
                         RIGHT(fjobno, 10) = 'IP346-0000' OR
                         RIGHT(fjobno, 10) = 'IP351-0000' OR
                         RIGHT(fjobno, 10) = 'IP352-0000' OR
                         RIGHT(fjobno, 10) = 'IP353-0000' OR
                         RIGHT(fjobno, 10) = 'IP354-0000' OR
                         RIGHT(fjobno, 10) = 'IP355-0000' OR
                         RIGHT(fjobno, 10) = 'IP356-0000' OR
                         RIGHT(fjobno, 10) = 'IQ198-0000' OR
                         RIGHT(fjobno, 10) = 'IQ248-0000' OR
                         RIGHT(fjobno, 10) = 'IQ254-0000' OR
                         RIGHT(fjobno, 10) = 'IQ256-0000' OR
                         RIGHT(fjobno, 10) = 'IQ262-0000' OR
                         RIGHT(fjobno, 10) = 'IQ264-0000' OR
                         RIGHT(fjobno, 10) = 'IQ268-0000' OR
                         RIGHT(fjobno, 10) = 'IQ356-0000' OR
                         RIGHT(fjobno, 10) = 'IR458-0000' OR
                         RIGHT(fjobno, 10) = 'IR459-0000' OR
                         RIGHT(fjobno, 10) = 'IR460-0000' OR
                         RIGHT(fjobno, 10) = 'IR461-0000' OR
                         RIGHT(fjobno, 10) = 'IR462-0000' OR
                         RIGHT(fjobno, 10) = 'IR463-0000' OR
                         RIGHT(fjobno, 10) = 'IR464-0000' OR
                         RIGHT(fjobno, 10) = 'IR465-0000' OR
                         RIGHT(fjobno, 10) = 'IS581-0000' OR
                         RIGHT(fjobno, 10) = 'IS582-0000' OR
                         RIGHT(fjobno, 10) = 'IS583-0000' OR
                         RIGHT(fjobno, 10) = 'IS584-0000' OR
                         RIGHT(fjobno, 10) = 'IS585-0000' OR
                         RIGHT(fjobno, 10) = 'IS586-0000' OR
                         RIGHT(fjobno, 10) = 'IS587-0000' OR
                         RIGHT(fjobno, 10) = 'IS588-0000' OR
                         RIGHT(fjobno, 10) = 'IT811-0000' OR
                         RIGHT(fjobno, 10) = 'IT812-0000' OR
                         RIGHT(fjobno, 10) = 'IT814-0000' OR
                         RIGHT(fjobno, 10) = 'IT820-0000' OR
                         RIGHT(fjobno, 10) = 'IT815-0000' OR
                         RIGHT(fjobno, 10) = 'IT816-0000' OR
                         RIGHT(fjobno, 10) = 'IT817-0000' OR
                         RIGHT(fjobno, 10) = 'IT818-0000' OR
                         RIGHT(fjobno, 10) = 'IT846-0000' OR

                         RIGHT(fjobno, 10) = 'I4772-0000') AND (frdate > CONVERT(DATETIME, '2007-01-01 00:00:00', 102)) AND (ftime <> '')
ORDER BY Jobnumber

GO
/****** Object:  View [dbo].[FRxBud]    Script Date: 4/24/2018 7:54:15 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create  VIEW [dbo].[FRxBud] AS 
Select plbudg.fcname as BudgetName, fctgtacct as AcctCode, 10 as Period, fnper10 as Amount
from plbudg 
union
Select plbudg.fcname as BudgetName, fctgtacct as AcctCode, 11 as Period, fnper11 as Amount
from plbudg 
union 
Select plbudg.fcname as BudgetName, fctgtacct as AcctCode, 12 as Period, fnper12 as Amount
from plbudg 
union 
Select plbudg.fcname as BudgetName, fctgtacct as AcctCode, 13 as Period, fnper13 as Amount
from plbudg 
Union 
select name1 as BudgetName, acct as Acctcode, period as Period, functlamt as Amount
from FRxBudget

GO
/****** Object:  View [dbo].[FRxBudget]    Script Date: 4/24/2018 7:54:15 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create VIEW [dbo].[FRxBudget] AS 
Select plbudg.fcname as name1, fctgtacct as acct, 1 as period, fnper1 as functlamt
from plbudg 
union 
Select plbudg.fcname as name1, fctgtacct as acct, 2 as period, fnper2 as functlamt
from plbudg 
union 
Select plbudg.fcname as name1, fctgtacct as acct, 3 as period, fnper3 as functlamt
from plbudg 
union 
Select plbudg.fcname as name1, fctgtacct as acct, 4 as period, fnper4 as functlamt
from plbudg 
union 
Select plbudg.fcname as name1, fctgtacct as acct, 5 as period, fnper5 as functlamt
from plbudg 
union 
Select plbudg.fcname as name1, fctgtacct as acct, 6 as period, fnper6 as functlamt
from plbudg 
union 
Select plbudg.fcname as name1, fctgtacct as acct, 7 as period, fnper7 as functlamt
from plbudg 
union 
Select plbudg.fcname as name1, fctgtacct as acct, 8 as period, fnper8 as functlamt
from plbudg 
union 
Select plbudg.fcname as name1, fctgtacct as acct, 9 as period, fnper9 as functlamt
from plbudg 
GO
/****** Object:  View [dbo].[FRxJE]    Script Date: 4/24/2018 7:54:15 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[FRxJE] as 
SELECT *
 FROM gltran
 WHERE Gltran.fcrefclass = 'JE'
GO
/****** Object:  View [dbo].[FRxYears]    Script Date: 4/24/2018 7:54:15 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[FRxYears] AS 
SELECT fcName, MIN(fdStart) AS FYStart, MAX(fdEnd) AS FYEnd,
CASE fnFRxYr WHEN 0 THEN YEAR(MAX(fdEnd)) ELSE fnFRxYr END AS FYYear
FROM GLRule 
GROUP BY fnFRxYr, fcName
GO
/****** Object:  View [dbo].[inloca]    Script Date: 4/24/2018 7:54:15 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--Create view to support old inloca 'table'

CREATE VIEW [dbo].[inloca] AS SELECT * FROM dbo.location WITH CHECK OPTION
GO
/****** Object:  View [dbo].[MA_JobLaborDetail]    Script Date: 4/24/2018 7:54:15 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


----------------------------------------------------------------------------------------------
-- MA_JobLaborDetail returns raw actual labor data and employee information (primarily from ladetail) 
-- Note: we use CONVERT(DECIMAL(17,5), ...) to avoid LinqToSql overflow warnings.
----------------------------------------------------------------------------------------------
create view [dbo].[MA_JobLaborDetail] as
select fjobno as JobNo
		,foperno as OperationNo		
		,ladetail.fempno as EmployeeId
		,LTRIM(RTRIM(prempl.fname)) + ', ' + LTRIM(RTRIM(prempl.ffname)) as EmployeeName		
		,CASE WHEN FCODE1 = 'S' THEN 'Setup' ELSE 'Production' END AS LaborType
		,fsdatetime as StartDateTime
		,fedatetime as EndDateTime		
		,ISNULL(CONVERT(DECIMAL(17,5), CONVERT(DECIMAL(17,5), DATEDIFF(ss, ladetail.fsdatetime, ladetail.fedatetime))/3600),0) as LaborHours
		,fcompqty as CompletedQuantity
		,ftotpcost As LaborCost
		,ftotocost As OverheadCost		
from ladetail
LEFT JOIN prempl ON prempl.fempno = ladetail.fempno
where fstatus <> 'H'

GO
/****** Object:  View [dbo].[MA_JobMiscSummary]    Script Date: 4/24/2018 7:54:15 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


----------------------------------------------------------------------------------------------
-- MA_JobMiscSummary returns all misc costs associated with jobs
----------------------------------------------------------------------------------------------
create view [dbo].[MA_JobMiscSummary] as
select 
	fjob_so as JobNo
	,fcacctnum as GLAcctNo
	,fdate as CostDate
	,fnitemcost as ActualMiscCost
	,case ftrantype when 1 then 'Material' when 2 then 'Misc' end as CostType
	,fdesc as Description
	,fqty_req as Quantity
	,fpartno as PartNo
	,fpartrev as PartRev
	,fac as Facility
from ocmisc 
where ftype = 2 -- 2 = job

GO
/****** Object:  View [dbo].[MA_JobPartNumbers]    Script Date: 4/24/2018 7:54:15 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
		

----------------------------------------------------------------------------------------------
-- MA_JobPartNumbers returns distinct job part number from the joitem table;
-- The distinct is performed based on the part #, rev, and fac fields.
-- The part description and product class can be non-determinent
----------------------------------------------------------------------------------------------
create view [dbo].[MA_JobPartNumbers] as
select 
	fpartno as PartNo
	,fpartrev as PartRev
	,fac as PartFac
	,max(substring(fdesc,0,500)) as PartDesc
	,max(fprodcl) as ProductClass
from joitem
group by fpartno, fpartrev,fac


GO
/****** Object:  View [dbo].[MA_Main_JobAnalysis]    Script Date: 4/24/2018 7:54:15 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

----------------------------------------------------------------------------------------------
-- MA_Main_JobAnalysis returns the data used to power the main job analysis UI
-- Note: we use CONVERT(DECIMAL(17,5), ...) to avoid LinqToSql overflow warnings.
----------------------------------------------------------------------------------------------
CREATE view [dbo].[MA_Main_JobAnalysis] as 
select
	jomast.fjobno as JobNo	
	-- joitem
	,joitem.fpartno as PartNo
	,joitem.fpartrev as PartRev
	,joitem.fac as Facility	
	,joitem.fsource as PartSource
	,joitem.fdesc as PartDesc	
	,joitem.fgroup as GroupCode		
	,joitem.fprodcl as ProductClassCode		
	-- jomast
	,jomast.fglacct as GLAcctno
	,jomast.fact_rel as ReleaseDate
	,jomast.fddue_date as DueDate
	,jomast.fhold_dt as HoldDate 
	,jomast.fcus_id as CustomerNo
	,case when jomast.fdfnshdate > jomast.factschdfn then jomast.fdfnshdate else jomast.factschdfn end as FinishDate
	,jomast.ftype as JobType
	,jomast.fsub_from as ParentJobNo
	,jomast.fquantity as Quantity
	,jomast.fsono as SalesOrderNo
	,jomast.fschbefjob as SchedulingParentJobNo
	,jomast.fstatus as Status
	,jomast.ftot_assy as TotalAssociatedJobs
	-- jopact - Actuals	
	,jopact.flabact as LaborCost
	,jopact.fmatlact as MaterialCost
	,jopact.fothract as OtherCost
	,jopact.fovhdact as OverheadCost
	,jopact.fsetupact as SetupCost
	,jopact.fsubact as SubcontractingCost
	,jopact.ftoolact as ToolingCost
	,jopact.ftotptime + jopact.ftotstime as ActualHours
	-- jopest - Estimates
	,jopest.flabcost as EstimatedLaborCost
	,jopest.fmatlcost as EstimatedMaterialCost
	,jopest.fothrcost as EstimatedOtherCost
	,jopest.fovhdcost + jopest.fovhdsc as EstimatedOverheadCost
	,jopest.fsetupcost as EstimatedSetupCost
	,jopest.fsubcost as EstimatedSubcontractingCost
	,jopest.ftoolcost as EstimatedToolingCost
	,jopest.fsetuphrs + jopest.fprodhrs as EstimatedHours
	-- inmastx - Inventory cost (standard or average)
	,CONVERT(DECIMAL(17,5), case when (select top 1 utcomp.fcosttype from utcomp) ='S' then inmastx.flabcost else inmastx.f2labcost end * fquantity) as InventoryLaborCost
	,CONVERT(DECIMAL(17,5), case when (select top 1 utcomp.fcosttype from utcomp) ='S' then inmastx.fmatlcost else inmastx.f2matlcost end * fquantity) as InventoryMaterialCost
	,CONVERT(DECIMAL(17,5), case when (select top 1 utcomp.fcosttype from utcomp) ='S' then inmastx.fovhdcost else inmastx.f2ovhdcost end * fquantity) as InventoryOverheadCost
	-- somast - Sales Order Info
	,somast.fterr as TerritoryId
	,somast.fsoldby as SalesPersonId
	-- sorels - Sales Order release price and cost estimates
	,CASE when joitem.fsource ='M' then
	    -- for make items, get the price right off the associated sales order		
			CONVERT(DECIMAL(17,5), sorels.fnetprice) 		
	 ELSE
		-- non-make item get an average price based on sales order releases for this item around the job's due date		
			CONVERT(DECIMAL(17,5), dbo.MA_GetPartAverageSalesOrderReleasePrice(joitem.fpartno, joitem.fpartrev, jomast.fddue_date) * jomast.fquantity) 		
	 END as NetSales
	,sorels.forderqty as SalesOrderQuantity
	,CONVERT(DECIMAL(17,5), sorels.flabcost) as SalesOrderLaborCost
	,CONVERT(DECIMAL(17,5), sorels.fmatlcost) as SalesOrderMaterialCost
	,CONVERT(DECIMAL(17,5), sorels.fothrcost) as SalesOrderOtherCost
	,CONVERT(DECIMAL(17,5), sorels.fovhdcost) as SalesOrderOverheadCost
	,CONVERT(DECIMAL(17,5), sorels.fsetupcost) as SalesOrderSetupCost
	,CONVERT(DECIMAL(17,5), sorels.fsubcost) as SalesOrderSubcontractingCost
	,CONVERT(DECIMAL(17,5), sorels.ftoolcost) as SalesOrderToolingCost
FROM jomast
JOIN joitem ON jomast.fjobno = joitem.fjobno
JOIN jopact ON jomast.fjobno = jopact.fjobno
JOIN jopest ON jomast.fjobno = jopest.fjobno
LEFT JOIN sorels ON joitem.fsono = sorels.fsono AND joitem.finumber = sorels.finumber AND joitem.fkey = sorels.frelease
LEFT JOIN somast on sorels.fsono = somast.fsono
LEFT JOIN inmastx ON joitem.fac = inmastx.fac AND joitem.fpartno = inmastx.fpartno AND joitem.fpartrev = inmastx.frev
WHERE ftype <> 'T' -- no template jobs


GO
/****** Object:  View [dbo].[MA_Version]    Script Date: 4/24/2018 7:54:15 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
		

----------------------------------------------------------------------------------------------
-- MA_Version provides version information on the current set of Margin Analyzer SQL objects;  
-- used to determine if the SQL creation scripts needs to be run
----------------------------------------------------------------------------------------------
create view [dbo].[MA_Version] as select 1.62 as Version

GO
/****** Object:  View [dbo].[partNumberSelection]    Script Date: 4/24/2018 7:54:15 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
	CREATE VIEW [dbo].[partNumberSelection]
	AS
	SELECT * FROM dbo.inmastx where dbo.INMASTx.FNUSRCUR1 <> 0 

GO
/****** Object:  View [dbo].[partNumberSelectionOld]    Script Date: 4/24/2018 7:54:15 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
	CREATE VIEW [dbo].[partNumberSelectionOld]
	AS
	SELECT * FROM dbo.inmastx where dbo.INMASTx.FNUSRCUR1 <> 0 

GO
/****** Object:  View [dbo].[Scrap - Grouped Labor]    Script Date: 4/24/2018 7:54:15 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[Scrap - Grouped Labor]
AS
SELECT     TOP (100) PERCENT SUM(fcompqty) AS Quantity, fdate AS Date, fjobno AS JobNumber, foperno
FROM         dbo.ladetail
GROUP BY fdate, fjobno, foperno, fstatus
HAVING      (fstatus = 'P') AND (fdate > CONVERT(DATETIME, '2007-01-01 00:00:00', 102))
ORDER BY Date DESC


GO
/****** Object:  View [dbo].[Scrap - Grouped Scrap]    Script Date: 4/24/2018 7:54:15 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[Scrap - Grouped Scrap]
AS
SELECT     TOP (100) PERCENT fjobno AS [Job Number], LEFT(fcode, 1) AS [Scrap Type], finsp_dt AS [Inspection Date], SUM(fquantity) AS Quantity, foperno
FROM         dbo.qajors
GROUP BY fjobno, foperno, LEFT(fcode, 1), finsp_dt
ORDER BY [Inspection Date] DESC


GO
/****** Object:  View [dbo].[Scrap - Grouped Scrap & Labor]    Script Date: 4/24/2018 7:54:15 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[Scrap - Grouped Scrap & Labor]
AS
SELECT     [Job Number] AS JobNumber, foperno, [Inspection Date] AS Date, [Scrap Type], Quantity AS ScrapQty, 0 AS ProdQty
FROM         dbo.[Scrap - Grouped Scrap]
UNION ALL
SELECT     JobNumber, foperno, Date, 0 AS [Scrap Type], 0 AS ScrapQty, Quantity AS ProdQty
FROM         dbo.[Scrap - Grouped Labor]


GO
/****** Object:  View [dbo].[ShMInvc]    Script Date: 4/24/2018 7:54:15 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Original view definition for ShMInvc
/*
CREATE VIEW dbo.ShMInvc
AS
SELECT     dbo.shmast.fshipno, dbo.shmast.fshipdate, dbo.shmast.fcnumber, dbo.shmast.fbl_lading, dbo.shmast.ftype, dbo.shmast.fno_boxes, 
                      dbo.shmast.fshipwght, dbo.shmast.fcjobno, dbo.shmast.fcpono, dbo.shmast.fcvendno, dbo.shmast.fcsono, dbo.shmast.fcsorev, dbo.slcdpm.fcompany, 
                      dbo.slcdpm.fcontact, dbo.slcdpm.fphone, SUBSTRING(dbo.slcdpm.fmstreet,1,40) AS fstreet, dbo.slcdpm.fcity, dbo.slcdpm.fstate, dbo.slcdpm.fzip, 
                      dbo.slcdpm.fcountry, dbo.shmast.Identity_Column
FROM         dbo.shmast INNER JOIN
                      dbo.slcdpm ON dbo.shmast.fcnumber = dbo.slcdpm.fcustno
WHERE     (dbo.shmast.fconfirm = 'Y') AND (NOT (dbo.shmast.flisinv = 1)) AND (dbo.shmast.ftype <> 'VE') AND (dbo.shmast.ftype <> 'JO') AND 
                      (dbo.shmast.fcnumber <> '      ') AND (dbo.shmast.fshipno IN
                          (SELECT     shipno
                            FROM          ShNoInvc))


*/

CREATE VIEW [dbo].[ShMInvc]
AS
SELECT     a.fshipno, a.fshipdate, a.fcnumber, a.fbl_lading, a.ftype, a.fno_boxes, 
                      a.fshipwght, a.fcjobno, a.fcpono, a.fcvendno, a.fcsono, a.fcsorev, b.fcompany, 
                      b.fcontact, b.fphone, SUBSTRING(b.fmstreet,1,40) AS fstreet, b.fcity, b.fstate, b.fzip, 
                      b.fcountry, a.Identity_Column
FROM  dbo.ShNoInvc  
INNER JOIN  dbo.shmast a ON a.fshipno=dbo.ShNoInvc.ShipNo and a.fcnumber <> '' and a.fconfirm = 'Y' and a.flisinv <> 1  and a.ftype not in ('VE','JO') 
INNER JOIN dbo.slcdpmx b ON  b.fcustno=a.fcnumber
GO
/****** Object:  View [dbo].[slcdpm]    Script Date: 4/24/2018 7:54:15 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ******************************************************************************************

	-- **********************************************************************************************************************************************************
	-- Create new view and instead of triggers based on the renamed table.		
	CREATE VIEW [dbo].[slcdpm]
	AS
	SELECT     *, dbo.GetCustLastPayDate(fcustno) AS fdlpaydate, dbo.GetCustLastPayment(fcustno) AS fnpayamt, dbo.GetCustOpenOrders(fcustno) AS fcurorder, 
	                      dbo.GetCustYTDSales(fcustno, GETDATE()) AS fytdSales, dbo.GetCustMTDSales(fcustno, GETDATE()) AS fmtdSales, dbo.GetCustBalance(fcustno) 
	                      AS fbal, dbo.GetCustOpenCredits(fcustno) AS fopencr
	FROM         dbo.slcdpmx
GO
/****** Object:  View [dbo].[ToolingLog]    Script Date: 4/24/2018 7:54:15 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[ToolingLog]
AS
select CAST(JobNumber AS INT) as jn, * from toolingtranslog

GO
/****** Object:  View [dbo].[UtComp]    Script Date: 4/24/2018 7:54:15 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[UtComp] AS SELECT * FROM M2MSystem1.dbo.UtComp WHERE fRecID = '01' 

GO
/****** Object:  View [dbo].[UtCurr]    Script Date: 4/24/2018 7:54:15 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[UtCurr] AS SELECT * FROM M2MSystem1.dbo.UtCurr 

GO
/****** Object:  View [dbo].[UtFact]    Script Date: 4/24/2018 7:54:15 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[UtFact] AS SELECT * FROM M2MSystem1.dbo.UtFact 

GO
/****** Object:  View [dbo].[VToolingItems]    Script Date: 4/24/2018 7:54:15 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[VToolingItems] AS
		select itemnumber, TotTBQty,
		SUBSTRING(
			list.xmlDoc.value('.', 'varchar(max)'),
			3, 10000
		) AS PlantList

		from
		( 
			select distinct itemnumber,sum(qtycurrent) TotTBQty
			from toolinginv
			group by itemnumber
		) lv1
		cross apply(
			select ', '+ ti.Plant as ListItem
			from 
			(
				select distinct itemnumber,plant
				from toolinginv
			) ti
			where lv1.itemnumber=ti.itemnumber
			order by ti.plant
			for xml path(''), type
		) as list(xmlDoc)

GO
/****** Object:  View [dbo].[VToolItems]    Script Date: 4/24/2018 7:54:15 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[VToolItems] AS
select itemnumber, totQty,
SUBSTRING(
	plantList.xmlDoc.value('.', 'varchar(max)'),
	3, 10000
) AS PlantList,
SUBSTRING(
	binLocList.xmlDoc.value('.', 'varchar(max)'),
	5, 10000
) AS binLocList
from
( 
	select itemnumber,sum(totqty) totQty
	from 
	toolinv 
	group by itemnumber
	--6317
) lv1
cross apply(
	select ', '+ ti.Plant as ListItem
	from 
	(
		select distinct itemnumber,plant
		from toolinv
	) ti
	where lv1.itemnumber=ti.itemnumber
	order by ti.plant
	for xml path(''), type
) as plantList(xmlDoc)
cross apply(
	select '<br>'+ ti.binloclist as ListItem
	from 
	(
		select distinct itemnumber,binloclist
		from toolinv
	) ti
	where lv1.itemnumber=ti.itemnumber
	order by ti.binloclist
	for xml path(''), type
) as binLoclist(xmlDoc)

GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4[30] 2[40] 3) )"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 3
   End
   Begin DiagramPane = 
      PaneHidden = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 5
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'Combine Jobs'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'Combine Jobs'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4[30] 2[40] 3) )"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 3
   End
   Begin DiagramPane = 
      PaneHidden = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 5
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'Combine Transactions'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'Combine Transactions'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "bcraw"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 135
               Right = 230
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'Downtime Prep BCRAW'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'Downtime Prep BCRAW'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4[51] 2[19] 3) )"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 3
   End
   Begin DiagramPane = 
      PaneHidden = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 12
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 5
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'Grouped Tooling & Labor'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'Grouped Tooling & Labor'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[21] 4[27] 2[30] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "jomast"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 121
               Right = 207
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "ladetail"
            Begin Extent = 
               Top = 6
               Left = 245
               Bottom = 121
               Right = 414
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "inmast"
            Begin Extent = 
               Top = 6
               Left = 452
               Bottom = 121
               Right = 621
            End
            DisplayFlags = 280
            TopColumn = 9
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 13
         Width = 284
         Width = 1245
         Width = 1095
         Width = 930
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1260
         Width = 600
         Width = 1935
         Width = 1020
         Width = 945
         Width = 2550
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 4215
         Alias = 3570
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 3690
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'Labor - 1'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'Labor - 1'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "jomast"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 121
               Right = 207
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "ladetail"
            Begin Extent = 
               Top = 6
               Left = 245
               Bottom = 121
               Right = 414
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "inmast"
            Begin Extent = 
               Top = 126
               Left = 38
               Bottom = 241
               Right = 207
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'Labor - JT'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'Labor - JT'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "inmast"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 121
               Right = 223
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "inboms"
            Begin Extent = 
               Top = 6
               Left = 261
               Bottom = 121
               Right = 446
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'Material Cost Per Part'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'Material Cost Per Part'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "ladetail"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 121
               Right = 223
            End
            DisplayFlags = 280
            TopColumn = 19
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'Scrap - Grouped Labor'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'Scrap - Grouped Labor'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "qajors"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 320
               Right = 223
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'Scrap - Grouped Scrap'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'Scrap - Grouped Scrap'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4[30] 2[40] 3) )"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 3
   End
   Begin DiagramPane = 
      PaneHidden = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 5
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'Scrap - Grouped Scrap & Labor'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'Scrap - Grouped Scrap & Labor'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "Combine Transactions"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 121
               Right = 210
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Combine Jobs"
            Begin Extent = 
               Top = 6
               Left = 248
               Bottom = 121
               Right = 400
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'Tooling - 1'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'Tooling - 1'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[29] 4[43] 2[10] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "Combine Transactions"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 268
               Right = 322
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Combine Jobs"
            Begin Extent = 
               Top = 6
               Left = 360
               Bottom = 209
               Right = 599
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 3480
         Alias = 1950
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'Tooling - 1 Rev A'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'Tooling - 1 Rev A'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "Combine Transactions"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 114
               Right = 209
            End
            DisplayFlags = 280
            TopColumn = 5
         End
         Begin Table = "JobTranslation"
            Begin Extent = 
               Top = 6
               Left = 247
               Bottom = 114
               Right = 398
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 12
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'Tooling - 1 Rev B'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'Tooling - 1 Rev B'
GO
