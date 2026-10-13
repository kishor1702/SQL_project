# Retail Sales & Inventory Intelligence — PostgreSQL

A GitHub-ready Data Analyst portfolio project built around the **UCI Online Retail** dataset.

## Dataset
Source: UCI Machine Learning Repository — Online Retail.
- 541,909 transaction rows
- 01-Dec-2010 to 09-Dec-2011
- UK-based non-store online retailer
- Fields include InvoiceNo, StockCode, Description, Quantity, InvoiceDate, UnitPrice, CustomerID and Country.
- License: CC BY 4.0

The raw workbook is intentionally **not committed** to this repository. Download it from UCI and place it at:

`data/raw/Online Retail.xlsx`

Official source: https://archive.ics.uci.edu/dataset/352/online%2Bretail

## Important modeling note
The source dataset is an online retailer transaction log and does not provide physical stores, product categories or inventory snapshots.

For the requested relational model:
- `categories` are derived from product descriptions using transparent keyword rules.
- `stores` are analytical virtual sales regions derived from customer country.
- `inventory` is a derived planning layer based on observed sales velocity; it is not historical source-system inventory.

This keeps the project honest and reproducible while still demonstrating retail inventory analytics.

## Project objectives
- Analyze sales and order trends.
- Rank products, customers and stores.
- Identify high-value customers.
- Identify stock-outs and low-stock products.
- Detect slow-moving products.
- Analyze monthly revenue trends.
- Demonstrate joins, CTEs, subqueries, CASE, aggregation, date functions, window functions, RANK, DENSE_RANK, ROW_NUMBER, LAG, LEAD, running totals and percentage contribution.

## Repository structure

```text
retail-sales-inventory-intelligence/
├── README.md
├── .gitignore
├── requirements.txt
├── sql/
│   ├── 01_schema.sql
│   ├── 02_load_data.sql
│   └── 03_40_analytical_queries.sql
├── etl/
│   └── prepare_online_retail.py
├── data/
│   └── raw/
│       └── README.md
└── docs/
    └── business_questions.md
```

## Setup

### 1. Create database

```sql
CREATE DATABASE retail_intelligence;
```

Connect to it:

```bash
psql -U postgres -d retail_intelligence
```

### 2. Install ETL dependencies

```bash
pip install -r requirements.txt
```

### 3. Download the source data
Download `Online Retail.xlsx` from UCI and place it in `data/raw/`.

### 4. Prepare CSV files

```bash
python etl/prepare_online_retail.py
```

The script:
- removes cancelled invoices for the core sales model;
- removes rows with missing CustomerID from customer-linked records while retaining guest sales at order level;
- standardizes product codes and descriptions;
- derives product categories;
- derives virtual stores from customer country;
- creates clean CSVs for PostgreSQL;
- produces a derived inventory planning dataset.

### 5. Create tables

```bash
psql -U postgres -d retail_intelligence -f sql/01_schema.sql
```

### 6. Load data

Update the `\copy` paths in `sql/02_load_data.sql` if required, then:

```bash
psql -U postgres -d retail_intelligence -f sql/02_load_data.sql
```

### 7. Run analysis

```bash
psql -U postgres -d retail_intelligence -f sql/03_40_analytical_queries.sql
```

## Portfolio highlights
This project demonstrates:
- normalized relational modeling;
- PostgreSQL data loading;
- analytical SQL;
- retail KPI design;
- customer and product segmentation;
- inventory risk analysis;
- window functions;
- business-oriented recommendations.

## Suggested resume bullet

> Built a PostgreSQL Retail Sales & Inventory Intelligence project using 541K+ online retail transactions, designing a normalized relational schema and 40+ analytical SQL queries to evaluate product performance, customer value, store/region performance, monthly trends, stock risk and slow-moving inventory using CTEs, joins, subqueries and advanced window functions.
