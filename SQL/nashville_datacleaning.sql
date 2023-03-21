-- SQlite --

SELECT
	*
FROM
	Nashville_Housing;


-- Updating where PropertyAddress is null --


-- Shows where PropertyAddress is null
SELECT
	nh.ParcelID
	, nh.PropertyAddress
	, nh2.ParcelID
	, nh2.PropertyAddress
FROM
	Nashville_Housing nh
JOIN Nashville_Housing nh2
	on
	nh.ParcelID = nh2.ParcelID
	AND nh."UniqueID " <> nh2."UniqueID "
WHERE
	nh.PropertyAddress is NULL;

-- Updates PropertyAddress by filling in null with matching values 
UPDATE
	Nashville_Housing
SET
	PropertyAddress = (
		SELECT
			nh.PropertyAddress
		FROM
			Nashville_Housing nh
		WHERE
			Nashville_Housing .ParcelID = nh.ParcelID
			AND Nashville_Housing ."UniqueID " <> nh."UniqueID "
			AND nh.PropertyAddress IS NOT NULL
	)
WHERE
	PropertyAddress IS NULL;


-- Splitting PropertyAddress into Address and City --;


-- Shows what split values will look like
SELECT
	SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) AS Address
    , SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LENGTH(PropertyAddress)) AS City
FROM
	Nashville_Housing;

-- Adds SplitAddress column and fills it with address
ALTER TABLE Nashville_Housing 
ADD SplitAddress Nvarchar(255);

UPDATE
	Nashville_Housing
SET
	SplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1);

-- Adds SplitCity column and fills it with city 
ALTER TABLE Nashville_Housing 
ADD SplitCity Nvarchar(255);

UPDATE
	Nashville_Housing
SET
	SplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LENGTH(PropertyAddress));


-- Splitting OwnerAddress into Address, City, and State --


-- Shows what split values will look like
SELECT
	SUBSTRING(OwnerAddress, 1, INSTR(OwnerAddress, ',') - 1) AS SplitOwnerAddress
	, SUBSTRING(OwnerAddress, INSTR(OwnerAddress, ',') + 1, LENGTH(OwnerAddress) - INSTR(OwnerAddress, ',') - INSTR(REVERSE(OwnerAddress), ',')) AS SplitOwnerCity
	, REVERSE(
		SUBSTR(
			REVERSE(OwnerAddress), 1
			, INSTR(REVERSE(OwnerAddress), ',') - 1
		)
	) AS SplitOwnerState
FROM
	Nashville_Housing;

-- Adds SplitOwnerAddress column and fills it with owner address
ALTER TABLE Nashville_Housing 
ADD SplitOwnerAddress Nvarchar(255);

UPDATE
	Nashville_Housing
SET
	SplitOwnerAddress = SUBSTRING(OwnerAddress, 1, INSTR(OwnerAddress, ',') - 1);

-- Adds SplitOwnerCity column and fills it with owner city
ALTER TABLE Nashville_Housing 
ADD SplitOwnerCity Nvarchar(255);

UPDATE
	Nashville_Housing
SET
	SplitOwnerCity = SUBSTRING(OwnerAddress, INSTR(OwnerAddress, ',') + 1, LENGTH(OwnerAddress) - INSTR(OwnerAddress, ',') - INSTR(REVERSE(OwnerAddress), ','));

-- Adds SplitOwnerState column and fills it with owner state
ALTER TABLE Nashville_Housing 
ADD SplitOwnerState Nvarchar(255);

UPDATE
	Nashville_Housing
SET
	SplitOwnerState = 	
	SUBSTRING(OwnerAddress, 1, INSTR(OwnerAddress, ',') - 1) AS SplitOwnerAddress
	, SUBSTRING(OwnerAddress, INSTR(OwnerAddress, ',') + 1, LENGTH(OwnerAddress) - INSTR(OwnerAddress, ',') - INSTR(REVERSE(OwnerAddress), ',')) AS SplitOwnerCity
	, REVERSE(
		SUBSTR(
			REVERSE(OwnerAddress), 1
			, INSTR(REVERSE(OwnerAddress), ',') - 1
		)
	);


-- Change Y,N to Yes,No in SoldAsVacant column--


-- Test query to change Y,N to Yes,No
SELECT
	SoldAsVacant
	, 
CASE
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
	END
FROM
	Nashville_Housing;

-- Updating SoldAsVacant column with query
UPDATE
	Nashville_Housing
SET
	SoldAsVacant =
CASE
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
	END;


-- Removing Duplicates --

-- Using CTE to see how many duplicates the table has
WITH RowNumCTE AS(
	SELECT *
	, ROW_NUMBER() OVER(
			PARTITION BY 
			  ParcelID
			, PropertyAddress
			, SalePrice
			, SaleDate
			, LegalReference
		ORDER BY
			"UniqueID"
		) row_num
	FROM
		Nashville_Housing
)
SELECT
	*
FROM
	RowNumCTE
WHERE
	row_num > 1

-- Deleting duplicates from table using rowid	
DELETE
FROM
	Nashville_Housing
WHERE
	rowid NOT IN (
		SELECT
			MIN(rowid)
		FROM
			Nashville_Housing
		GROUP BY
			ParcelID
			, PropertyAddress
			, SalePrice
			, SaleDate
			, LegalReference
	)
	

-- Removing unused columns --
	
ALTER TABLE Nashville_Housing 
DROP COLUMN PropertyAddress;

ALTER TABLE Nashville_Housing 
DROP COLUMN OwnerAddress;



