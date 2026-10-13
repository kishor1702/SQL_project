-- 01_schema.sql
DROP TABLE IF EXISTS inventory CASCADE;
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS stores CASCADE;

CREATE TABLE categories (
    category_id INTEGER PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL UNIQUE,
    category_source VARCHAR(30) NOT NULL DEFAULT 'derived'
);

CREATE TABLE stores (
    store_id INTEGER PRIMARY KEY,
    store_name VARCHAR(120) NOT NULL,
    region VARCHAR(80) NOT NULL,
    country_group VARCHAR(120) NOT NULL,
    store_type VARCHAR(40) NOT NULL DEFAULT 'virtual_region',
    store_source VARCHAR(30) NOT NULL DEFAULT 'derived'
);

CREATE TABLE products (
    product_id VARCHAR(20) PRIMARY KEY,
    product_name TEXT NOT NULL,
    category_id INTEGER NOT NULL REFERENCES categories(category_id),
    unit_price NUMERIC(12,2),
    active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE customers (
    customer_id INTEGER PRIMARY KEY,
    country VARCHAR(100),
    first_order_date DATE,
    last_order_date DATE
);

CREATE TABLE orders (
    order_id VARCHAR(20) PRIMARY KEY,
    customer_id INTEGER REFERENCES customers(customer_id),
    store_id INTEGER NOT NULL REFERENCES stores(store_id),
    order_date TIMESTAMP NOT NULL,
    order_status VARCHAR(20) NOT NULL DEFAULT 'Completed'
);

CREATE TABLE order_items (
    order_item_id BIGSERIAL PRIMARY KEY,
    order_id VARCHAR(20) NOT NULL REFERENCES orders(order_id),
    product_id VARCHAR(20) NOT NULL REFERENCES products(product_id),
    quantity INTEGER NOT NULL,
    unit_price NUMERIC(12,2) NOT NULL,
    line_amount NUMERIC(14,2) GENERATED ALWAYS AS (quantity * unit_price) STORED
);

CREATE TABLE inventory (
    inventory_id BIGSERIAL PRIMARY KEY,
    store_id INTEGER NOT NULL REFERENCES stores(store_id),
    product_id VARCHAR(20) NOT NULL REFERENCES products(product_id),
    snapshot_date DATE NOT NULL,
    opening_stock INTEGER NOT NULL,
    units_sold INTEGER NOT NULL,
    closing_stock INTEGER NOT NULL,
    reorder_level INTEGER NOT NULL,
    stock_status VARCHAR(20) NOT NULL,
    UNIQUE(store_id, product_id, snapshot_date)
);

CREATE INDEX idx_orders_date ON orders(order_date);
CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE INDEX idx_orders_store ON orders(store_id);
CREATE INDEX idx_order_items_product ON order_items(product_id);
CREATE INDEX idx_inventory_status ON inventory(stock_status);
CREATE INDEX idx_products_category ON products(category_id);

CREATE OR REPLACE VIEW vw_sales AS
SELECT
    o.order_id,
    o.customer_id,
    o.store_id,
    o.order_date,
    oi.product_id,
    oi.quantity,
    oi.unit_price,
    oi.line_amount,
    p.category_id
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON p.product_id = oi.product_id
WHERE o.order_status = 'Completed';
