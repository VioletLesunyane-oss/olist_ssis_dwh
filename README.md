# 🛒 Brazilian E-Commerce Data Warehouse (Olist)

An automated end-to-end data pipeline and reporting warehouse built with **SQL Server (SSMS)** and **SQL Server Integration Services (SSIS)**. This project turns raw, messy online store spreadsheets into clean, reliable business reports.

---

## 📑 Table of Contents

1. [Project Overview](#-project-overview)
2. [How the Data Flows (The Medallion Architecture)](#-how-the-data-flows-the-medallion-architecture)
3. [Repository Folder Structure](#-repository-folder-structure)
4. [Phase-by-Phase Walkthrough](#-phase-by-phase-walkthrough)
   - [Phase 0: Setting Up the Database & Tracking Logs](#phase-0-setting-up-the-database--tracking-logs)
   - [Phase 1: Bronze Layer (Raw Data Landing)](#phase-1-bronze-layer-raw-data-landing)
   - [Phase 2: Silver Layer (Cleaning & Fixing Data Quirks)](#phase-2-silver-layer-cleaning--fixing-data-quirks)
   - [Phase 3: Gold Layer (Star Schema for Reporting)](#phase-3-gold-layer-star-schema-for-reporting)
   - [Phase 4: Master Automation & Orchestration](#phase-4-master-automation--orchestration)
   - [Phase 5: Automated Data Quality Checks](#phase-5-automated-data-quality-checks)
   - [Phase 6: Business Analytics & Insights](#phase-6-business-analytics--insights)
5. [How to Run This Project](#-how-to-run-this-project)

---

## 🎯 Project Overview

**Olist** is a large Brazilian e-commerce marketplace that connects small businesses with customers across Brazil. Their public dataset contains roughly **100,000 real orders** spread across **9 separate CSV files** covering customers, orders, items, payments, reviews, products, sellers, locations, and category translations.

### The Problem
Raw CSV files are difficult to report on directly. They contain duplicate locations, duplicate customer reviews, missing translations, misspelled column names, and dates stored as plain text.

### The Solution
We built an automated **Data Warehouse (`olist_dwh`)** that:
- Collects all 9 raw files automatically without manual copy-pasting.
- Cleans, standardizes, and catches broken records in an error log instead of silently losing them.
- Organizes the clean data into an easy-to-query **Star Schema** for business reporting.
- Tracks every run in an audit log and runs 10 automated quality checks before marking a run successful.

---

## 🏗️ How the Data Flows (The Medallion Architecture)

We organized the warehouse into three progressive layers—**Bronze**, **Silver**, and **Gold**—plus a dedicated **ETL** tracking area:

```text
[ 9 Raw CSV Files ]
        │
        ▼
┌───────────────────┐
│   BRONZE LAYER    │  ➔ Raw landing zone (exact copy of CSV files, nothing changed)
└────────┬──────────┘
         │
         ▼
┌───────────────────┐
│   SILVER LAYER    │  ➔ Clean & standardized data (duplicates removed, types fixed)
└────────┬──────────┘
         │
         ▼
┌───────────────────┐
│    GOLD LAYER     │  ➔ Business-ready Star Schema (7 Lookup Lists + 3 Fact Tables)
└───────────────────┘
```

---

## 📂 Repository Folder Structure

```text
olist_ssis_dwh/
├── data/                  # Raw Olist CSV source files
├── SSMS/                  # SQL scripts to create databases, tables, seeds, and reports
│   ├── 00_create_database.sql
│   ├── 01_create_schemas.sql
│   ├── 02_bronze_tables.sql
│   ├── 03_silver_tables.sql
│   ├── 04_gold_tables.sql
│   ├── 05_seed_unknown_rows.sql
│   └── 06_analytics_queries.sql
├── SSIS/ olist_dwh/       # Visual Studio SSIS packages for automated data movement
│   ├── Project.params
│   ├── 00_master.dtsx
│   ├── 01_bronze_load.dtsx
│   ├── 02_silver_transform.dtsx
│   ├── 03_gold_dimensions.dtsx
│   └── 04_gold_facts.dtsx
├── tests/                 # Automated quality checks to verify data accuracy
│   └── data_quality_checks.sql
└── README.md              # Project documentation
```

---

## 🚀 Phase-by-Phase Walkthrough

### Phase 0: Setting Up the Database & Tracking Logs
Before moving any data, we created the **`olist_dwh`** database and separated it into four clean workspaces (`bronze`, `silver`, `gold`, and `etl`). We also built three tracking tables inside `etl`:
- **`etl.batch_log`:** Records when each pipeline run starts, finishes, and whether it succeeded or failed.
- **`etl.load_log`:** Tracks how many rows were read, written, or rejected for every single table.
- **`etl.error_rows`:** Acts as a quarantine bin that saves any broken rows so nothing disappears silently.

---

### Phase 1: Bronze Layer (Raw Data Landing)
- **Package:** `01_bronze_load.dtsx`
- **What happens here:** SSIS reads all 9 CSV files from a dynamic folder path (no hard-coded local paths) and loads them into the `bronze` tables.
- **Why we keep it raw:** Every column is stored as plain text first so that unexpected characters or formatting quirks never crash the initial import. Every row is stamped with the exact load time, source file name, and batch run ID.

---

### Phase 2: Silver Layer (Cleaning & Fixing Data Quirks)
- **Package:** `02_silver_transform.dtsx`
- **What happens here:** Raw text is converted into proper numbers, dates, and clean text. Using SSIS transforms (**Derived Column**, **Data Conversion**, **Lookup**, and **Conditional Split**), we solved all known quirks in the Olist dataset:
  - **Zip Codes:** Padded short postal codes with leading zeros so every prefix is 5 digits (e.g., `1046` becomes `01046`).
  - **City & State Names:** Trimmed extra spaces, standardized city names, and made state codes uppercase (e.g., `sp` becomes `SP`).
  - **Duplicate Locations:** Collapsed over 1 million repeated geolocation coordinates down to **1 clean average coordinate per zip code**.
  - **Duplicate Reviews:** Removed duplicate review entries by keeping only the most recent response for each review.
  - **Spelling Fixes & Missing Translations:** Fixed typos in the raw product columns (`lenght` → `length`), added missing English category translations (`pc_gamer` and `kitchen_portables_and_food_preparators`), and labeled missing categories as `Unknown`.
  - **Delivery Metrics & Canceled Orders:** Flagged delivered orders cleanly while keeping empty delivery dates intact for canceled orders.
  - **Error Quarantine:** Any row with missing IDs or unreadable dates is routed directly to `etl.error_rows` instead of being dropped.

---

### Phase 3: Gold Layer (Star Schema for Reporting)
- **Packages:** `03_gold_dimensions.dtsx` and `04_gold_facts.dtsx`
- **What happens here:** The clean Silver data is organized into a **Star Schema** designed for fast, simple business reporting.
- **7 Dimension Tables (Reference Lists):**
  - `dim_date` (Calendar dates from 2016–2019), `dim_geography`, `dim_product`, `dim_seller`, `dim_order_status`, `dim_payment_type`, and `dim_customer`.
  - **Tracking Customer History (SCD Type 2):** Because Olist assigns a new `customer_id` to every order, we used `customer_unique_id` to track real people over time—recording when a customer moves to a new city or state without overwriting their past history.
  - **`-1` Unknown Placeholders:** Every list includes a `-1` `"Unknown"` fallback record so reports never break if a detail is missing.
- **3 Fact Tables (Business Measurements):**
  - `fact_sales`: Tracks every item sold, item price, shipping cost, total item value, actual delivery days, and whether the order arrived late.
  - `fact_payments`: Tracks payment methods, installment counts, and payment amounts.
  - `fact_reviews`: Tracks customer satisfaction scores (1 to 5 stars) and survey timestamps.

---

### Phase 4: Master Automation & Orchestration
- **Package:** `00_master.dtsx`
- **What happens here:** Instead of running packages one by one, `00_master.dtsx` acts as the single control switch for the entire warehouse:
  1. Creates a new batch ID in `etl.batch_log` (`RUNNING`).
  2. Runs **Bronze** ➔ **Silver** ➔ **Gold Dimensions** ➔ **Gold Facts** in strict order, passing the batch ID down to every child package.
  3. Runs automated quality checks.
  4. Marks the batch `SUCCEEDED` if everything passes—or automatically catches any failure and marks the batch `FAILED`.
- **Safe to Re-Run:** Running `00_master.dtsx` multiple times produces identical, duplicate-free results every single time.

---

### Phase 5: Automated Data Quality Checks
- **Script:** `tests/data_quality_checks.sql`
- **What happens here:** We built **10 automated checks** that scan the warehouse for missing keys, duplicate records, broken math (`price + freight ≠ total`), orphaned links, and invalid delivery dates. Every check must return **0 errors** before a batch is approved.

---

### Phase 6: Business Analytics & Insights
- **Script:** `SSMS/06_analytics_queries.sql`
- **What happens here:** We wrote **8 business queries** answering key operational questions for Olist:
  1. **Monthly Revenue & Order Trends (2017–2018):** Tracks order growth, item sales, and shipping revenue month by month.
  2. **Top 10 Product Categories:** Identifies the highest-earning product categories in English.
  3. **Payment Preferences:** Shows revenue share and average installment plans across credit cards, boletos, vouchers, and debit cards.
  4. **Delivery Performance by State:** Compares average delivery times and late-delivery percentages across Brazilian states.
  5. **Top 10 States by Customer Spend:** Highlights regional purchasing power and Average Order Value (AOV).
  6. **Top 10 Sellers & Satisfaction:** Ranks top-performing sellers alongside their average customer review scores.
  7. **Customer Retention Rate:** Measures how many shoppers buy once versus how many return for repeat purchases.
  8. **Impact of Late Deliveries on Reviews:** Proves how late deliveries directly drop average review scores and spike 1-star complaints.

---

## ▶️ How to Run This Project

### Step 1: Set Up the Database in SQL Server (SSMS)
Run the SQL scripts inside the SSMS/ folder in numerical order (00 through 05) to create the olist_dwh database, schemas, tables, and -1 Unknown placeholders.

Step 2: Configure the Folder Path in Visual Studio (SSIS)

1. Open the SSIS solution inside SSIS/ olist_dwh/.
2. Open Project.params and update p_source_folder to point to the folder containing your Olist CSV files (make sure the path ends with a backslash \).
3. Confirm the OLE DB Connection Manager (olist_dwh) points to your local SQL Server instance.

Step 3: Run the Master Pipeline

1. Right-click 00_master.dtsx in Solution Explorer and click Execute Package.
2. Once all tasks turn green, verify the run in SSMS by checking SELECT * FROM etl.batch_log; and running SSMS/06_analytics_queries.sql.
