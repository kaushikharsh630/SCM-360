# SCM 360°: Supply Chain Control Tower for ABC World Pvt Ltd

An end-to-end supply chain analytics project for a fictional mid-sized Indian manufacturer of industrial components. It covers supplier performance, demand planning, production capacity and supply risk, ending in a control tower dashboard.

> Status: **Week 1 of 4** (business case and data foundation)

## Modules

1. **Supplier scorecard:** weighted cost, quality and on-time delivery score; spend Pareto.
2. **Demand forecast and inventory policy:** forecast vs naive baseline (MAPE), ABC, safety stock, reorder point, stockout and dead-stock flags.
3. **Production capacity:** factory utilisation and a PuLP linear program to reallocate volume across 3 plants.
4. **Supplier-disruption scenario:** 30-day outage of the top supplier; revenue at risk and mitigation cost.
5. **Control tower dashboard:** about 8 headline KPIs with drill-downs.

## Stack

Seeded Python data generator → CSV → PostgreSQL → SQL and Python (pandas, statsmodels, PuLP) → BI dashboard

## Repository layout

```
docs/            Charter, KPI definitions, decisions log, data spec
sql/             PostgreSQL schema and KPI queries
src/generator/   Synthetic data generator (Week 2)
src/analysis/    Scorecard, forecasting, LP, scenario (Weeks 2–4)
data/raw/        Generated CSVs (git-ignored; reproducible from the seed)
data/processed/  Analysis outputs for the dashboard (git-ignored)
notebooks/       Exploration and charts
dashboard/       Dashboard workbook (tool to be confirmed)
reports/         Findings report
```

## Documents

- [Project charter and business case](docs/01_project_charter.md)
- [KPI definitions](docs/02_kpi_definitions.md)
- [Decisions for MK](docs/03_decisions_for_mk.md)
- [Data specification](docs/04_data_spec.md)

## Setup (macOS)

1. Install Python 3.11+ and PostgreSQL 16 (for example `brew install python@3.12 postgresql@16`, then `brew services start postgresql@16`).
2. Create the database and schema:
   ```bash
   createdb scm360
   psql -d scm360 -f sql/schema.sql
   ```
3. Create a virtual environment and install packages:
   ```bash
   python3 -m venv .venv && source .venv/bin/activate
   pip install -r requirements.txt
   ```

## Data model

12 tables in the `scm` schema: `factories`, `suppliers`, `materials`, `supplier_materials`, `products`, `bom`, `factory_products`, `customers`, `sales_orders`, `purchase_orders`, `production`, `inventory_snapshots`. See [sql/schema.sql](sql/schema.sql).

---

*All company names and data are synthetic.*
