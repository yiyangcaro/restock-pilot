BEGIN;

-- Track applied migrations
CREATE TABLE IF NOT EXISTS schema_migrations (
  version TEXT PRIMARY KEY,
  applied_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Use a dedicated schema
CREATE SCHEMA IF NOT EXISTS rp;

-- ---------- RAW TABLES (ingestion landing zone) ----------
CREATE TABLE IF NOT EXISTS rp.raw_products (
  source TEXT NOT NULL,
  source_product_id TEXT NOT NULL,
  sku TEXT,
  name TEXT,
  payload JSONB NOT NULL,
  ingested_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (source, source_product_id)
);

CREATE TABLE IF NOT EXISTS rp.raw_orders (
  source TEXT NOT NULL,
  source_order_id TEXT NOT NULL,
  order_ts TIMESTAMPTZ,
  payload JSONB NOT NULL,
  ingested_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (source, source_order_id)
);

CREATE TABLE IF NOT EXISTS rp.raw_receipts (
  source TEXT NOT NULL,
  source_receipt_id TEXT NOT NULL,
  receipt_ts TIMESTAMPTZ,
  payload JSONB NOT NULL,
  ingested_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (source, source_receipt_id)
);

-- ---------- CANONICAL TABLES ----------
CREATE TABLE IF NOT EXISTS rp.suppliers (
  supplier_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS rp.locations (
  location_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS rp.products (
  product_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  sku TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  supplier_id BIGINT REFERENCES rp.suppliers(supplier_id),
  active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS rp.sales_orders (
  sales_order_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  order_number TEXT UNIQUE,
  order_ts TIMESTAMPTZ NOT NULL,
  channel TEXT NOT NULL DEFAULT 'unknown',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS rp.sales_order_items (
  sales_order_item_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  sales_order_id BIGINT NOT NULL REFERENCES rp.sales_orders(sales_order_id) ON DELETE CASCADE,
  product_id BIGINT NOT NULL REFERENCES rp.products(product_id),
  location_id BIGINT NOT NULL REFERENCES rp.locations(location_id),
  quantity INTEGER NOT NULL CHECK (quantity > 0),
  unit_price_cents INTEGER NOT NULL CHECK (unit_price_cents >= 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS rp.purchase_orders (
  purchase_order_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  po_number TEXT UNIQUE,
  supplier_id BIGINT NOT NULL REFERENCES rp.suppliers(supplier_id),
  order_ts TIMESTAMPTZ NOT NULL,
  expected_delivery_ts TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS rp.po_receipts (
  po_receipt_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  purchase_order_id BIGINT REFERENCES rp.purchase_orders(purchase_order_id) ON DELETE SET NULL,
  receipt_ts TIMESTAMPTZ NOT NULL,
  location_id BIGINT NOT NULL REFERENCES rp.locations(location_id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Inventory ledger: signed deltas (+ for receipts/returns, - for sales)
CREATE TABLE IF NOT EXISTS rp.inventory_movements (
  movement_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  occurred_at TIMESTAMPTZ NOT NULL,
  product_id BIGINT NOT NULL REFERENCES rp.products(product_id),
  location_id BIGINT NOT NULL REFERENCES rp.locations(location_id),
  movement_type TEXT NOT NULL CHECK (movement_type IN ('SALE','RECEIPT','RETURN','ADJUSTMENT')),
  quantity_delta INTEGER NOT NULL CHECK (quantity_delta <> 0),
  ref_type TEXT,
  ref_id BIGINT,
  note TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK (
    (movement_type = 'SALE' AND quantity_delta < 0) OR
    (movement_type IN ('RECEIPT','RETURN') AND quantity_delta > 0) OR
    (movement_type = 'ADJUSTMENT')
  )
);

-- Helpful indexes
CREATE INDEX IF NOT EXISTS idx_movements_product_time ON rp.inventory_movements (product_id, occurred_at);
CREATE INDEX IF NOT EXISTS idx_movements_location_time ON rp.inventory_movements (location_id, occurred_at);
CREATE INDEX IF NOT EXISTS idx_so_items_product ON rp.sales_order_items (product_id);
CREATE INDEX IF NOT EXISTS idx_so_items_order ON rp.sales_order_items (sales_order_id);

COMMIT;
