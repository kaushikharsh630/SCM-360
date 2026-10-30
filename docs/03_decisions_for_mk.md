# Decisions for MK

Each decision has a recommended default. Reply "go with defaults" to accept all of them, or name the ones you want to change. Data generation in Week 2 depends on D-1, D-2 and D-4, so these are the urgent ones.

| ID | Decision | Recommended default | Status |
|---|---|---|---|
| D-1 | Which problems to plant in the data | P1, P2, P3, P4 (one per module) | Open |
| D-2 | Supplier scorecard weights | Option B: Cost 30 / Quality 35 / Delivery 35 | Open |
| D-3 | On-time delivery grace window | 2 days | Open |
| D-4 | Service level by ABC class | A 98%, B 95%, C 90% | Open |
| D-5 | Disruption scenario settings | Start 1 Jan 2026; alternate +12% price, +7 days lead time, 5% expediting premium | Open |
| D-6 | Max planned utilisation in the LP | 90% | Open |
| D-7 | Dashboard tool | Tableau Public (Mac-friendly, free, shareable link) | Open |

---

## D-1. Planted problems

These are deliberate, explainable issues the generator builds into the data. Each one should be "discovered" by an analysis module, which gives you a concrete story for interviews ("I found that our cheapest supplier was actually costing us ₹X more...").

| ID | Problem | How it shows up in the data | Found by | Recommend |
|---|---|---|---|---|
| **P1** | **Cheapest supplier is the most expensive.** The lowest-price castings supplier (S07) has a 6–8% rejection rate vs about 1.5% for peers. | Lowest PPV but worst quality rate; total cost of ownership is higher once rejections and rework are counted | Module 1 scorecard | ✅ |
| **P2** | **Seasonal stockouts plus dead stock.** Two A-class products peak 40–60% in Oct–Dec (festive season and year-end capex) but safety stock is flat, so they short-ship. Meanwhile one product (P10) is phased out in Sep 2025 and its 2 unique materials keep being bought until Dec. | Short-shipped orders and OTIF dip in Oct–Nov; materials with no movement for 90+ days | Module 2 | ✅ |
| **P3** | **One plant overloaded, one idle.** Chennai runs at 95–100% utilisation with high downtime; Ahmedabad sits at about 55%, though it can make most of the same products. | Utilisation gap; Chennai has lower schedule attainment | Module 3 LP | ✅ |
| **P4** | **Top supplier is slipping and single-sourced.** The top-spend steel supplier (S03, about 22% of spend) is the only source of 2 key materials, and its OTD drops from about 96% to about 72% from Oct 2025. | Spend Pareto concentration plus OTD trend break | Module 1 and Module 4 | ✅ |
| P5 | Quoted lead times are optimistic. One overseas bearing supplier quotes 21 days but averages 30. | Gap between `quoted_lead_time_days` and actual | Module 1 | Optional |
| P6 | Data-quality traps. About 1% of rows have missing receipt dates, duplicate PO lines, or negative quantities in the raw CSV. | Caught by Week 2 validation before load | Data checks | Optional |

**Recommendation:** P1–P4. One problem per module keeps the story clean. P6 is cheap to add and shows data-cleaning skills, so add it if you want a "data quality" bullet on the resume.

## D-2. Supplier scorecard weights

| Option | Cost | Quality | Delivery | When it fits |
|---|---|---|---|---|
| A. Cost-led | 40% | 30% | 30% | Commodity buying, price-driven market |
| **B. Balanced (recommended)** | **30%** | **35%** | **35%** | Manufacturer where a rejected lot or late delivery stops a line, which costs more than a few % on price |
| C. Quality-led | 25% | 40% | 35% | Safety-critical parts, aerospace or automotive tier-1 |

Why B: ABC World sells to OEMs on delivery schedules, so delivery and quality failures hurt more than price. It is also the weighting that makes P1 visible: under A, the cheap supplier may still look acceptable, which is itself a nice interview point (we'll show the ranking under all three in a sensitivity table).

## D-3. OTD grace window

- 0 days: strict, typical for automotive JIT.
- **2 days (recommended):** common in Indian industrial supply, where receiving and GRN posting lag a day or two.

## D-4. Service level by ABC class

| Class | Recommended | z |
|---|---|---|
| A | 98% | 2.05 |
| B | 95% | 1.65 |
| C | 90% | 1.28 |

Alternative: a flat 95% for everything (simpler, but loses the "differentiated policy" talking point).

## D-5. Disruption scenario settings

- Supplier hit: the top-spend supplier (expected to be S03 if P4 is planted).
- Outage: 30 days, starting 1 Jan 2026.
- Alternate supplier: +12% price, lead time +7 days over the primary.
- Expediting premium: 5% on emergency orders.

## D-6. Max planned utilisation in the LP

**90% recommended.** It leaves room for breakdowns and changeovers. 85% is more conservative; 100% is unrealistic.

## D-7. Dashboard tool

Power BI Desktop does not run on macOS. Options:

| Tool | Pros | Cons |
|---|---|---|
| **Tableau Public (recommended)** | Free, native Mac app, publishes to a public link you can put on your resume | Public only; connects to CSV/Excel (not PostgreSQL) in the free version |
| Power BI via a Windows VM or cloud PC | Power BI is the most-asked tool in Indian SCM job posts | Needs Parallels or a Windows machine; extra setup |
| Power BI Service (web) | Browser-based | Needs a work or school account; limited modelling |
| Looker Studio | Free, browser, Google Sheets/CSV | Less common in SCM job posts |

Whichever tool you pick, the KPI formulas in `02_kpi_definitions.md` stay the same, and Week 4 will export clean KPI tables to CSV so the tool choice does not block anything.
