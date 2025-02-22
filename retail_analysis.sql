-- Create database
CREATE DATABASE retail_analysis;

-- Connect to database
\c retail_analysis

-- Create categories table
CREATE TABLE categories (
    category_id SERIAL PRIMARY KEY,
    category_name VARCHAR(50) NOT NULL,
    department VARCHAR(50) NOT NULL
);

-- Create products table
CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    category_id INTEGER REFERENCES categories(category_id),
    unit_price DECIMAL(10,2) NOT NULL,
    supplier VARCHAR(100),
    stock_quantity INTEGER DEFAULT 0
);

-- Create stores table
CREATE TABLE stores (
    store_id SERIAL PRIMARY KEY,
    store_name VARCHAR(100) NOT NULL,
    city VARCHAR(50) NOT NULL,
    state VARCHAR(2) NOT NULL,
    region VARCHAR(20) NOT NULL
);

-- Create customers table
CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE,
    join_date DATE NOT NULL
);

-- Create sales table
CREATE TABLE sales (
    sale_id SERIAL PRIMARY KEY,
    store_id INTEGER REFERENCES stores(store_id),
    product_id INTEGER REFERENCES products(product_id),
    customer_id INTEGER REFERENCES customers(customer_id),
    sale_date DATE NOT NULL,
    quantity INTEGER NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL
);

-- Insert sample data into categories
INSERT INTO categories (category_name, department) VALUES
('Laptops', 'Electronics'),
('Smartphones', 'Electronics'),
('Tablets', 'Electronics'),
('Desktops', 'Electronics'),
('TV & Home Theater', 'Electronics'),
('Cameras', 'Electronics'),
('Wearables', 'Electronics'),
('Gaming', 'Electronics'),
('Home Appliances', 'Appliances'),
('Kitchen Appliances', 'Appliances');

-- Insert sample data into products
INSERT INTO products (product_name, category_id, unit_price, supplier, stock_quantity)
SELECT 
    'Product ' || generate_series(1, 100),
    ceiling(random() * 10)::int,
    (random() * 900 + 100)::decimal(10,2),
    'Supplier ' || ceiling(random() * 5)::int,
    ceiling(random() * 100)::int
FROM generate_series(1, 100);

-- Insert sample data into stores
INSERT INTO stores (store_name, city, state, region) VALUES
('Store Alpha', 'New York', 'NY', 'Northeast'),
('Store Beta', 'Los Angeles', 'CA', 'West'),
('Store Gamma', 'Chicago', 'IL', 'Midwest'),
('Store Delta', 'Houston', 'TX', 'South'),
('Store Epsilon', 'Phoenix', 'AZ', 'West'),
('Store Zeta', 'Philadelphia', 'PA', 'Northeast'),
('Store Eta', 'San Antonio', 'TX', 'South'),
('Store Theta', 'San Diego', 'CA', 'West'),
('Store Iota', 'Dallas', 'TX', 'South'),
('Store Kappa', 'Miami', 'FL', 'South');

-- Insert sample data into customers
INSERT INTO customers (first_name, last_name, email, join_date)
SELECT 
    'FirstName' || generate_series(1, 200),
    'LastName' || generate_series(1, 200),
    'customer' || generate_series(1, 200) || '@email.com',
    date '2023-01-01' + (random() * 365)::integer
FROM generate_series(1, 200);

-- Insert sample sales data (500 records)
INSERT INTO sales (store_id, product_id, customer_id, sale_date, quantity, unit_price, total_amount)
SELECT 
    ceiling(random() * 10)::int,
    ceiling(random() * 100)::int,
    ceiling(random() * 200)::int,
    date '2023-01-01' + (random() * 365)::integer,
    ceiling(random() * 5)::int,
    p.unit_price,
    (ceiling(random() * 5)::int * p.unit_price)::decimal(10,2)
FROM generate_series(1, 500) g
JOIN products p ON p.product_id = ceiling(random() * 100)::int;

-- Analysis Queries

-- 1. Monthly Sales Analysis
SELECT 
    TO_CHAR(sale_date, 'YYYY-MM') AS month,
    COUNT(*) as total_transactions,
    SUM(total_amount) as total_revenue,
    AVG(total_amount) as avg_transaction_value
FROM sales
GROUP BY TO_CHAR(sale_date, 'YYYY-MM')
ORDER BY month;

-- 2. Top 10 Best-Selling Products
SELECT 
    p.product_name,
    COUNT(*) as times_sold,
    SUM(s.quantity) as total_quantity_sold,
    SUM(s.total_amount) as total_revenue
FROM sales s
JOIN products p ON s.product_id = p.product_id
GROUP BY p.product_id, p.product_name
ORDER BY total_revenue DESC
LIMIT 10;

-- 3. Store Performance Comparison
SELECT 
    st.store_name,
    st.city,
    st.state,
    COUNT(*) as total_transactions,
    SUM(s.total_amount) as total_revenue,
    AVG(s.total_amount) as avg_transaction_value
FROM sales s
JOIN stores st ON s.store_id = st.store_id
GROUP BY st.store_id, st.store_name, st.city, st.state
ORDER BY total_revenue DESC;

-- 4. Category Performance
SELECT 
    c.category_name,
    COUNT(*) as total_sales,
    SUM(s.quantity) as total_units_sold,
    SUM(s.total_amount) as total_revenue,
    AVG(s.total_amount) as avg_transaction_value
FROM sales s
JOIN products p ON s.product_id = p.product_id
JOIN categories c ON p.category_id = c.category_id
GROUP BY c.category_id, c.category_name
ORDER BY total_revenue DESC;

-- 5. Customer Purchase Frequency
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    COUNT(*) as total_purchases,
    SUM(s.total_amount) as total_spent,
    AVG(s.total_amount) as avg_purchase_amount
FROM customers c
JOIN sales s ON c.customer_id = s.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_spent DESC
LIMIT 20;

-- 6. Seasonal Sales Analysis
SELECT 
    EXTRACT(MONTH FROM sale_date) as month,
    COUNT(*) as total_sales,
    SUM(total_amount) as total_revenue
FROM sales
GROUP BY EXTRACT(MONTH FROM sale_date)
ORDER BY month;

-- 7. Regional Performance
SELECT 
    st.region,
    COUNT(*) as total_transactions,
    SUM(s.total_amount) as total_revenue,
    AVG(s.total_amount) as avg_transaction_value
FROM sales s
JOIN stores st ON s.store_id = st.store_id
GROUP BY st.region
ORDER BY total_revenue DESC;