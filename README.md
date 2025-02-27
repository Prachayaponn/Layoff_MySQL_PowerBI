# Layoff Analysis (2020-2023) – Power BI & SQL
Analyzing global layoff trends across industries, funding stages, and companies using SQL & Power BI

## Project Overview
This project explores **layoff trends from 2020 to 2023**, analyzing **which industries, countries, and funding stages** were most affected. The dataset includes information about layoffs from various companies, their funding, and the percentage of employees laid off.

## Key Objectives
- Identify layoff trends over time
- Compare layoffs by industry, country, and funding stage
- Analyze the impact of company growth stage (early vs. late)
- Use SQL for data analysis and Power BI for visualization

## Dataset Overview
- Columns:
    - company – Name of the company
    - location – City of headquarters
    - industry – Industry sector
    - total_laid_off – Number of employees laid off
    - percentage_laid_off – % of workforce affected
    - date – Date of the layoff event
    - stage – Funding stage (Series A, B, IPO, etc.)
    - country – Country of the company
    - funds_raised_millions – Total funds raised

 ## Key Insights & Findings
- Total layoffs peaked in January 2023, with the largest single layoff event affecting 84,714 employees.
- The United States experienced the highest layoffs, followed by India, Canada, Brazil, and Germany.
- The Consumer industry was most affected, followed by Retail, Transportation, and Finance.
- Companies in the $10M - $30M funding range saw the highest layoffs, indicating possible over-expansion risks.
- Late-stage companies saw the highest layoffs, while early-stage startups had fewer job cuts.
- Uber, Booking.com, and Groupon had the highest layoffs in their respective years.

## Some interesting queries
**Data cleaning** 
Create new table for delete duplicate
```
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
```

fill out some information in 'industry' column
```
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
```

**Exploratory data analysis**
the rank of highest laidoff per year 
```
WITH hightest AS (
SELECT company,YEAR(date) as year,SUM(total_laid_off) as total_num
FROM layoffs_staging2
GROUP BY company,YEAR(date)
)
,
company_year_rank AS (
SELECT company,year,total_num,dense_rank() OVER(PARTITION BY year ORDER BY total_num DESC) as company_rank
FROM hightest
WHERE year IS NOT NULL 
)
SELECT *
FROM company_year_rank
WHERE company_rank <= 5
;
```

Find companies where layoffs are higher than the industry average.
```
WITH avg_in AS (
SELECT industry,AVG(total_laid_off) as AVG_in
FROM layoffs_staging2
GROUP BY industry
)

SELECT company,total_laid_off,ROUND(AVG_in,2),avg_in.industry
FROM layoffs_staging2
LEFT JOIN avg_in
USING (industry)
WHERE total_laid_off >= AVG_in
ORDER BY 2 DESC
;
```
Find the largest single layoff event in each country.
```
with cte_country AS (
SELECT country,DENSE_RANK() OVER(PARTITION BY country ORDER BY total_laid_off DESC) AS rank_country,total_laid_off
FROM layoffs_staging2
)
SELECT country,total_laid_off
FROM cte_country
WHERE rank_country = 1
ORDER BY 2 DESC
;
```
