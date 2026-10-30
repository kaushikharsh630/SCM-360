# Project Charter and Business Case: SCM 360°

**Company:** ABC World Pvt Ltd (fictional)
**Prepared by:** MK (Supply Chain Analyst)
**Status:** Draft v0.1, Week 1
**Data window:** FY 2025-26 (1 Apr 2025 to 31 Mar 2026)

---

## 1. Company background

ABC World Pvt Ltd is a mid-sized Indian manufacturer of industrial components (gear assemblies, hydraulic valves, pump housings, couplings and motor mounts) sold to OEMs, distributors and EPC contractors across India.

| Fact | Value |
|---|---|
| Annual revenue (target for synthetic data) | ≈ ₹150 crore |
| Direct material spend | ≈ ₹70 crore (about 47% of revenue) |
| Factories | 3: Pune (Maharashtra), Chennai (Tamil Nadu), Ahmedabad (Gujarat) |
| Suppliers | 15 active, across 6 categories |
| Finished products | 10 SKUs in 4 product families |
| Raw materials and bought-out parts | 20 |
| Customers | about 60 across 3 segments and 4 regions |

## 2. Problem statement

ABC World's supply chain data sits in separate spreadsheets for purchasing, planning, production and sales. Leadership has no single view of how the supply chain is performing, so problems surface late and as firefights:

- Purchasing picks suppliers mainly on unit price, with no structured view of quality or delivery.
- Inventory is planned on gut feel. Some items stock out during peak months while others sit unused for months.
- Some plants run overtime while others have idle capacity, and there is no method to rebalance the load.
- Nobody has quantified what happens if a major supplier stops delivering.

## 3. Objectives

1. **Supplier scorecard.** Rank all 15 suppliers on a weighted cost, quality and on-time delivery score, and show where spend is concentrated (Pareto).
2. **Demand forecast and inventory policy.** Forecast monthly demand per product, prove it beats a naive baseline (MAPE), classify items ABC, and set safety stock and reorder points. Flag stockout risk and dead stock.
3. **Production capacity optimisation.** Measure utilisation per factory, and use a linear program (PuLP) to reallocate production across the 3 factories at minimum cost within capacity.
4. **Disruption scenario.** Model a 30-day outage of the highest-spend supplier: which materials, products and customers are hit, how much revenue is at risk, and what the mitigation costs.
5. **Control tower.** A BI dashboard (tool to be confirmed; MK is on a Mac, so likely Tableau Public) with about 8 headline KPIs and drill-downs for leadership.

## 4. Scope

**In scope**
- Seeded synthetic data for 12 months covering the tables in `sql/schema.sql`.
- PostgreSQL as the single source of truth; SQL for KPI queries.
- Python (pandas, statsmodels, PuLP) for forecasting, inventory policy, optimisation and the scenario.
- BI dashboard on top of PostgreSQL (or exported CSVs).
- A short findings report with recommendations and estimated ₹ impact.

**Out of scope**
- Real company data, ERP integration, live refresh.
- Transportation and warehouse network design.
- Multi-echelon inventory, lot sizing and detailed shop-floor scheduling.
- Finance-grade costing (we use standard costs).

## 5. Business case (hypotheses to prove or disprove with the data)

The numbers below are the size of prize we expect to find. Week 4 replaces them with the actual figures from the analysis.

| Lever | Hypothesis | Estimated annual value |
|---|---|---|
| Supplier rebalancing | Moving volume away from a low-price, high-rejection supplier lowers total cost of ownership | 1–2% of material spend ≈ ₹0.7–1.4 crore |
| Inventory policy | Statistical safety stock cuts excess and dead stock while lifting fill rate | 10–15% lower inventory value; fill rate +3–5 pts |
| Capacity reallocation | Shifting volume from the overloaded plant cuts overtime and conversion cost | 5–8% of conversion cost at the overloaded plant |
| Disruption readiness | Qualifying an alternate source for single-sourced materials protects revenue | Avoids ₹X crore revenue at risk per 30-day outage (computed in Module 4) |

## 6. Deliverables

| # | Deliverable | Week |
|---|---|---|
| D1 | Charter, KPI definitions, data model and schema (this PR) | 1 |
| D2 | Synthetic data generator, CSVs, data loaded in PostgreSQL, data-quality checks | 2 |
| D3 | Supplier scorecard and spend Pareto (SQL plus Python) | 2 |
| D4 | Forecast vs naive, ABC, safety stock, ROP, stockout and dead-stock flags | 3 |
| D5 | Utilisation analysis and PuLP reallocation model | 3 |
| D6 | 30-day supplier-disruption scenario | 4 |
| D7 | BI control tower dashboard | 4 |
| D8 | Findings report, README and resume bullets | 4 |

## 7. Timeline

| Week | Focus | Exit criteria |
|---|---|---|
| 1 | Business case and data foundation | Charter, KPIs, schema merged; MK decisions made; PostgreSQL and the BI tool installed |
| 2 | Data and supplier analytics | Data loaded and validated; scorecard finished |
| 3 | Planning analytics | Forecast, inventory policy and capacity LP finished |
| 4 | Scenario, dashboard, storytelling | Scenario, dashboard and findings report finished |

## 8. Roles

| Who | Responsibilities |
|---|---|
| MK | Business decisions (weights, policies, planted problems), sanity checks in Excel, PostgreSQL and BI tool setup, the dashboard, findings narrative, interview preparation |
| Claude | Documentation drafts, data generator, SQL, Python models, code review support |

## 9. Assumptions

- Lead time and demand are stable enough within the year for a single safety-stock formula per item.
- Standard costs stay fixed for the year; price variance is measured against them.
- Each sales order line ships from one factory; each purchase order line is for one material.
- Indian fiscal year (April to March) and Indian festive-season demand peak (October to December).

## 10. Risks

| Risk | Mitigation |
|---|---|
| Synthetic data looks too clean or too random to be credible | Plant specific, explainable problems; add realistic noise and seasonality; MK checks distributions in Excel |
| Scope creep beyond 4 weeks | Scope fixed to 4 modules plus dashboard; extras go to a "future work" list |
| Tool setup delays (PostgreSQL, BI tool) | MK installs in Week 1; CSVs work as a fallback source for the dashboard |
