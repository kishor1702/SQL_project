-- 02_load_data.sql
-- CSV files are produced by etl/prepare_online_retail.py
-- Run from psql. Replace the absolute paths if needed.

\copy categories(category_id,category_name,category_source) FROM 'data/processed/categories.csv' WITH (FORMAT csv, HEADER true);
\copy stores(store_id,store_name,region,country_group,store_type,store_source) FROM 'data/processed/stores.csv' WITH (FORMAT csv, HEADER true);
\copy products(product_id,product_name,category_id,unit_price,active) FROM 'data/processed/products.csv' WITH (FORMAT csv, HEADER true);
\copy customers(customer_id,country,first_order_date,last_order_date) FROM 'data/processed/customers.csv' WITH (FORMAT csv, HEADER true);
\copy orders(order_id,customer_id,store_id,order_date,order_status) FROM 'data/processed/orders.csv' WITH (FORMAT csv, HEADER true);
\copy order_items(order_id,product_id,quantity,unit_price) FROM 'data/processed/order_items.csv' WITH (FORMAT csv, HEADER true);
\copy inventory(store_id,product_id,snapshot_date,opening_stock,units_sold,closing_stock,reorder_level,stock_status) FROM 'data/processed/inventory.csv' WITH (FORMAT csv, HEADER true);

ANALYZE;
