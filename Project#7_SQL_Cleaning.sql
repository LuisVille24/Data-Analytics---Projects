-- Importing CSV file with appropriate CASTING
CREATE TABLE Housing_Data(
	UniqueID INT,
	ParcelID VARCHAR(50),
	LandUse VARCHAR (50),
	Property_Address VARCHAR(50),
	SaleDate DATE, 
	SalePrice INT,
	LegalReference VARCHAR(50),
	Sold_Vacant VARCHAR(10),
	Owner_Name VARCHAR(50),
	Owner_Address VARCHAR(50),
	Acreage FLOAT,
	Tax_District VARCHAR(50),
	LandValue INT, 
	BuildingValue INT, 
	TotalValue INT, 
	YearBuilt INT, 
	Bedrooms INT, 
	FullBath INT, 
	HalfBath INT
)


--- Data Cleaning 

SELECT DISTINCT(sold_vacant)

FROM housing_data_new

-- Answers: Yes, Y, N, No.
-- Change Y to Yes and N to No.

SELECT 
	CASE 
		WHEN sold_vacant = 'Y' THEN 'Yes'
		WHEN sold_vacant = 'N' THEN 'No'
		ELSE sold_vacant
		END
		
FROM housing_data_new
		
UPDATE housing_data_new
SET sold_vacant = 	
	CASE 
		WHEN sold_vacant = 'Y' THEN 'Yes'
		WHEN sold_vacant = 'N' THEN 'No'
		ELSE sold_vacant
		END

SELECT DISTINCT(sold_vacant)

FROM housing_data_new

-- ACTION COMPLETE

SELECT uniqueID, sold_vacant

FROM housing_data_new
WHERE sold_vacant = 'No'
ORDER BY uniqueid


--------------------------------------
-- Breaking out property_address into Individual Columns (Address, City, State)

SELECT
	property_address,
	TRIM(SUBSTRING(property_address, 1, POSITION(',' IN property_address)-1)) AS ADDRESS_NUMBER,
	TRIM(SUBSTRING(property_address, POSITION(',' IN property_address) + 1, LENGTH(property_address))) AS City
	
FROM housing_data_new

ALTER TABLE housing_data_new
ADD Address VARCHAR(100), 
ADD City VARCHAR(50)

UPDATE housing_data_new
SET Address = TRIM(SUBSTRING(property_address, 1, POSITION(',' IN property_address)-1))

UPDATE housing_data_new
SET City = TRIM(SUBSTRING(property_address, POSITION(',' IN property_address) + 1, LENGTH(property_address)))


-- DROP Property_Address & Owner_Address & tax_district

ALTER TABLE housing_data_new
DROP COLUMN property_address

ALTER TABLE housing_data_new
DROP COLUMN owner_address

ALTER TABLE housing_data_new
DROP COLUMN tax_district

--------- REMOVE DUPLICATES
WITH RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY parcelid,landuse, saleprice,saledate, legalreference, 
				owner_name, acreage, landvalue, buildingvalue
				 ORDER BY
					uniqueid
					) row_num
FROM housing_data_new)

SELECT uniqueid
INTO temp
FROM RowNumCTE
WHERE row_num > 1

DELETE FROM housing_data_new USING temp
WHERE housing_data_new.uniqueid = temp.uniqueid

--- GENERIC QUERY
SELECT *

FROM housing_data_new


				