USE  world_layoffs;

-- 1.All records where the total number of laid-off employees is greater than 100
SELECT *
FROM layoffs_staging2
WHERE total_laid_off >= 100
;
-- 2.The number of companies in each country
SELECT country,count(company) as total_num
FROM layoffs_staging2
GROUP BY country
ORDER BY 2 DESC
;
-- 3.The total number of layoffs per industry.
SELECT industry,sum(total_laid_off)
FROM layoffs_staging2
GROUP BY industry
ORDER BY 2 DESC
;
-- 4.Find companies with the highest layoff percentage.
SELECT company,percentage_laid_off
FROM layoffs_staging2
WHERE percentage_laid_off IS NOT NULL AND percentage_laid_off !=1
ORDER BY 2 DESC 
;
-- 5.Analyze layoffs by funding stage to see which stage has the highest layoffs.
SELECT stage,SUM(total_laid_off) as total_num
FROM layoffs_staging2
WHERE total_laid_off IS NOT NULL
GROUP BY stage
ORDER BY 2 DESC 
;
-- 6.The highest layoffs event/Total layoff overtime .
SELECT substring(date,1,7),sum(total_laid_off)
FROM layoffs_staging2
GROUP BY 1
ORDER BY 1
;

-- 7.Average percentage of layoffs per industry.
SELECT industry,ROUND(AVG(percentage_laid_off),2) as avg_per_in
FROM layoffs_staging2
GROUP BY industry
ORDER BY 2 DESC 
;
-- 8.Investigate the correlation between funds raised and layoffs by calculating the average layoffs for different funding ranges.
-- find max = 121900 and min =0 should have 5 bin binsize = 25000 (should be 24380 but 25000 look more clean)
-- after doing with 5 bins i found that most laid off is in range 25001-50000 so i will do more detail in that range so binsize is 15000 this time
SELECT max(funds_raised_millions),min(funds_raised_millions)
FROM layoffs_staging2
;
SELECT CASE
WHEN funds_raised_millions between 0 and 10000 THEN '0-25,000'
WHEN funds_raised_millions between 10001 and 20000 THEN '10001 and 20000'
WHEN funds_raised_millions between 20001 and 30000 THEN '20001 and 30000'
WHEN funds_raised_millions between 30001 and 40000 THEN '30001 and 40000'
WHEN funds_raised_millions between 40001 and 50000 THEN '40001 and 50000'
WHEN funds_raised_millions > 50000 THEN 'Morethan 50,000'
ELSE NULL END as funding_range
,ROUND(AVG(total_laid_off),2)
FROM layoffs_staging2
WHERE funds_raised_millions IS NOT NULL
GROUP BY 1
ORDER BY 1 
;
-- 9.Top 3 countries with the highest total layoffs per industry.
SELECT country,industry,sum(total_laid_off)
FROM layoffs_staging2
GROUP BY country,industry
ORDER BY 3 DESC
LIMIT 3
;

-- 10.Top 5 industries with the highest layoff percentages.
SELECT industry,ROUND(AVG(percentage_laid_off),2) AS max_percent
FROM layoffs_staging2
where percentage_laid_off != 1 AND percentage_laid_off IS NOT NULL AND percentage_laid_off != ''
GROUP BY industry
ORDER BY 2 DESC
;

-- 11.The rolling total of layoffs per month to observe trends.
SELECT DISTINCT(substring(date,1,7)) as month,SUM(total_laid_off) OVER(ORDER BY substring(date,1,7))
FROM layoffs_staging2
WHERE substring(date,1,7) IS NOT NULL 
ORDER BY 1 
;
-- 12.Compare layoffs between early-stage (Pre-IPO) and late-stage (Post-IPO) companies.
SELECT CASE
WHEN stage in ('Seed','Series A','Series B','Series C') THEN 'early-stage'
WHEN stage in ('Series D','Series E','Series F','Series G','Series H','Series I','Series J','Post-IPO') THEN 'late-stage'
ELSE 'Unknow' END AS stageipo
,SUM(total_laid_off)
FROM layoffs_staging2
WHERE stage IS NOT NULL or stage != ''
GROUP BY 1
;
-- 13.Average layoffs per industry and filter industries where the average layoffs exceed 500.
SELECT industry,AVG(total_laid_off)
FROM layoffs_staging2
GROUP BY industry
HAVING AVG(total_laid_off) >=500
;
-- 14.Rank companies within each industry based on the number of employees laid off.
--  do cte to know what is rank1 in each industry
with rank_laid AS (
SELECT industry,company,RANK() OVER(PARTITION BY industry ORDER BY total_laid_off DESC) AS rank_in
FROM layoffs_staging2
WHERE industry IS NOT NULL
)
SELECT industry,company
FROM rank_laid
WHERE rank_in = 1
;

-- 15.Find the largest single layoff event in each country.
with cte_country AS (
SELECT country,DENSE_RANK() OVER(PARTITION BY country ORDER BY total_laid_off DESC) AS rank_country,total_laid_off
FROM layoffs_staging2
)
SELECT country,total_laid_off
FROM cte_country
WHERE rank_country = 1
ORDER BY 2 DESC
;
-- 16.The running total of layoffs per industry.
SELECT industry,SUM(total_laid_off) OVER(PARTITION BY industry ORDER BY substring(date,1,7)),substring(date,1,7)
FROM layoffs_staging2
WHERE industry IS NOT NULL 
;

-- 17.Find companies where layoffs are higher than the industry average.
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

-- 18.the rank of highest laidoff per year 
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
