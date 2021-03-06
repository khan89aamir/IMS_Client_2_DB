﻿CREATE TABLE [dbo].[tblCashClosing](
	[CashClosingID] [int] IDENTITY(1,1) NOT NULL,
	[MasterCashClosingID] [int] NOT NULL,
	[CashBandID] [int]  NOT NULL,
	[Count] [int] NOT NULL,
	[Value] [decimal](18, 3) NOT NULL,
	[CreatedBy] [int] NOT NULL CONSTRAINT [DF_tblCashClosing_CreatedBy]  DEFAULT ((0)),
	[CreatedOn] [datetime] NOT NULL CONSTRAINT [DF_tblCashClosing_CreatedOn]  DEFAULT (getdate()),
	[UpdatedBy] [int] NULL,
	[UpdatedOn] [datetime] NULL
PRIMARY KEY CLUSTERED 
(
	[CashClosingID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO