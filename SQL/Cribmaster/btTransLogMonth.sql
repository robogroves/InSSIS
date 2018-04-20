btTransLogMonth.sql
USE [m2mdata01]
GO

/****** Object:  Table [dbo].[btTransLogMonth]    Script Date: 4/19/2018 2:23:56 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[btTransLogMonth](
	[JobNumber] [nvarchar](32) NULL,
	[PartNumber] [nvarchar](25) NULL,
	[Rev] [nvarchar](3) NULL,
	[ItemNumber] [nvarchar](32) NULL,
	[Qty] [int] NULL,
	[UNITCOST] [money] NULL,
	[TranStartDateTime] [smalldatetime] NOT NULL,
	[UserNumber] [nvarchar](32) NULL,
	[UserName] [nvarchar](50) NULL,
	[Plant] [nvarchar](3) NULL
) ON [PRIMARY]

GO