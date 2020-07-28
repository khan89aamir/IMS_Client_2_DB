﻿CREATE TABLE [dbo].[tblProductWiseModelNo](
	[SubProductID] [int] IDENTITY(1,1) NOT NULL,
	[ProductID] [int] NOT NULL,
	[ModelNo] [nvarchar](50) NOT NULL,
	[BrandID] [int] NOT NULL,
	[StoreID] [int] NOT NULL,
	[EndUser] [decimal](18, 3) NOT NULL,
	[Photo] [nvarchar](50) NULL,
	[CreatedBy] [int] NOT NULL CONSTRAINT [DF_tblProductWiseModelNo_CreatedBy]  DEFAULT ((0)),
	[CreatedOn] [datetime] NOT NULL CONSTRAINT [DF_tblProductWiseModelNo_CreatedOn]  DEFAULT (getdate()),
	[UpdatedBy] [int] NULL,
	[UpdatedOn] [datetime] NULL
) ON [PRIMARY]

GO