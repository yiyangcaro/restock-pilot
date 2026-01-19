CREATE TABLE IF NOT EXISTS receipts (
  receipt_id SERIAL PRIMARY KEY,
  receipt_date DATE NOT NULL,
  vendor TEXT,
  note TEXT
);

CREATE TABLE IF NOT EXISTS receipt_items (
  receipt_item_id SERIAL PRIMARY KEY,
  receipt_id INT NOT NULL REFERENCES receipts(receipt_id),
  product_id INT NOT NULL REFERENCES products(product_id),
  qty INT NOT NULL CHECK (qty > 0),
  unit_cost NUMERIC(10,2)
);

CREATE TABLE IF NOT EXISTS returns (
  return_id SERIAL PRIMARY KEY,
  return_date DATE NOT NULL,
  order_id INT REFERENCES orders(order_id),
  note TEXT 
);

CREATE TABLE IF NOT EXISTS return_items (
  return_item_id SERIAL PRIMARY KEY,
  return_id INT NOT NULL REFERENCES returns(return_id),
  product_id INT NOT NULL REFERENCES products(product_id),
  qty INT NOT NULL CHECK (qty > 0)
);