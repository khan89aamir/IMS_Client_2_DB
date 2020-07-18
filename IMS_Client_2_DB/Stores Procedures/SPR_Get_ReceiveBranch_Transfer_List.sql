﻿-- =============================================
-- Author:		<AAMIR KHAN>
-- Create date: <16th JULY 2020>
-- Update date: <18th JULY 2020>
-- Description:	<>
-- =============================================
--EXEC SPR_Get_ReceiveBranch_Transfer_List
CREATE PROCEDURE SPR_Get_ReceiveBranch_Transfer_List
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @PARAMERES VARCHAR(MAX)=''
	DECLARE @StoreID AS INT=0

	BEGIN TRY
	
	SELECT @StoreID=StoreID FROM DefaultStoreSetting WITH(NOLOCK) WHERE MachineName=HOST_NAME()

	SELECT stb.StoreTransferID,sm.StoreName [Branch],stb.BillNo,stb.BillDate,stb.TotalQTY
	,usr.UserName [Sender], ' ' as Post,'Identical' as Identical
	FROM tblStoreTransferBillDetails stb
	INNER JOIN StoreMaster sm ON stb.ToStore=sm.StoreID
	INNER JOIN UserManagement usr ON stb.CreatedBy=usr.UserID
	WHERE sm.StoreID = @StoreID
	AND stb.BillStatus ='Not Posted'

	END TRY

	BEGIN CATCH

		INSERT [dbo].[ERROR_Log]
		(
		ERR_NUMBER
		, ERR_SEVERITY
		, ERR_STATE
		, ERR_LINE
		, ERR_MESSAGE
		, ERR_PROCEDURE
		, PARAMERES
		)
		SELECT  
		ERROR_NUMBER() 
		,ERROR_SEVERITY() 
		,ERROR_STATE() 
		,ERROR_LINE()
		,ERROR_MESSAGE()
		,ERROR_PROCEDURE()
		,@PARAMERES

	END CATCH
END