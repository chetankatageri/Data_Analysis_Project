-- Create database
CREATE DATABASE retail_analysis;

-- Use database
USE retail_analysis;

-- Create categories table
CREATE TABLE categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(50) NOT NULL,
    department VARCHAR(50) NOT NULL
);

-- Create products table
CREATE TABLE products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    category_id INT,
    unit_price DECIMAL(10,2) NOT NULL,
    supplier VARCHAR(100),
    stock_quantity INT DEFAULT 0,
    FOREIGN KEY (category_id) REFERENCES categories(category_id)
);

-- Create stores table
CREATE TABLE stores (
    store_id INT AUTO_INCREMENT PRIMARY KEY,
    store_name VARCHAR(100) NOT NULL,
    city VARCHAR(50) NOT NULL,
    state VARCHAR(2) NOT NULL,
    region VARCHAR(20) NOT NULL
);

-- Create customers table
CREATE TABLE customers (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE,
    join_date DATE NOT NULL
);

-- Create sales table
CREATE TABLE sales (
    sale_id INT AUTO_INCREMENT PRIMARY KEY,
    store_id INT,
    product_id INT,
    customer_id INT,
    sale_date DATE NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (store_id) REFERENCES stores(store_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
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
DELIMITER $$
CREATE PROCEDURE generate_products()
BEGIN
    DECLARE i INT DEFAULT 1;
    WHILE i <= 100 DO
        INSERT INTO products (product_name, category_id, unit_price, supplier, stock_quantity)
        VALUES (
            CONCAT('Product ', i),
            CEIL(RAND() * 10),
            ROUND(RAND() * 900 + 100, 2),
            CONCAT('Supplier ', CEIL(RAND() * 5)),
            CEIL(RAND() * 100)
        );
        SET i = i + 1;
    END WHILE;
END$$
DELIMITER ;

CALL generate_products();
DROP PROCEDURE generate_products;

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
DELIMITER $$
CREATE PROCEDURE generate_customers()
BEGIN
    DECLARE i INT DEFAULT 1;
    WHILE i <= 200 DO
        INSERT INTO customers (first_name, last_name, email, join_date)
        VALUES (
            CONCAT('FirstName', i),
            CONCAT('LastName', i),
            CONCAT('customer', i, '@email.com'),
            DATE_ADD('2023-01-01', INTERVAL FLOOR(RAND() * 365) DAY)
        );
        SET i = i + 1;
    END WHILE;
END$$
DELIMITER ;

CALL generate_customers();
DROP PROCEDURE generate_customers;

-- Insert sample sales data (500 records)
DELIMITER $$
CREATE PROCEDURE generate_sales()
BEGIN
    DECLARE i INT DEFAULT 1;
    WHILE i <= 500 DO
        INSERT INTO sales (store_id, product_id, customer_id, sale_date, quantity, unit_price, total_amount)
        SELECT 
            CEIL(RAND() * 10),
            p.product_id,
            CEIL(RAND() * 200),
            DATE_ADD('2023-01-01', INTERVAL FLOOR(RAND() * 365) DAY),
            qty,
            p.unit_price,
            qty * p.unit_price
        FROM (SELECT CEIL(RAND() * 5) as qty, CEIL(RAND() * 100) as prod_id) as tmp
        JOIN products p ON p.product_id = tmp.prod_id;
        
        SET i = i + 1;
    END WHILE;
END$$
DELIMITER ;

CALL generate_sales();
DROP PROCEDURE generate_sales;

-- Analysis Queries

-- 1. Monthly Sales Analysis
SELECT 
    DATE_FORMAT(sale_date, '%Y-%m') AS month,
    COUNT(*) as total_transactions,
    SUM(total_amount) as total_revenue,
    AVG(total_amount) as avg_transaction_value
FROM sales
GROUP BY DATE_FORMAT(sale_date, '%Y-%m')
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
    MONTH(sale_date) as month,
    COUNT(*) as total_sales,
    SUM(total_amount) as total_revenue
FROM sales
GROUP BY MONTH(sale_date)
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
