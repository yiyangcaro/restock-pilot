CREATE TABLE IF NOT EXISTS products (
  product_id SERIAL PRIMARY KEY,
  sku TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS orders (
  order_id SERIAL PRIMARY KEY,
  order_date DATE NOT NULL
);

CREATE TABLE IF NOT EXISTS order_items (
  order_item_id SERIAL PRIMARY KEY,
  order_id INT NOT NULL REFERENCES orders(order_id),
  product_id INT NOT NULL REFERENCES products(product_id),
  qty INT NOT NULL CHECK (qty > 0)
);

CREATE TABLE IF NOT EXISTS inventory_movements (
  movement_id SERIAL PRIMARY KEY,
  movement_ts TIMESTAMP NOT NULL DEFAULT NOW(),
  product_id INT NOT NULL REFERENCES products(product_id),
  qty_delta INT NOT NULL,
  reason TEXT NOT NULL
);
