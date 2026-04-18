# Phone Market Data Cleaning & Transformation — SQL Server

## 1. Business Problem

Raw e-commerce catalog data is rarely analysis-ready.
Phone listings often contain duplicate entries, missing specifications,
inconsistent formats, and valuable information buried inside unstructured text fields.

This project addresses a core data Cleaning question:

> "How can we transform a raw, inconsistent mobile phone catalog
>  into a clean, structured dataset ready for pricing analysis
>  and market reporting?"

---

## 2. Dataset

| Field | Details |
|---|---|
| Source | Mobile Phone E-Commerce Catalog |
| Raw Records | 1,224 rows |
| Brands | 50+ brands (Apple, Samsung, Xiaomi, Nokia, HUAWEI, and more) |
| Price Range | ~214 to ~56,082 |
| Period | 2013 – 2021 |

### Columns

| Column | Type | Description |
|---|---|---|
| brand_name | Text | Phone manufacturer |
| model_name | Text | Full model name (contains embedded specs) |
| os | Text | Operating system |
| popularity | Integer | Popularity score |
| best_price | Decimal | Best available market price |
| lowest_price | Decimal | Lowest seller price |
| highest_price | Decimal | Highest seller price |
| sellers_amount | Integer | Number of active sellers |
| screen_size | Decimal | Screen size in inches |
| memory_size | Decimal | Internal storage in GB |
| battery_size | Decimal | Battery capacity in mAh |
| release_date | Text → Date | Release date (raw: MM-YYYY) |

---

## 3. Data Quality Issues Found

| Issue | Column(s) | Scale |
|---|---|---|
| Duplicate rows | brand_name + model_name | ~350 rows |
| Missing OS | os | ~180 rows |
| Missing prices | lowest_price, highest_price | ~320 rows each |
| Missing memory | memory_size | ~35 rows |
| Missing screen size | screen_size | ~2 rows |
| Missing battery | battery_size | ~15 rows |
| Wrong date format | release_date | All rows (stored as MM-YYYY string) |
| Hidden specs in text | model_name | All rows |

---

## 4. Technical Approach

### Tools & Environment
- **Database:** Microsoft SQL Server
- **Language:** T-SQL

### Methodology

**Step 1 — Data Audit**
- Measured missing values across all 13 columns
- Identified duplicate records using GROUP BY + HAVING COUNT(*) > 1

**Step 2 — Duplicate Removal**
- Used ROW_NUMBER() with PARTITION BY brand_name, model_name
  to rank duplicate rows and delete all but the first occurrence
- Note: Phones sharing the same model_name but differing only
  in color are consolidated into one representative record

**Step 3 — Critical Row Deletion**
- Deleted rows where screen_size or battery_size were NULL
- These are non-imputable physical attributes —
  no statistical method can reliably substitute them

**Step 4 — Categorical Imputation**
- Filled NULL values in os column with 'Unknown'
- Applies to feature phones that have no operating system

**Step 5 — Numeric Imputation by Median**
- Compared mean vs. median for lowest_price, highest_price,
  and memory_size to assess the impact of price outliers
- Selected Median (PERCENTILE_CONT) as the imputation strategy
  due to significant right skew caused by flagship phone prices
- Stored median values in DECLARE variables for efficient
  single-pass UPDATE operations

**Step 6 — Date Formatting**
- Converted release_date from 'MM-YYYY' string format
  to a proper SQL DATE type using CONVERT with format code 105
- Assumed day = 01 for all records

**Step 7 — Feature Engineering via String Parsing**
- Added two new permanent columns: ram_size and phone_color
- Used a CTE to extract both features from model_name
  using prioritized CASE WHEN / LIKE logic
- RAM extraction uses fraction pattern first (e.g., 4/64GB → 4GB)
  before falling back to standalone storage patterns
- Color extraction covers 18 color keywords
- Persisted results using a professional UPDATE...JOIN pattern

**Step 8 — Final Validation**
- Re-ran NULL checks across all critical columns
- Confirmed zero remaining nulls in imputed columns
- Verified final row count post-cleaning

---

## 5. Key Results

| Metric | Before | After |
|---|---|---|
| Total Rows | 1,224 | ~850 |
| Duplicate Rows | ~350 | 0 |
| NULL in os | ~180 | 0 |
| NULL in lowest_price | ~320 | 0 |
| NULL in highest_price | ~320 | 0 |
| NULL in memory_size | ~35 | 0 |
| release_date format | MM-YYYY string | DATE type |
| ram_size column | Not present | Extracted |
| phone_color column | Not present | Extracted |

---

## 6. SQL Techniques Demonstrated

| Technique | Usage |
|---|---|
| CTE | Duplicate detection and feature extraction logic |
| ROW_NUMBER() | Ranking duplicates for targeted deletion |
| PERCENTILE_CONT | Robust median calculation for imputation |
| DECLARE Variables | Storing medians for efficient UPDATE operations |
| UPDATE...JOIN | Persisting CTE-calculated features to main table |
| CONVERT(DATE) | Transforming string dates to proper DATE type |
| CASE WHEN / LIKE | Prioritized string parsing for RAM and color extraction |
| SP_HELP | Schema inspection before processing |

---
