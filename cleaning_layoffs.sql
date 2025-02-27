USE  world_layoffs;

SELECT *
FROM layoffs_staging
LIMIT 100
;

-- TO DO LIST
-- 1.remove duplicates
-- 2. Standardize the Data
-- 3. Null Values or blank values
-- 4. Remove Any column or row

-- create a new table for changing raw data
CREATE TABLE layoffs_staging LIKE layoffs ;
INSERT layoffs_staging SELECT * FROM layoffs ;

-- 1. Remove duplicate
-- need to add a row number column cause it didn't has any unique key
-- do a row number to match column
SELECT *,ROW_NUMBER() OVER(
PARTITION BY company,industry,total_laid_off,percentage_laid_off,'date') as row_num
FROM layoffs_staging
;

WITH duplicate_cte AS (
SELECT *,ROW_NUMBER() OVER(
PARTITION BY company,location,industry,total_laid_off,percentage_laid_off
,'date',stage,country,funds_raised_millions) as row_num
FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
where row_num > 1
;

-- create new table for delete duplicate cause we cannot delete from duplicate_cte
CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` int 
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO layoffs_staging2
SELECT *,ROW_NUMBER() OVER(PARTITION BY company,location,industry,total_laid_off,percentage_laid_off,'date',stage,country,funds_raised_millions) as row_num
FROM layoffs_staging
;

DELETE
FROM layoffs_staging2
where row_num > 1
;


-- 2. Standardize the Data
-- find out that it got a space in company column so we need to trim 
SELECT TRIM(company),company
FROM layoffs_staging2
;
UPDATE layoffs_staging2
SET company =  TRIM(company)
;
-- find out that In industry column has 3 different way to write cryptocurrency
select DISTINCT(industry)
FROM layoffs_staging2
order by 1
;
UPDATE layoffs_staging2 
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%' ;

-- find out that in country column has 2 different way to write United states
SELECT DISTINCT(country),TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2 
ORDER BY 1
;
UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country like 'United States%'
;

-- change date format
SELECT date,str_to_date(date,'%m/%d/%Y')
FROM layoffs_staging2
;
UPDATE layoffs_staging2
SET date = str_to_date(date,'%m/%d/%Y') 
;
ALTER TABLE layoffs_staging2
MODIFY COLUMN date DATE 
;

-- 3. Null Values or blank values
-- has null value in industry,total_laid_off,percentage_laid_off column 
-- fill only industry column because the rest of column need more information from another department
-- -industry column
SELECT t1.industry,t2.industry
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
ON t1.company = t2.company
WHERE (t1.industry IS NULL OR t1.industry = '') AND t2.industry IS NOT NULL
;
-- change ' ' to null 
UPDATE layoffs_staging2 
SET industry = null
WHERE industry = ''
;
-- fill null with correct industry
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL  AND t2.industry IS NOT NULL
;

-- 4. Remove Any column or row
-- need to calculate by using total_laid_off,percentage_laid_off so the column that both column is null,need to delete
DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL AND percentage_laid_off IS NULL
;
ALTER TABLE layoffs_staging2
DROP COLUMN row_num
;

