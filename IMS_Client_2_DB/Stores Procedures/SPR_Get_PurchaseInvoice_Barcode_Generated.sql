﻿-- =============================================
-- Author:		<AAMIR KHAN>
-- Create date: <09th AUGUST 2020>
-- Update date: <21th NOV 2020>
-- Description:	<Saved PIVOT delivery purchase bill details via ModelNo and Barcode is generated>
-- =============================================
-- EXEC [dbo].[SPR_Get_PurchaseInvoice_Barcode_Generated] 2048,1,'00173',2
CREATE PROCEDURE [dbo].[SPR_Get_PurchaseInvoice_Barcode_Generated]
@PurchaseInvoiceID INT=0
,@StoreID INT=0
,@SupplierBillNo VARCHAR(MAX)
--,@DeliveryPurchaseID3 INT=0
,@CreatedBy INT=0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	SET NOCOUNT ON;

	IF EXISTS(SELECT 1 FROM DeliveryPurchaseBill1 WITH(NOLOCK) WHERE PurchaseInvoiceID=@PurchaseInvoiceID)
	BEGIN

		BEGIN TRY
		DECLARE @PARAMERES VARCHAR(MAX)=''

		BEGIN TRANSACTION

		DECLARE @SizeType_ID AS INT=0
		DECLARE @SizeValue AS VARCHAR(MAX)
		DECLARE @i AS INT=1
		DECLARE @DeliveryPurchaseID AS INT=0
		DECLARE @query1  AS VARCHAR(MAX)=''
		DECLARE @query2  AS VARCHAR(MAX)
		DECLARE @query3  AS NVARCHAR(MAX)
		DECLARE @queryunpivot  AS VARCHAR(MAX)=''
		DECLARE @ModelNo NVARCHAR(50) =''
	
		DECLARE @ProductID	  INT =0
		DECLARE @SubProductID INT =0
		DECLARE @ColorID	  INT =0
		DECLARE @QTY		  INT =0
		DECLARE @SizeID		  INT =0
		DECLARE @BarcodeNo	  BIGINT =0

		SET @PARAMERES=CONCAT(@PurchaseInvoiceID,',',@StoreID,',',@SupplierBillNo,',',@CreatedBy)
		--SET @PARAMERES=CONCAT(@PurchaseInvoiceID,',',@StoreID,',',@SupplierBillNo,',',@DeliveryPurchaseID3,',',@CreatedBy)
		
		DECLARE ColorSize_CURSOR CURSOR 
		FOR
		
		SELECT ProductID,SubProductID, StoreID, ColorID, SizeID , QTY
		FROM dbo.ProductStockMaster WITH(NOLOCK)
		WHERE PurchaseInvoiceID=@PurchaseInvoiceID 
		AND QTY > 0
		--AND BarcodeNo IS NULL

		DECLARE OUTER_CURSOR CURSOR 
		FOR
		SELECT SizeTypeID,DeliveryPurchaseID1,ModelNo,SubProductID,ProductID
		FROM DeliveryPurchaseBill1 WITH(NOLOCK)
		WHERE PurchaseInvoiceID=@PurchaseInvoiceID
		
		OPEN OUTER_CURSOR 
		
		FETCH NEXT FROM OUTER_CURSOR INTO @SizeType_ID,  @DeliveryPurchaseID, @ModelNo,@SubProductID,@ProductID
		
		WHILE @@FETCH_STATUS <> -1
		BEGIN

			SET @i = 1
			SET @query1=''
			SET @queryunpivot=''

			DECLARE cursor_Size CURSOR
			FOR
			--SELECT Size FROM SizeMaster WITH(NOLOCK) WHERE SizeTypeID=@SizeType_ID;-- for Size value
			SELECT SizeID FROM SizeMaster WITH(NOLOCK) WHERE SizeTypeID=@SizeType_ID;-- for SizeID
	
			OPEN cursor_Size;
	
			FETCH NEXT FROM cursor_Size INTO @SizeValue

			WHILE @@FETCH_STATUS <> -1
				BEGIN

				SET @query1 += 'MAX(CASE pd2.Col'+CAST(@i AS VARCHAR)+' WHEN pd2.Col'+cast(@i AS VARCHAR)+
				' THEN pd3.Col'+CAST(@i as VARCHAR)+' END) '+QUOTENAME(@SizeValue)+',';

				SET @queryunpivot += QUOTENAME(@SizeValue);

				SET @i+=1;
				FETCH NEXT FROM cursor_Size INTO @SizeValue;

				 IF @@FETCH_STATUS = 0 
					SET @queryunpivot +=',';

				END;

			CLOSE cursor_Size;
			DEALLOCATE cursor_Size;

	SET @query2='
	SELECT PurchaseInvoiceID,ColorID,ProductID,SubProductID,QTY,Size,ModelNo,Rate,StoreID FROM
	(SELECT pd1.PurchaseInvoiceID,
	clr.ColorID,pd1.ProductID,pd1.SubProductID,pwm.ModelNo,pwm.EndUser [Rate],pd1.StoreID,'+@query1+'pd3.Total
	,FROM DeliveryPurchaseBill1 pd1
	INNER JOIN DeliveryPurchaseBill2 pd2 ON pd1.DeliveryPurchaseID1=pd2.DeliveryPurchaseID1
	INNER JOIN DeliveryPurchaseBill3 pd3 ON pd2.DeliveryPurchaseID2=pd3.DeliveryPurchaseID2 
	--AND pd3.DeliveryPurchaseID3=+CAST(@DeliveryPurchaseID3 AS VARCHAR)+
	INNER JOIN ColorMaster clr ON pd3.ColorID=clr.ColorID
	INNER JOIN ProductMaster pm on pd1.ProductID = pm.ProductID
	INNER JOIN tblProductWiseModelNo pwm ON pd1.ProductID=pwm.ProductID AND pd1.SubProductID=pwm.SubProductID
	--AND pwm.StoreID='+CAST(@StoreID AS VARCHAR)+'
	LEFT OUTER JOIN ProductStockMaster psm ON pwm.ProductID=psm.ProductID AND pwm.SubProductID=psm.SubProductID
	WHERE pd1.StoreID='+CAST(@StoreID AS VARCHAR)+' AND ISNULL(psm.PurchaseInvoiceID,0)!='+CAST(@PurchaseInvoiceID AS VARCHAR)+'
	AND pd1.PurchaseInvoiceID='+CAST(@PurchaseInvoiceID AS VARCHAR)+' AND pd2.DeliveryPurchaseID1='+CAST(@DeliveryPurchaseID as VARCHAR)+' GROUP BY pd1.PurchaseInvoiceID,pd1.ProductID,pd1.SubProductID,clr.ColorID,pwm.ModelNo,pwm.EndUser,pd1.StoreID,pd3.Total

)a 
	UNPIVOT
	(
	QTY
	FOR SIZE IN ('+@queryunpivot+')
	) unpvt
	WHERE QTY>0'
	
	SET @query2=REPLACE(@query2,',FROM',' FROM');

	--PRINT @query1
	--PRINT @queryunpivot;
	--PRINT @query2
	--SELECT @PurchaseInvoiceID [PurchaseInvoiceID],@StoreID [StoreID],@SubProductID [SubProductID],@ProductID [ProductID]
	IF NOT EXISTS(SELECT 1 FROM dbo.ProductStockMaster WITH(NOLOCK) WHERE 
	PurchaseInvoiceID=@PurchaseInvoiceID AND StoreID=@StoreID AND SubProductID=@SubProductID AND ProductID=@ProductID)
	BEGIN

		INSERT INTO dbo.ProductStockMaster
		(PurchaseInvoiceID
		,ColorID 	
		,ProductID
		,SubProductID
		,QTY
		,SizeID 
		,ModelNo
		,Rate
		,StoreID)
		EXEC (@query2);
	END

	FETCH NEXT FROM OUTER_CURSOR INTO @SizeType_ID,  @DeliveryPurchaseID, @ModelNo,@SubProductID,@ProductID
	END
	CLOSE OUTER_CURSOR
	DEALLOCATE OUTER_CURSOR

	--PRINT 'Data saved in ProductStockMaster'

	OPEN ColorSize_CURSOR

	FETCH NEXT FROM ColorSize_CURSOR INTO @ProductID, @SubProductID, @StoreID, @ColorID, @SizeID , @QTY
	WHILE @@FETCH_STATUS <> -1
	BEGIN

	--SELECT CONCAT(@PurchaseInvoiceID,',',@ProductID,',',@SubProductID,',', @StoreID,',', @ColorID,',', @SizeID,',' , @QTY)

	--IF EXISTS(SELECT 1 FROM ProductStockMaster WITH(NOLOCK) WHERE ProductID=@ProductID AND SubProductID=@SubProductID AND ColorID=@ColorID AND StoreID=@StoreID AND SizeID=@SizeID)
	--BEGIN
		
		SET @BarcodeNo=0

		SELECT TOP 1 @BarcodeNo=BarcodeNo FROM ProductStockMaster WITH(NOLOCK)
		WHERE ProductID=@ProductID 
		AND SubProductID=@SubProductID 
		AND ColorID=@ColorID 
		--AND StoreID=@StoreID 
		AND SizeID=@SizeID-- AND BarcodeNo IS NOT NULL
		ORDER BY CreatedOn
		--SELECT @BarcodeNo [BarcodeNo],@ProductID [ProductID],@SubProductID [SubProductID]
		--,@ColorID [ColorID],@SizeID [SizeID],@StoreID [StoreID]

		IF ISNULL(@BarcodeNo,0)=0
		BEGIN
			-- Getting BarocdeNo
			SELECT @BarcodeNo=NEXT VALUE FOR Barcode_Sequance
			--PRINT @BarcodeNo
		END

		UPDATE ProductStockMaster
		SET BarcodeNo=@BarcodeNo
		,UpdatedBy = @CreatedBy
		,UpdatedOn = GETDATE()
		WHERE 
		SubProductID=@SubProductID
		AND ProductID=@ProductID 
		AND ColorID=@ColorID 
		AND StoreID=@StoreID
		AND SizeID=@SizeID
		AND ISNULL(BarcodeNo,0)=0

		UPDATE ProductMaster
		SET Photo=@BarcodeNo
		WHERE Photo IS NULL
		AND ProductID=@ProductID

		UPDATE tblProductWiseModelNo
		SET Photo=@BarcodeNo
		WHERE Photo IS NULL
		AND SubProductID=@SubProductID
		AND ProductID=@ProductID 

	--END

	SET @i+=1;
	    FETCH NEXT FROM ColorSize_CURSOR INTO @ProductID, @SubProductID, @StoreID, @ColorID, @SizeID , @QTY

	    END

	CLOSE ColorSize_CURSOR;
	DEALLOCATE ColorSize_CURSOR;

	COMMIT

	SELECT 1 AS Flag,CONCAT('BarCode is Generated for SupplierBillNo. ',@SupplierBillNo) as Msg

	END TRY
	
	BEGIN CATCH

		ROLLBACK
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
		,ISNULL(ERROR_PROCEDURE(),'SPR_Get_PurchaseInvoice_Barcode_Generated')
		,@PARAMERES

		SELECT -1 AS Flag,ERROR_MESSAGE() as Msg -- Exception occured

	END CATCH
	
	END

	ELSE
	BEGIN
	
	SELECT 0 AS Flag,'Purchase invoice details is not found.' as Msg	-- Means Purchase invoice details is not found
	
	END
END