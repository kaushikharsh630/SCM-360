# Data Specification (input to the Week 2 generator)

The generator (`src/generator/`) is seeded (`SEED = 42`) so every run produces identical CSVs. Targets below make the synthetic numbers consistent with the business case (≈ ₹150 crore revenue, ≈ ₹70 crore material spend).

## Master data

| Table | Rows | Notes |
|---|---|---|
| factories | 3 | F01 Pune, F02 Chennai, F03 Ahmedabad |
| suppliers | 15 | 6 categories: Steel, Castings, Bearings, Seals & Gaskets, Fasteners, Paint & Packaging; 1 overseas |
| materials | 20 | Standard cost ₹15/kg (fasteners) to ₹4,500/pc (bearings) |
| supplier_materials | ≈ 30 | Most materials dual-sourced; 2 single-sourced (P4) |
| products | 10 | 4 families: Gear Assemblies, Hydraulic Valves, Pump Housings, Couplings & Mounts; price ₹2,500 to ₹65,000 |
| bom | ≈ 50 | 3–7 materials per product |
| factory_products | ≈ 22 | Each product makeable in 2–3 plants, with different hours and cost |
| customers | ≈ 60 | Segments: OEM 50%, Distributor 35%, EPC 15% of revenue |

## Transactions (FY 2025-26)

| Table | Approx. rows | Generation logic |
|---|---|---|
| sales_orders | ≈ 9,000 | Monthly demand = base × trend × seasonality × noise; Oct–Dec peak; order sizes lognormal |
| purchase_orders | ≈ 3,500 | Triggered by material consumption with a simple reorder rule; delivery delay and rejection drawn per supplier profile |
| production | ≈ 8,000 | Daily per factory–product, driven by orders; machine hours = actual_qty × hours_per_unit + noise |
| inventory_snapshots | ≈ 1,100 | Month-end per factory and item (materials + products) |

## Planted problems

Implemented according to MK's decision D-1 in `03_decisions_for_mk.md`.

## Validation checks (Week 2)

- Row counts and primary-key uniqueness.
- Foreign keys resolve (enforced by the schema on load).
- Annual revenue and material spend within ±10% of targets.
- Material balance: opening + received − consumed ≈ closing inventory (within 2%).
- Each planted problem is visible with a simple query.
