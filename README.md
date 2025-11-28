# 📊 SQL Gold Layer Project – Dashboard & Reporting  

## 📌 Overview  
This project implements the **Gold Layer** of a SQL-based data pipeline, and then the Data Analyst role comes
The Gold Layer provides **clean, aggregated, business-ready data** used for dashboards and business reports.  

### Objectives  
- Ensure **data quality**  
- Create **derived metrics** 
- Create **VIEWS for KPI calculations, then put them into SP for batch running** 
- Define **fact and dimension tables**  
- Power **dashboards & reports** with optimized SQL queries  

---

## 📂 Project Structure  
```
sql-gold-layer/
│
├── README.md               # Project overview, setup, conventions
├── scripts/                # All SQL scripts
│    ├── KPIs Views.sql     # Create views for KPIs calculations, CTEs, EDA
│    └── Quality check.sql  # Check NULLs and duplicates for Identity columns & check If there was Leading & Trailing spaces in text columns
│
├── dashboard/              # Excel, Power BI
│
└──  docs/                   # Extended docs (ERD, data dictionary, KPIs)
    ├── data-dictionary.md  # Column descriptions, Sample data, Column relationship, analytics notes
    ├── Industry Overview.docx 
    ├── ERD Model.png       # Modeling data tables and defining the relationships  
    ├── 📊 KPI → Dataset Mapping.docx    # Show how to calculate or apply KPIs on the dataset   
    └── Industry KPIs.docx  # KPI list and definitions


```

---

## 🚀 Workflow  

### 1. Setup  
- Create Git repository  
- Define coding standards  

### 2. Data Preparation  
- Check data quality (Silver quality)  
- Apply business rules  
- Create derived columns (profit, margin, session duration)  

### 3. EDA (Exploratory Data Analysis)  
- Explore distributions & anomalies  
- Validate assumptions  

### 4. Gold Layer Modeling  

### ⭐ Sales Snowflake Schema
- **Fact Table:** `orders`
- **Dimensions:** `products`, `order_items`, `order_item_refunds` as a Subdimension to `order_items`

### ⭐ Website Snowflake Schema
- **Fact Table:** `orders`
- **Dimensions:** `website_sessions`, `website_pageviews` as a Subdimension to `website_sessions`

---

### 🔗 Shared Dimensions
- **Products** → shared by `orders`, `order_items`, `order_item_refunds`
- **Date** → shared by all snowflake schemas
- **User** → shared by `orders` and `website_sessions`
- **Website Session** → bridges marketing (`website_sessions`) with sales (`orders`)



### 5. KPI Calculations  
- GMV (Gross Merchandise Value)  
- CLV (Customer Lifetime Value)  
- Conversion Rate  
- Churn Rate
- More KPIs are in the mapping file 

### 6. Dashboard & Reports  
- Connect BI tool (Power BI)  
- Create dashboards (executive overview + drilldowns)  
- Validate numbers with SQL queries  

---

## 📑 Documentation  

Extended documentation is in the **docs/** folder:  
- `docs/erd.png` → Entity Relationship Diagram  
- `docs/data-dictionary.md` → Columns, Sample data, Columns relationships, Quality check → [Data Dictionary](docs/data-dictionary.md)
- `docs/Industry Overview.docx` → E-Commerce industry overview report 
- `docs/Industry KPIs.docx` → KPI formulas & explanations  
- `📊 KPI → Dataset Mapping.docx` → Dataset KPIs calculations
---

## ✅ Deliverables  
- SQL scripts for **Gold Layer tables & KPIs**  
- **Documentation** of KPI definitions & formulas  
- **Dashboard** (Excel / Power BI) with KPIs & drilldowns  
- Git repository with version-controlled code  

---

## 👨‍💻 Contributors  
- Project Team Leader: Nouran 
- Data Engineering Support: Omar  
- Data Analyst & BI Developer: Manar, Faris, Hassan, Nouran, Omar

---
