/* Project - Cleaning Data in SQL */

SELECT *
FROM NashvilleHousing.dbo.Nashville

-- Standarizing SaleDate column into Date format

ALTER TABLE Nashville
Add SaleDateConverted Date

UPDATE Nashville
SET SaleDateConverted = CONVERT(Date, SaleDate)

-- Populating PropertyAdress data
-- Since ParcelID is tied to PropertyAddress, we will do a self join to replace NULL PropertyAddressess

SELECT *
FROM NashvilleHousing.dbo.Nashville
WHERE PropertyAddress IS NULL
ORDER BY ParcelID

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM NashvilleHousing.dbo.Nashville a
	JOIN NashvilleHousing.dbo.Nashville b
		on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
	FROM NashvilleHousing.dbo.Nashville a
		JOIN NashvilleHousing.dbo.Nashville b
			on a.ParcelID = b.ParcelID
		AND a.[UniqueID ] <> b.[UniqueID ]
	WHERE a.PropertyAddress IS NULL

-- Separating PropertyAddress into individual columns (Address, City) using SUBSTRING

SELECT PropertyAddress
FROM NashvilleHousing.dbo.Nashville

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) as Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) as City
FROM NashvilleHousing.dbo.Nashville

-- Adding columns

ALTER TABLE Nashville
Add PropertySplitAddress NVARCHAR(255),
	PropertySplitCity NVARCHAR(255)

-- Updating columns

UPDATE Nashville
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1),
	PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))

-- Separating PropertyAddress into individual columns (Address, City, State) using PARSENAME

SELECT OwnerAddress
FROM NashvilleHousing.dbo.Nashville

SELECT OwnerAddress,
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM NashvilleHousing.dbo.Nashville

-- Adding columns

ALTER TABLE Nashville
Add OwnerSplitAddress NVARCHAR(255),
	OwnerSplitCity NVARCHAR(255),
	OwnerSplitState NVARCHAR(255)

-- Updating columns

UPDATE Nashville
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
	OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
	OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

-- Cleaning SoldAsVacant (converting Y and N to Yes and No)

SELECT DISTINCT SoldAsVacant, COUNT(SoldAsVacant)
FROM NashvilleHousing.dbo.Nashville
GROUP BY SoldAsVacant
ORDER BY 2

UPDATE Nashville
SET SoldAsVacant = 	
		CASE 
			WHEN SoldAsVacant = 'Y' THEN 'Yes'
			WHEN SoldAsVacant = 'N' THEN 'No'
			ELSE SoldAsVacant
		END

SELECT DISTINCT SoldAsVacant
FROM NashvilleHousing.dbo.Nashville

-- Removing Duplicates

WITH RowNUMCTE AS(
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY 
		ParcelID, 
		PropertyAddress,
		SalePrice,
		SaleDate,
		LegalReference
		ORDER BY UniqueID
		) ROW_NUM
FROM NashvilleHousing.dbo.Nashville
)
DELETE
FROM RowNUMCTE
WHERE ROW_NUM > 1

-- Deleting unused columns

ALTER TABLE NashvilleHousing.dbo.Nashville
DROP COLUMN
	SaleDate,
	SaleDateConverted,
	PropertyAddress,
	OwnerAddress,
	TaxDistrict

-- Final check

SELECT *
FROM NashvilleHousing.dbo.Nashville