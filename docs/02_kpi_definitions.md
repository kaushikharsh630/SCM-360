# KPI Definitions

Every KPI below has one owner formula. SQL, Python and the BI dashboard must all implement exactly this formula so the numbers match everywhere. Table and column names refer to `sql/schema.sql`.

Conventions:
- Period = calendar month unless stated. FY 2025-26 = 1 Apr 2025 to 31 Mar 2026.
- Money in ₹. Percentages stored as fractions (0.953) and shown as 95.3%.
- Cancelled orders and POs are excluded from every KPI unless stated.
- `[D-n]` marks a parameter MK decides in `03_decisions_for_mk.md`.

---

## A. Control tower headline KPIs (dashboard cards)

| # | KPI | Formula | Target / good direction |
|---|---|---|---|
| 1 | Customer OTIF % | Order lines shipped in full **and** with `shipped_date ≤ requested_date` ÷ order lines due in period | ≥ 95% ↑ |
| 2 | Fill rate % | Σ `quantity_shipped` ÷ Σ `quantity_ordered` (orders due in period) | ≥ 97% ↑ |
| 3 | Forecast MAPE % | See B5 | ≤ 20% ↓ |
| 4 | Inventory days on hand (DOH) | Closing inventory value ÷ (COGS for the period ÷ days in period) | 30–45 days |
| 5 | Dead-stock value ₹ | Σ `on_hand_qty × unit_cost_inr` where days since `last_movement_date` ≥ 90 | ↓ |
| 6 | Capacity utilisation % | See C1 | 75–85% |
| 7 | Supplier OTD % | See D1 | ≥ 95% ↑ |
| 8 | Supplier quality rate % | See D2 | ≥ 98.5% ↑ |

Revenue at risk (E2) is shown on the scenario page rather than as a headline card.

---

## B. Demand and inventory (Module 2)

**B1. Monthly demand per product**
`demand(p, m) = Σ quantity_ordered` for orders of product *p* with `order_date` in month *m*. We forecast ordered quantity, not shipped quantity, so stockouts do not hide true demand.

**B2. ABC classification (by annual revenue)**
1. Annual revenue per product = Σ `quantity_ordered × unit_price_inr`.
2. Sort descending, compute cumulative share of total.
3. Class **A** while cumulative share ≤ 80%, **B** up to 95%, **C** the rest. The item that crosses a boundary goes into the higher class.
The same method is applied to materials using annual purchase spend.

**B3. Naive baseline forecast**
`naive(p, m) = demand(p, m − 1)` (last month's actual). A seasonal naive (`demand(p, m − 12)`) is not possible with 12 months of data.

**B4. Model forecast**
Holt-Winters / exponential smoothing (statsmodels), trained on months 1–9, tested on months 10–12 (Jan–Mar 2026). Model choice is finalised in Week 3.

**B5. Forecast error metrics** (on the test months only)
- `MAPE = (1/n) Σ |actual − forecast| ÷ actual` (months with actual = 0 excluded)
- `WAPE = Σ |actual − forecast| ÷ Σ actual` (used for portfolio-level roll-up because it weights by volume)
- `Bias = Σ (forecast − actual) ÷ Σ actual` (positive = over-forecasting)
- `Forecast value added (FVA) = MAPE_naive − MAPE_model` (positive = the model earns its keep)

**B6. Safety stock** (demand and lead time both vary)

```
SS = z × √( LT × σ_d²  +  d̄² × σ_LT² )
```

| Symbol | Meaning | Source |
|---|---|---|
| z | Service-level factor: 90% → 1.28, 95% → 1.65, 98% → 2.05 | `[D-4]` service level by ABC class |
| d̄, σ_d | Mean and std dev of **daily** demand | materials: consumption = Σ production `actual_qty × bom.qty_per_unit`; products: sales orders |
| LT, σ_LT | Mean and std dev of actual lead time in days | `received_date − po_date` from purchase_orders |

For finished goods, LT = average production lead time (fixed parameter, 7 days) and σ_LT = 0.

**B7. Reorder point**
`ROP = d̄ × LT + SS`

**B8. Stockout flag**
An item-month is flagged when closing `on_hand_qty` < SS, or any order line for the product is short-shipped (`quantity_shipped < quantity_ordered`). Stockout days = days in the month where projected on-hand < 0 (from the daily simulation in Week 3).

**B9. Dead-stock flag**
`days_since_movement = snapshot_date − last_movement_date`. Flag as **slow** at 60–89 days, **dead** at ≥ 90 days.

**B10. Inventory turns**
`Turns = annual COGS ÷ average monthly inventory value`. DOH (A4) = 365 ÷ Turns on an annual basis.

---

## C. Production (Module 3)

**C1. Capacity utilisation %**
`Utilisation(f, m) = Σ machine_hours_used ÷ factories.monthly_capacity_hours`

**C2. Schedule attainment %**
`Σ actual_qty ÷ Σ planned_qty`

**C3. Downtime %**
`Σ downtime_hours ÷ (Σ machine_hours_used + Σ downtime_hours)`

**C4. Reallocation LP (PuLP)**
- Decision variable: `x[f, p]` = units of product *p* made at factory *f* in the month.
- Objective: minimise Σ `x[f, p] × variable_cost_per_unit_inr[f, p]`.
- Constraints:
  - Demand: Σ_f `x[f, p]` ≥ forecast demand for *p*.
  - Capacity: Σ_p `x[f, p] × hours_per_unit[f, p]` ≤ `monthly_capacity_hours[f] × max_utilisation` (max_utilisation = 0.90 `[D-6]`).
  - Only factory–product pairs present in `factory_products`.
  - `x[f, p] ≥ 0`.
- Output: plan vs actual, ₹ saving, utilisation before and after.

---

## D. Supplier performance (Module 1)

All supplier KPIs use received PO lines (`received_date` not null) in the period.

**D1. On-time delivery (OTD) %**
`OTD = PO lines with received_date ≤ promised_date + grace_days ÷ PO lines received`
grace_days = `[D-3]`.

**D2. Quality rate % and PPM**
`Quality rate = 1 − Σ quantity_rejected ÷ Σ quantity_received`
`PPM rejected = Σ quantity_rejected ÷ Σ quantity_received × 1,000,000`

**D3. Purchase price variance (PPV) %**
`PPV = Σ (unit_price_inr − standard_cost_inr) × quantity_received ÷ Σ standard_cost_inr × quantity_received`
Positive = paying above standard.

**D4. Lead-time adherence**
`Average delay days = mean(received_date − promised_date)` and lead-time std dev (feeds σ_LT in B6).

**D5. Composite supplier score (0–100)**
1. For each supplier compute the three raw metrics: cost = PPV (lower is better), quality = quality rate, delivery = OTD.
2. Normalise each across the 15 suppliers with min-max to 0–100, so the best supplier scores 100 and the worst 0:
   - Higher-is-better: `score = 100 × (x − min) ÷ (max − min)`
   - Lower-is-better (PPV): `score = 100 × (max − x) ÷ (max − min)`
3. `Composite = w_cost × cost_score + w_quality × quality_score + w_delivery × delivery_score` with weights from `[D-2]`.
4. Tier: **Preferred** ≥ 75, **Approved** 50–74.9, **Watch-list** < 50.

**D6. Spend Pareto**
Annual spend per supplier = Σ `unit_price_inr × quantity_received`. Sort descending; show cumulative %. Report **top-3 supplier share** and the number of suppliers making up 80% of spend.

**D7. Single-source flag**
A material is single-sourced when it has only one row in `supplier_materials`, or one supplier carries > 90% of its annual spend.

---

## E. Disruption scenario (Module 4)

**E1. Exposure**
Supplier *s* stops shipping for 30 days from the scenario start date `[D-5]`. For each material it supplies: days of cover = current on-hand ÷ d̄. If cover < 30 days and no alternate supplier can deliver inside the gap, the shortfall flows through the BOM to the products that use it.

**E2. Revenue at risk ₹**
`Σ_p lost_units(p) × unit_price_inr(p)`, where `lost_units` = units of product *p* that cannot be built during the outage because of the material shortfall.

**E3. Mitigation cost ₹**
Extra cost of buying from the alternate supplier (`contract_price` difference × quantity) plus expediting premium `[D-5]`. Compared against E2 to recommend action.
