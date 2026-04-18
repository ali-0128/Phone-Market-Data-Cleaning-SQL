# Phone Market Data Cleaning & Transformation — SQL Server

## 1. Business Problem

Raw e-commerce catalog data is rarely analysis-ready.
Phone listings often contain duplicate entries, missing specifications,
inconsistent formats, and valuable information buried inside unstructured text fields.

This project addresses a core data question:

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

| Column | Description |
|---|---|
| brand_name | Phone manufacturer |
| model_name | Full model name (contains embedded specs) |
| os | Operating system |
| popularity | Popularity score |
| best_price | Best available market price |
| lowest_price | Lowest seller price |
| highest_price | Highest seller price |
| sellers_amount | Number of active sellers |
| screen_size | Screen size in inches |
| memory_size | Internal storage in GB |
| battery_size | Battery capacity in mAh |
| release_date | Release date (raw format: MM-YYYY) |

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
| Wrong date format | release_date | All rows (MM-YYYY string) |
| Hidden specs in text | model_name | All rows |

---

## 4. Technical Approach

### Tools & Environment
- **Database:** Microsoft SQL Server
- **Language:** T-SQL

### Methodology

**Step 1 — Data Audit**
- Measured missing values across all columns using CASE WHEN + SUM
- Identified duplicate records using GROUP BY + HAVING COUNT(*) > 1

**Step 2 — Duplicate Removal**
- Used ROW_NUMBER() with PARTITION BY brand_name, model_name
  to rank duplicate rows and delete all but the first occurrence

**Step 3 — Critical Row Deletion**
- Deleted rows where screen_size or battery_size were NULL
- These are physical attributes that cannot be estimated or replaced

**Step 4 — Categorical Imputation**
- Filled NULL values in os with 'Unknown'
- Applies to feature phones that have no operating system

**Step 5 — Numeric Imputation by Average**
- Filled missing lowest_price, highest_price, and memory_size
  using AVG calculated from non-null rows
- Applied via subquery UPDATE for simplicity and clarity

**Step 6 — Date Formatting**
- Converted release_date from 'MM-YYYY' string
  to a proper SQL DATE type using CONVERT with format code 105
- Assumed day = 01 for all records

**Step 7 — Feature Engineering**
- Added two new columns: ram_size and phone_color
- Extracted RAM size from model_name using prioritized CASE WHEN / LIKE
  (fraction pattern X/YGB takes priority over standalone storage size)
- Extracted phone color from 17 color keywords in model_name
- Applied directly via UPDATE statements

**Step 8 — Final Validation**
- Re-ran NULL checks across all critical columns
- Confirmed zero remaining nulls
- Verified final row count after all deletions

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
| CTE | Duplicate detection and targeted deletion |
| ROW_NUMBER() | Ranking duplicate rows for removal |
| CASE WHEN / LIKE | String parsing for RAM and color extraction |
| Subquery UPDATE | Average-based imputation for missing numerics |
| CONVERT(DATE) | Transforming string dates to proper DATE type |
| GROUP BY + HAVING | Identifying duplicate combinations |
| SP_HELP | Schema inspection before processing |
