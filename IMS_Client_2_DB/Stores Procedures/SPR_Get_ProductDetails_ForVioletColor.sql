﻿-- =============================================
-- Author:		<AAMIR KHAN>
-- Create date: <18th JULY 2020>
-- Update date: <29th AUGUST 2020>
-- Description:	<>
-- =============================================
--EXEC SPR_Get_ProductDetails_ForVioletColor 'TRANS-60015',1002
CREATE PROCEDURE [dbo].[SPR_Get_ProductDetails_ForVioletColor]
@BillNo AS NVARCHAR(MAX)='0'
,@BarCode AS BIGINT=0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	BEGIN TRY
	DECLARE @PARAMERES VARCHAR(MAX)=''
	DECLARE @StoreTransferID INT=0
	DECLARE @StoreID INT=0
	SET @PARAMERES=CONCAT(@BillNo,',',@BarCode)

	SELECT @StoreID=FromStore,@StoreTransferID=StoreTransferID 
	FROM tblStoreTransferBillDetails WITH(NOLOCK) WHERE BillNo=@BillNo

	SELECT 0 [TransferItemID],@StoreTransferID [StoreBillDetailsID],p2.BarcodeNo [Barcode]
	--,'' BillQTY,1 [EnterQTY],'' [State]
	,'Violet' [CellColor],pwm.ModelNo [StyleNo]
	, p1.ProductID,p2.SubProductID, p1.ProductName [Item],c1.ColorName [Color]
    ,s1.Size,0 [Total]
	,p2.ColorID,p2.SizeID
	--,'' BillDate,'' BillNo,'' TotalQTY
	FROM dbo.ProductMaster p1
    --INNER JOIN ProductStockMaster p2 ON p1.ProductID=p2.ProductID AND p2.StoreID = @StoreID AND p2.BarcodeNo IS NOT NULL
	INNER JOIN ProductStockColorSizeMaster p2 ON p1.ProductID=p2.ProductID AND p2.StoreID = @StoreID AND p2.BarcodeNo IS NOT NULL
	INNER JOIN ColorMaster c1 ON p2.ColorID=c1.ColorID 
    INNER JOIN SizeMaster s1 ON p2.SizeID=s1.SizeID
	INNER JOIN tblProductWiseModelNo pwm ON p2.ProductID=pwm.ProductID AND p2.SubProductID=pwm.SubProductID--AND pwm.StoreID=@StoreID
    WHERE p2.StoreID = @StoreID 
	AND p2.BarcodeNo =@BarCode

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