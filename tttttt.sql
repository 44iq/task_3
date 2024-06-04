CREATE TABLE dbo.SKU (
ID_identity INT IDENTITY(1,1) PRIMARY KEY,
Code Varchar (100) UNIQUE,
[Name] Varchar(100)
);

CREATE TABLE dbo.Family (
ID_identity INT IDENTITY(1,1) PRIMARY KEY,
SurName Varchar (100) UNIQUE,
BudgetValue Varchar(100)
);

CREATE TABLE dbo.Basket (
ID_identity INT IDENTITY(1,1) PRIMARY KEY,
CONSTRAINT ID_SKU FOREIGN KEY (ID_identity) REFERENCES dbo.SKU (ID_identity),
CONSTRAINT ID_Family FOREIGN KEY (ID_identity) REFERENCES dbo.Family (ID_identity),
Quantity INT CHECK (Quantity >= 0), 
[Value] INT CHECK ([Value] >= 0), 
PurchaseDate DATE DEFAULT GETDATE(), 
DiscountValue INT 
);

GO
CREATE FUNCTION dbo.udf_GetSKUPrice (
    @ID_SKU INT
)
RETURNS DECIMAL(18, 2)
AS
BEGIN
    DECLARE @Price DECIMAL(18, 2)
SELECT @Price = SUM(Value) / SUM(Quantity)
    FROM dbo.Basket
    WHERE ID_identity = @ID_SKU

    RETURN @Price
END
GO

CREATE VIEW dbo.vw_SKUPrice
AS
SELECT 
    SKU.*,
    dbo.udf_GetSKUPrice(ID_identity) AS PricePerOne
FROM dbo.SKU;

GO

CREATE PROCEDURE UpdateFamilyBudget
(
    @FamilySurName varchar(255)
)
AS
BEGIN
    DECLARE @TotalCost decimal(18, 2)

    SELECT @TotalCost = SUM(Value)
    FROM dbo.Basket JOIN dbo.Family ON (Basket.ID_identity = Family.ID_identity)
    WHERE SurName = @FamilySurName

    UPDATE dbo.Family
    SET BudgetValue = BudgetValue - @TotalCost
    WHERE SurName = @FamilySurName
END
GO

CREATE TRIGGER TR_Basket_insert_update
ON dbo.Basket
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @ID_SKU INT;
    SELECT @ID_SKU = ID_identity FROM inserted;
    
    DECLARE @Count INT;
    SELECT @Count = COUNT(*) FROM dbo.Basket WHERE ID_identity = @ID_SKU;
    
    IF @Count >= 2
    BEGIN
        UPDATE dbo.Basket
        SET DiscountValue = Value * 0.05
        WHERE ID_identity = @ID_SKU;
    END
    ELSE
    BEGIN
        UPDATE dbo.Basket
        SET DiscountValue = 0
        WHERE ID_identity = @ID_SKU;
    END
END

GO
