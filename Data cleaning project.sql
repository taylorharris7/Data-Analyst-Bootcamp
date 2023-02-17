select *
from PortfolioProject..NashvilleHousing

-- standardize date format
select SaleDate, convert(date, SaleDate) as want
from PortfolioProject..NashvilleHousing

-- not working, add new column
update NashvilleHousing
set SaleDate = convert(date, SaleDate)

-- adding new column
alter table NashvilleHousing
add SaleDateConverted Date;

update NashvilleHousing
set SaleDateConverted = convert(date, SaleDate)

select SaleDate, SaleDateConverted
from NashvilleHousing



-- populate property address data
-- Parcel Ids are duplicated, some have address and some don't
select *
from PortfolioProject..NashvilleHousing
order by ParcelID

-- self join to see if parcel ids are the same and if they both have an address
-- checking uniqueIds makes sure they are not the same row
-- ISNULL(expression, value) if the expression is null, then returns the value
select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, isnull(a.propertyaddress, b.PropertyAddress)
from PortfolioProject..NashvilleHousing a
join PortfolioProject..NashvilleHousing b
	on a.ParcelID = b.ParcelID
	and a.[UniqueID ] <> b.[UniqueID ]

update a
set PropertyAddress = isnull(a.propertyaddress, b.PropertyAddress)
from PortfolioProject..NashvilleHousing a
join PortfolioProject..NashvilleHousing b
	on a.ParcelID = b.ParcelID
	and a.[UniqueID ] <> b.[UniqueID ]



-- break out address into individual columns (addressw, city, state)
-- , is delimiter
-- SUBSTRING(string, start, length)
-- CHARINDEX(substring, string, start)
select PropertyAddress
from PortfolioProject..NashvilleHousing

select 
-- gives position of the , so -1 to remove it
substring(propertyaddress, 1, CHARINDEX(',', propertyaddress) - 1) as address,
substring(propertyaddress, CHARINDEX(',', propertyaddress) + 1, len(propertyaddress)) as city
from PortfolioProject..NashvilleHousing

-- address column
alter table NashvilleHousing
add PropertySplitAddress nvarchar(255);

update NashvilleHousing
set PropertySplitAddress = substring(propertyaddress, 1, CHARINDEX(',', propertyaddress) - 1)

-- city column
alter table NashvilleHousing
add PropertySplitCity nvarchar(255);

update NashvilleHousing
set PropertySplitCity = substring(propertyaddress, CHARINDEX(',', propertyaddress) + 1, len(propertyaddress))

select *
from PortfolioProject..NashvilleHousing



-- split owner address using parsename
-- parsename
select owneraddress
from PortfolioProject..NashvilleHousing

select
PARSENAME(replace(owneraddress, ',', '.'), 3),
PARSENAME(replace(owneraddress, ',', '.'), 2),
PARSENAME(replace(owneraddress, ',', '.'), 1)
from PortfolioProject..NashvilleHousing

alter table NashvilleHousing
add OwnerSplitAddress nvarchar(255);

update NashvilleHousing
set OwnerSplitAddress = PARSENAME(replace(owneraddress, ',', '.'), 3)

alter table NashvilleHousing
add OwnerSplitCity nvarchar(255);

update NashvilleHousing
set OwnerSplitCity = PARSENAME(replace(owneraddress, ',', '.'), 2)

alter table NashvilleHousing
add OwnerSplitState nvarchar(255);

update NashvilleHousing
set OwnerSplitState = PARSENAME(replace(owneraddress, ',', '.'), 1)

select *
from PortfolioProject..NashvilleHousing



-- switch Y and N in "sold as vacant" field
select distinct(SoldAsVacant), count(soldasvacant)
from PortfolioProject..NashvilleHousing
group by soldasvacant

update PortfolioProject..NashvilleHousing
set SoldAsVacant = case
	when SoldAsVacant = 'Y' then 'Yes'
	when SoldAsVacant = 'N' then 'No'
	else SoldAsVacant
end



-- remove duplicates using cte
with RowNumCTE as (
select * , 
	ROW_NUMBER() over (
	partition by parcelID,
				 propertyaddress,
				 saleprice,
				 saledate,
				 legalreference
				 order by
					uniqueid
					) row_num
from PortfolioProject..NashvilleHousing
)
-- gives all duplicates
select * from RowNumCTE
where row_num > 1
order by PropertyAddress

-- remove duplicates
-- needs to be the first query after the cte
delete 
from RowNumCTE
where row_num > 1



-- delete unused columns
-- best practices: don't delete duplicates or columns
select *
from PortfolioProject..NashvilleHousing

alter table
PortfolioProject..NashvilleHousing
drop column owneraddress, taxdistrict