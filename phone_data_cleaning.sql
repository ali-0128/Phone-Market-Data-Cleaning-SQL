-- =============================================
-- Phone Market Data Cleaning & Transformation

-- Goal: Transform a raw mobile phone catalog
--       into a clean, structured dataset
--       ready for pricing and market analysis
-- =============================================

-- ==============================
-- 1. DATA OVERVIEW
-- ==============================

SELECT * FROM phones;

EXEC SP_HELP phones;

-- ==============================
-- 2. DATA AUDIT
-- ==============================

-- 2.1 Missing Values Check
SELECT
    COUNT(*)                                                          AS total_rows,
    SUM(CASE WHEN brand_name     IS NULL THEN 1 ELSE 0 END)          AS missing_brand,
    SUM(CASE WHEN model_name     IS NULL THEN 1 ELSE 0 END)          AS missing_model,
    SUM(CASE WHEN os             IS NULL THEN 1 ELSE 0 END)          AS missing_os,
    SUM(CASE WHEN lowest_price   IS NULL THEN 1 ELSE 0 END)          AS missing_lowest_price,
    SUM(CASE WHEN highest_price  IS NULL THEN 1 ELSE 0 END)          AS missing_highest_price,
    SUM(CASE WHEN memory_size    IS NULL THEN 1 ELSE 0 END)          AS missing_memory,
    SUM(CASE WHEN screen_size    IS NULL THEN 1 ELSE 0 END)          AS missing_screen,
    SUM(CASE WHEN battery_size   IS NULL THEN 1 ELSE 0 END)          AS missing_battery
FROM phones;

-- 2.2 Duplicate Check
SELECT
    brand_name,
    model_name,
    COUNT(*) AS duplicate_count
FROM phones
GROUP BY brand_name, model_name
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- ==============================
-- 3. DATA CLEANING
-- ==============================

-- 3.1 Remove Duplicates
-- Keep one row per brand_name + model_name combination
WITH DuplicateCTE AS (
    SELECT *, ROW_NUMBER() OVER PARTITION BY brand_name, ORDER BY [row_number]) AS row_num
    FROM phones
)
DELETE FROM DuplicateCTE
WHERE row_num > 1;

-- 3.2 Delete Rows with Missing Critical Specs
DELETE FROM phones WHERE screen_size  IS NULL;
DELETE FROM phones WHERE battery_size IS NULL;

-- 3.3 Fill Missing OS with 'Unknown'
UPDATE phones
SET os = 'Unknown'
WHERE os IS NULL;

-- 3.4 Fill Missing Prices with Average
UPDATE phones
SET lowest_price = (SELECT AVG(lowest_price) FROM phones WHERE lowest_price IS NOT NULL)
WHERE lowest_price IS NULL;

UPDATE phones
SET highest_price = (SELECT AVG(highest_price) FROM phones WHERE highest_price IS NOT NULL)
WHERE highest_price IS NULL;

UPDATE phones
SET memory_size = (SELECT AVG(memory_size) FROM phones WHERE memory_size IS NOT NULL)
WHERE memory_size IS NULL;

-- 3.5 Date Formatting
-- Convert 'MM-YYYY' string to proper DATE format
UPDATE phones
SET release_date = CONVERT(DATE, '01-' + release_date, 105)
WHERE release_date IS NOT NULL AND ISDATE('01-' + release_date) = 1;


-- ==============================
-- 4. FEATURE ENGINEERING
-- ==============================

-- 4.1 Add New Columns
ALTER TABLE phones ADD ram_size    VARCHAR(10);
ALTER TABLE phones ADD phone_color VARCHAR(50);

-- 4.2 Extract RAM Size from model_name
UPDATE phones
SET ram_size =
    CASE
        WHEN model_name LIKE '% 1/8GB%'    OR model_name LIKE '% 1/16GB%'   THEN '1GB'
        WHEN model_name LIKE '% 2/16GB%'   OR model_name LIKE '% 2/32GB%'   THEN '2GB'
        WHEN model_name LIKE '% 3/32GB%'   OR model_name LIKE '% 3/64GB%' OR model_name LIKE '% 3/128GB%'                                     THEN '3GB'
        WHEN model_name LIKE '% 4/32GB%'   OR model_name LIKE '% 4/64GB%' OR model_name LIKE '% 4/128GB%'                                     THEN '4GB'
        WHEN model_name LIKE '% 6/64GB%'   OR model_name LIKE '% 6/128GB%' OR model_name LIKE '% 6/256GB%'                                     THEN '6GB'
        WHEN model_name LIKE '% 8/128GB%'  OR model_name LIKE '% 8/256GB%' OR model_name LIKE '% 8/512GB%'                                     THEN '8GB'
        WHEN model_name LIKE '% 12/256GB%' OR model_name LIKE '% 12/512GB%'  THEN '12GB'
        WHEN model_name LIKE '% 16GB%'     OR model_name LIKE '%(16GB%'      THEN '16GB'
        WHEN model_name LIKE '% 8GB%'      OR model_name LIKE '%(8GB%'       THEN '8GB'
        WHEN model_name LIKE '% 6GB%'      OR model_name LIKE '%(6GB%'       THEN '6GB'
        WHEN model_name LIKE '% 4GB%'      OR model_name LIKE '%(4GB%'       THEN '4GB'
        WHEN model_name LIKE '% 3GB%'      OR model_name LIKE '%(3GB%'       THEN '3GB'
        WHEN model_name LIKE '% 2GB%'      OR model_name LIKE '%(2GB%'       THEN '2GB'
        WHEN model_name LIKE '% 1GB%'      OR model_name LIKE '%(1GB%'       THEN '1GB'
        ELSE NULL
    END;

-- 4.3 Extract Phone Color from model_name
UPDATE phones
SET phone_color =
    CASE
        WHEN model_name LIKE '% black%'    THEN 'Black'
        WHEN model_name LIKE '% white%'    THEN 'White'
        WHEN model_name LIKE '% gold%'     THEN 'Gold'
        WHEN model_name LIKE '% blue%'     THEN 'Blue'
        WHEN model_name LIKE '% red%'      THEN 'Red'
        WHEN model_name LIKE '% green%'    THEN 'Green'
        WHEN model_name LIKE '% pink%'     THEN 'Pink'
        WHEN model_name LIKE '% silver%'   THEN 'Silver'
        WHEN model_name LIKE '% gray%'     THEN 'Gray'
        WHEN model_name LIKE '% grey%'     THEN 'Gray'
        WHEN model_name LIKE '% violet%'   THEN 'Violet'
        WHEN model_name LIKE '% yellow%'   THEN 'Yellow'
        WHEN model_name LIKE '% purple%'   THEN 'Purple'
        WHEN model_name LIKE '% orange%'   THEN 'Orange'
        WHEN model_name LIKE '% coral%'    THEN 'Coral'
        WHEN model_name LIKE '% copper%'   THEN 'Copper'
        WHEN model_name LIKE '% midnight%' THEN 'Midnight'
        ELSE 'Unknown/Default'
    END;


-- ==============================
-- 5. FINAL VALIDATION
-- ==============================

-- 5.1 Final row count
SELECT COUNT(*) AS final_row_count FROM phones;

-- 5.2 Confirm no nulls remain in critical columns
SELECT
    SUM(CASE WHEN os            IS NULL THEN 1 ELSE 0 END) AS remaining_null_os,
    SUM(CASE WHEN lowest_price  IS NULL THEN 1 ELSE 0 END) AS remaining_null_lowest,
    SUM(CASE WHEN highest_price IS NULL THEN 1 ELSE 0 END) AS remaining_null_highest,
    SUM(CASE WHEN memory_size   IS NULL THEN 1 ELSE 0 END) AS remaining_null_memory,
    SUM(CASE WHEN screen_size   IS NULL THEN 1 ELSE 0 END) AS remaining_null_screen,
    SUM(CASE WHEN battery_size  IS NULL THEN 1 ELSE 0 END) AS remaining_null_battery
FROM phones;

-- 5.3 Sample of final cleaned dataset
SELECT TOP 20 * FROM phones ORDER BY brand_name, model_name;