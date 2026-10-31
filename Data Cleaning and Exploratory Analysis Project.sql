SELECT * 
FROM layoffs;

-- CREATING A STAGING ENVIRONMENT 

CREATE TABLE layoffs_staging
LIKE layoffs;

SELECT *
FROM  layoffs_staging;

INSERT  layoffs_staging
SELECT *
FROM layoffs;

SELECT *,
ROW_NUMBER() OVER( PARTITION BY company,location,industry,total_laid_off,percentage_laid_off, `date`,stage,country,funds_raised_millions) AS 
raw_num
FROM  layoffs_staging;

-- REMOVING DUPLICATES

WITH duplicate_cte AS 
(
SELECT *,
ROW_NUMBER() OVER( PARTITION BY company,location,industry,total_laid_off,percentage_laid_off, `date`,stage,country,funds_raised_millions) AS 
row_num
FROM  layoffs_staging)
SELECT *
FROM duplicate_cte
WHERE row_num >1;

WITH duplicate_cte AS 
(
SELECT *,
ROW_NUMBER() OVER( PARTITION BY company,location,industry,total_laid_off,percentage_laid_off, `date`,stage,country,funds_raised_millions) AS 
row_num
FROM  layoffs_staging)
DELETE 
FROM duplicate_cte
WHERE row_num >1;

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

SELECT*
FROM layoffs_staging2;

INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER( PARTITION BY company,location,industry,total_laid_off,percentage_laid_off, `date`,stage,country,funds_raised_millions) AS 
row_num
FROM  layoffs_staging;

SELECT*
FROM layoffs_staging2
WHERE row_num>1;

SET SQL_SAFE_UPDATES =0;

DELETE
FROM layoffs_staging2
WHERE row_num>1;

SELECT*
FROM layoffs_staging2
WHERE row_num>1;

-- STANDARDIZING DATA

SELECT*
FROM layoffs_staging2;

SELECT DISTINCT(TRIM(company))
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company= TRIM(company);

SELECT company,TRIM(company)
FROM layoffs_staging2;

SELECT industry
FROM layoffs_staging2
ORDER BY industry ASC;

SELECT*
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

SELECT DISTINCT location
FROM layoffs_staging2
ORDER BY location ASC;

SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY country ASC;

SELECT DISTINCT country,TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
ORDER BY 1;

UPDATE layoffs_staging2
SET country =TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States %';

SELECT `date`,
STR_TO_DATE(`date`,'%m/%d/%Y')
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET `date`= STR_TO_DATE(`date`,'%m/%d/%Y');

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

-- NULL & BLANK VALUES
 
SELECT*
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

SELECT *
FROM layoffs_staging2
WHERE industry IS NULL
OR industry='';

UPDATE layoffs_staging2
SET industry = NULL 
WHERE industry='';

SELECT*
FROM layoffs_staging2 AS t1
JOIN layoffs_staging2 AS t2
      ON t1.company=t2.company
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;    

UPDATE layoffs_staging2 AS t1
JOIN layoffs_staging2 AS t2
      ON t1.company=t2.company
SET t1.industry=t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;   

-- REMOVING ROWS OR COLUMNS THAT ARE NOT NECESSARY 

SELECT*
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

-- Exploratory Data Analysis


SELECT*
FROM layoffs_staging2;


SELECT company,industry
FROM layoffs_staging2
ORDER BY industry ASC;

SELECT MAX(total_laid_off),MAX(percentage_laid_off)
FROM layoffs_staging2;

SELECT*
FROM layoffs_staging2
WHERE percentage_laid_off=1
ORDER BY total_laid_off DESC;

CREATE TABLE layoffs_staging2_backup AS 
SELECT DISTINCT *
FROM layoffs_staging2;

SELECT*
FROM layoffs_staging2_backup
WHERE percentage_laid_off=1
ORDER BY total_laid_off DESC;

SELECT*
FROM layoffs_staging2_backup
WHERE percentage_laid_off=1
ORDER BY funds_raised_millions DESC;

SELECT company,SUM(total_laid_off)
FROM layoffs_staging2_backup
GROUP BY company
ORDER BY 2 DESC;

SELECT MIN(`date`),MAX(`date`)
FROM layoffs_staging2_backup;


SELECT industry,SUM(total_laid_off)
FROM layoffs_staging2_backup
GROUP BY industry
ORDER BY 2 DESC;


SELECT country,SUM(total_laid_off)
FROM layoffs_staging2_backup
GROUP BY country
ORDER BY 2 DESC;


SELECT YEAR(`date`),SUM(total_laid_off)
FROM layoffs_staging2_backup
GROUP BY YEAR(`date`)
ORDER BY 1 DESC;

SELECT stage,SUM(total_laid_off)
FROM layoffs_staging2_backup
GROUP BY stage
ORDER BY 2 DESC;

SELECT SUBSTRING(`date`,1,7) AS `MONTH`,SUM(total_laid_off)
FROM layoffs_staging2_backup
WHERE SUBSTRING(`date`,1,7) IS NOT NULL
GROUP BY `MONTH`
ORDER BY 1 ASC;

WITH rolling_total AS (
SELECT SUBSTRING(`date`,1,7) AS `MONTH`,SUM(total_laid_off) AS sum_total
FROM layoffs_staging2_backup
WHERE SUBSTRING(`date`,1,7) IS NOT NULL
GROUP BY `MONTH`
ORDER BY 1 ASC)
SELECT `MONTH`,sum_total,SUM(sum_total) OVER(ORDER BY `MONTH`) AS rolling_total
FROM rolling_total;



SELECT country,YEAR(`date`),SUM(total_laid_off)
FROM layoffs_staging2_backup
GROUP BY country,YEAR(`date`)
ORDER BY 1 ASC;

WITH company_year(company,years,total_laid_off) AS 
(
SELECT country,YEAR(`date`),SUM(total_laid_off)
FROM layoffs_staging2_backup
GROUP BY country,YEAR(`date`)
)
SELECT *,DENSE_RANK() OVER(PARTITION BY years ORDER BY total_laid_off) AS ranking
FROM company_year;






















