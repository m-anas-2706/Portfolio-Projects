SELECT *
FROM PortfolioProject..NashvilleHousing


-- 1. Changing the SaleDate column to only include the date and get rid of the time at the end.

SELECT SaleDateConverted, CONVERT(date,SaleDate)
FROM PortfolioProject..NashvilleHousing

-- This didn't work.
UPDATE PortfolioProject.dbo.NashvilleHousing
SET SaleDate = CONVERT(date,SaleDate)

-- So, I used ALTER TABLE to add the column and then update it.
ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD SaleDateConverted date;

UPDATE PortfolioProject.dbo.NashvilleHousing
SET SaleDateConverted = CONVERT(date,SaleDate)

--------------------------------------------------------------------------------------------------

-- 2. Populating the PropertyAddress (checking for missing values)
SELECT *
FROM PortfolioProject..NashvilleHousing
WHERE PropertyAddress is null
--ORDER BY ParcelID


SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject..NashvilleHousing a
JOIN PortfolioProject..NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is null

-- While using JOINs, we cannot call a table by its name only. 
-- We have to call it by its alias, else it will throw an error.
UPDATE a
SET a.PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject..NashvilleHousing a
JOIN PortfolioProject..NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is null

--------------------------------------------------------------------------------------------------

-- 3. Breaking out Address into indiviual columns (Address, City, State)
SELECT PropertyAddress
FROM PortfolioProject..NashvilleHousing
--WHERE PropertyAddress is null
--ORDER BY ParcelID

-- CHARINDEX searches for one character expression inside a second character expression, 
-- returning the starting position of the first expression if found. 
-- CHARINDEX returns a number (the position of the the expression)
SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) AS Address_Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) AS Address_State
FROM PortfolioProject..NashvilleHousing

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD PropertySplitAddress nvarchar(255);

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD PropertySplitCity nvarchar(255);

UPDATE PortfolioProject.dbo.NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1)

UPDATE PortfolioProject.dbo.NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))


SELECT PropertyAddress, PropertySplitAddress, PropertySplitCity
FROM PortfolioProject..NashvilleHousing


-- We have done the Property Address, now we have to split the Owner's address.
-- We can do it using PARSENAME, which is simpler and less complex than SUBSTRING.

SELECT OwnerAddress
FROM PortfolioProject..NashvilleHousing

-- PARSENAME works with periods (.) and not commas (,). So we use REPLACE() to 
-- convert the commas in the OwnerAddress into periods. 
-- PARSENAME works kind of backwards. When we give it 1, it will return the state 
-- which is written at the very end of the address. 

SELECT 
PARSENAME(REPLACE(OwnerAddress,',', '.'), 3),
PARSENAME(REPLACE(OwnerAddress,',', '.'), 2),
PARSENAME(REPLACE(OwnerAddress,',', '.'), 1)
FROM PortfolioProject..NashvilleHousing


ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD OwnerSplitAddress nvarchar(255);

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD OwnerSplitCity nvarchar(255);

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD OwnerSplitState nvarchar(255);

UPDATE PortfolioProject.dbo.NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',', '.'), 3)

UPDATE PortfolioProject.dbo.NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',', '.'), 2)

UPDATE PortfolioProject.dbo.NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',', '.'), 1)


SELECT OwnerAddress, OwnerSplitAddress, OwnerSplitCity, OwnerSplitState
FROM PortfolioProject..NashvilleHousing


--------------------------------------------------------------------------------------------------

-- 4. Replacing 'Y' and 'N' in SoldAsVacant to 'Yes' and 'No'.

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM PortfolioProject..NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2

-- Using a CASE statement to change Y and N to Yes and No.

SELECT SoldAsVacant, 
CASE WHEN SoldAsVacant = 'N' THEN 'No'
	 WHEN SoldAsVacant = 'Y' THEN 'Yes'
	 ELSE SoldAsVacant
	 END
FROM PortfolioProject..NashvilleHousing
WHERE SoldAsVacant = 'N' 
  OR  SoldAsVacant = 'Y'

UPDATE PortfolioProject..NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'N' THEN 'No'
						WHEN SoldAsVacant = 'Y' THEN 'Yes'
						ELSE SoldAsVacant
						END

--------------------------------------------------------------------------------------------------

-- 5. Remove Duplicates.
-- In practice, don't delete the raw data from your table.

-- Using ROW_NUMBER() to check for duplicates.
-- ROW_NUMBER: Numbers the output of a result set. More specifically, 
-- returns the sequential number of a row within a partition of a result set, 
-- starting at 1 for the first row in each partition. ROW_NUMBER and RANK are similar. 
-- ROW_NUMBER numbers all rows sequentially (for example 1, 2, 3, 4, 5). RANK provides 
-- the same numeric value for ties (for example 1, 2, 2, 4, 5).

WITH RowNumCTE AS (
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
				) row_num

FROM PortfolioProject..NashvilleHousing
-- order by ParcelID
)
SELECT *
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress

-- DELETING the duplicates now.

WITH RowNumCTE AS (
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
				) row_num

FROM PortfolioProject..NashvilleHousing
-- order by ParcelID
)
DELETE
FROM RowNumCTE
WHERE row_num > 1
--ORDER BY PropertyAddress


-- Now, to check if there are any duplicates, we can run the CTE again 
-- with the select statement above.



--------------------------------------------------------------------------------------------------

-- 6. Deleting unused columns.
-- Again, don't delete your raw data without asking first.


SELECT *
FROM PortfolioProject..NashvilleHousing


ALTER TABLE PortfolioProject..NashvilleHousing
DROP COLUMN PropertyAddress, SaleDate, OwnerAddress, TaxDistrict







