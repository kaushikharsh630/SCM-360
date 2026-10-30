-- =====================================================================
-- SCM 360° — ABC World Pvt Ltd
-- PostgreSQL schema (tested on PostgreSQL 16)
--
-- Run:   psql -U postgres -d scm360 -f sql/schema.sql
-- The script drops and recreates the "scm" schema, so it is safe to re-run.
--
-- Data window: FY 2025-26 (1 Apr 2025 – 31 Mar 2026). All money in INR.
-- =====================================================================

SET client_min_messages = warning;
DROP SCHEMA IF EXISTS scm CASCADE;
CREATE SCHEMA scm;
SET search_path TO scm;

-- ---------------------------------------------------------------------
-- Master data
-- ---------------------------------------------------------------------

CREATE TABLE factories (
    factory_id              VARCHAR(5)    PRIMARY KEY,          -- F01..F03
    factory_name            VARCHAR(60)   NOT NULL,
    city                    VARCHAR(40)   NOT NULL,
    state                   VARCHAR(40)   NOT NULL,
    monthly_capacity_hours  NUMERIC(10,1) NOT NULL CHECK (monthly_capacity_hours > 0),
    cost_per_machine_hour   NUMERIC(10,2) NOT NULL CHECK (cost_per_machine_hour >= 0)
);

CREATE TABLE suppliers (
    supplier_id             VARCHAR(5)    PRIMARY KEY,          -- S01..S15
    supplier_name           VARCHAR(80)   NOT NULL,
    city                    VARCHAR(40)   NOT NULL,
    state                   VARCHAR(40)   NOT NULL,
    country                 VARCHAR(40)   NOT NULL DEFAULT 'India',
    supply_category         VARCHAR(40)   NOT NULL,             -- Steel, Castings, Bearings, ...
    quoted_lead_time_days   INTEGER       NOT NULL CHECK (quoted_lead_time_days > 0),
    payment_terms_days      INTEGER       NOT NULL CHECK (payment_terms_days >= 0)
);

CREATE TABLE materials (
    material_id             VARCHAR(5)    PRIMARY KEY,          -- M01..M20
    material_name           VARCHAR(80)   NOT NULL,
    material_category       VARCHAR(40)   NOT NULL,
    uom                     VARCHAR(10)   NOT NULL,             -- kg, pcs, litre
    standard_cost_inr       NUMERIC(12,2) NOT NULL CHECK (standard_cost_inr > 0)
);

-- Which suppliers can supply which material (needed for the disruption scenario:
-- who are the alternates when the primary supplier goes down?)
CREATE TABLE supplier_materials (
    supplier_id             VARCHAR(5)    NOT NULL REFERENCES suppliers(supplier_id),
    material_id             VARCHAR(5)    NOT NULL REFERENCES materials(material_id),
    contract_price_inr      NUMERIC(12,2) NOT NULL CHECK (contract_price_inr > 0),
    is_primary              BOOLEAN       NOT NULL DEFAULT FALSE,
    PRIMARY KEY (supplier_id, material_id)
);
-- At most one primary supplier per material
CREATE UNIQUE INDEX ux_supplier_materials_one_primary
    ON supplier_materials(material_id) WHERE is_primary;

CREATE TABLE products (
    product_id              VARCHAR(5)    PRIMARY KEY,          -- P01..P10
    product_name            VARCHAR(80)   NOT NULL,
    product_family          VARCHAR(40)   NOT NULL,
    unit_price_inr          NUMERIC(12,2) NOT NULL CHECK (unit_price_inr > 0),
    is_active               BOOLEAN       NOT NULL DEFAULT TRUE
);

-- Bill of materials: quantity of each material needed per finished unit
CREATE TABLE bom (
    product_id              VARCHAR(5)    NOT NULL REFERENCES products(product_id),
    material_id             VARCHAR(5)    NOT NULL REFERENCES materials(material_id),
    qty_per_unit            NUMERIC(10,3) NOT NULL CHECK (qty_per_unit > 0),
    PRIMARY KEY (product_id, material_id)
);

-- Which factory can make which product, how many machine hours a unit takes there,
-- and the variable conversion cost. This is the input for the capacity LP.
CREATE TABLE factory_products (
    factory_id              VARCHAR(5)    NOT NULL REFERENCES factories(factory_id),
    product_id              VARCHAR(5)    NOT NULL REFERENCES products(product_id),
    hours_per_unit          NUMERIC(8,3)  NOT NULL CHECK (hours_per_unit > 0),
    variable_cost_per_unit_inr NUMERIC(12,2) NOT NULL CHECK (variable_cost_per_unit_inr >= 0),
    PRIMARY KEY (factory_id, product_id)
);

CREATE TABLE customers (
    customer_id             VARCHAR(6)    PRIMARY KEY,          -- C001..
    customer_name           VARCHAR(80)   NOT NULL,
    segment                 VARCHAR(30)   NOT NULL,             -- OEM, Distributor, EPC
    city                    VARCHAR(40)   NOT NULL,
    state                   VARCHAR(40)   NOT NULL,
    region                  VARCHAR(10)   NOT NULL CHECK (region IN ('North','South','East','West'))
);

-- ---------------------------------------------------------------------
-- Transactions
-- ---------------------------------------------------------------------

-- Customer orders (one product per order line)
CREATE TABLE sales_orders (
    order_id                VARCHAR(10)   PRIMARY KEY,          -- SO000001..
    order_date              DATE          NOT NULL,
    customer_id             VARCHAR(6)    NOT NULL REFERENCES customers(customer_id),
    product_id              VARCHAR(5)    NOT NULL REFERENCES products(product_id),
    factory_id              VARCHAR(5)    NOT NULL REFERENCES factories(factory_id),  -- shipping plant
    quantity_ordered        INTEGER       NOT NULL CHECK (quantity_ordered > 0),
    quantity_shipped        INTEGER       NOT NULL DEFAULT 0 CHECK (quantity_shipped >= 0),
    unit_price_inr          NUMERIC(12,2) NOT NULL CHECK (unit_price_inr > 0),
    requested_date          DATE          NOT NULL,
    shipped_date            DATE,
    status                  VARCHAR(12)   NOT NULL
                            CHECK (status IN ('Open','Shipped','Partial','Cancelled')),
    CHECK (quantity_shipped <= quantity_ordered),
    CHECK (requested_date >= order_date),
    CHECK (shipped_date IS NULL OR shipped_date >= order_date)
);

-- Purchase orders to suppliers (one material per PO line)
CREATE TABLE purchase_orders (
    po_id                   VARCHAR(10)   PRIMARY KEY,          -- PO000001..
    po_date                 DATE          NOT NULL,
    supplier_id             VARCHAR(5)    NOT NULL REFERENCES suppliers(supplier_id),
    material_id             VARCHAR(5)    NOT NULL REFERENCES materials(material_id),
    factory_id              VARCHAR(5)    NOT NULL REFERENCES factories(factory_id),  -- receiving plant
    quantity_ordered        NUMERIC(12,2) NOT NULL CHECK (quantity_ordered > 0),
    unit_price_inr          NUMERIC(12,2) NOT NULL CHECK (unit_price_inr > 0),
    promised_date           DATE          NOT NULL,
    received_date           DATE,
    quantity_received       NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (quantity_received >= 0),
    quantity_rejected       NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (quantity_rejected >= 0),
    status                  VARCHAR(12)   NOT NULL
                            CHECK (status IN ('Open','Received','Partial','Cancelled')),
    CHECK (quantity_rejected <= quantity_received),
    CHECK (promised_date >= po_date),
    CHECK (received_date IS NULL OR received_date >= po_date)
);

-- Daily production per factory and product
CREATE TABLE production (
    production_date         DATE          NOT NULL,
    factory_id              VARCHAR(5)    NOT NULL,
    product_id              VARCHAR(5)    NOT NULL,
    planned_qty             INTEGER       NOT NULL CHECK (planned_qty >= 0),
    actual_qty              INTEGER       NOT NULL CHECK (actual_qty >= 0),
    machine_hours_used      NUMERIC(8,2)  NOT NULL CHECK (machine_hours_used >= 0),
    downtime_hours          NUMERIC(6,2)  NOT NULL DEFAULT 0 CHECK (downtime_hours >= 0),
    PRIMARY KEY (production_date, factory_id, product_id),
    FOREIGN KEY (factory_id, product_id) REFERENCES factory_products(factory_id, product_id)
);

-- Month-end (or weekly) stock position for materials and finished goods.
-- Exactly one of material_id / product_id is filled, matching item_type.
CREATE TABLE inventory_snapshots (
    snapshot_id             BIGSERIAL     PRIMARY KEY,
    snapshot_date           DATE          NOT NULL,
    factory_id              VARCHAR(5)    NOT NULL REFERENCES factories(factory_id),
    item_type               VARCHAR(8)    NOT NULL CHECK (item_type IN ('MATERIAL','PRODUCT')),
    material_id             VARCHAR(5)    REFERENCES materials(material_id),
    product_id              VARCHAR(5)    REFERENCES products(product_id),
    on_hand_qty             NUMERIC(12,2) NOT NULL CHECK (on_hand_qty >= 0),
    unit_cost_inr           NUMERIC(12,2) NOT NULL CHECK (unit_cost_inr >= 0),
    last_movement_date      DATE,                               -- for dead-stock ageing
    CHECK (
        (item_type = 'MATERIAL' AND material_id IS NOT NULL AND product_id IS NULL) OR
        (item_type = 'PRODUCT'  AND product_id  IS NOT NULL AND material_id IS NULL)
    )
);
CREATE UNIQUE INDEX ux_inventory_material
    ON inventory_snapshots(snapshot_date, factory_id, material_id) WHERE item_type = 'MATERIAL';
CREATE UNIQUE INDEX ux_inventory_product
    ON inventory_snapshots(snapshot_date, factory_id, product_id)  WHERE item_type = 'PRODUCT';

-- ---------------------------------------------------------------------
-- Indexes for the joins and date filters the analysis uses most
-- ---------------------------------------------------------------------
CREATE INDEX ix_so_date      ON sales_orders(order_date);
CREATE INDEX ix_so_product   ON sales_orders(product_id);
CREATE INDEX ix_po_date      ON purchase_orders(po_date);
CREATE INDEX ix_po_supplier  ON purchase_orders(supplier_id);
CREATE INDEX ix_po_material  ON purchase_orders(material_id);
CREATE INDEX ix_prod_factory ON production(factory_id, production_date);
