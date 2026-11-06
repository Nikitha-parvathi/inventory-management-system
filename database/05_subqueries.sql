-- 5 subqueries
-- Inventory Management System (MySQL 8.0+)

USE inventory_db;


-- 1. Products that have never been ordered by customers
SELECT name FROM products WHERE product_id NOT IN (SELECT product_id FROM sales_items);


-- 2. Products priced above the average price
SELECT name, unit_price FROM products WHERE unit_price > (SELECT AVG(unit_price) FROM products);


-- 3. Second-highest priced product
SELECT name, unit_price FROM products WHERE unit_price = (SELECT MAX(unit_price) FROM products WHERE unit_price < (SELECT MAX(unit_price) FROM products));


-- 4. Customers whose bill is above the average bill
SELECT sale_id, customer_name, SUM(quantity*unit_price) AS bill FROM sales JOIN sales_items USING(sale_id) GROUP BY sale_id, customer_name
HAVING bill > (SELECT AVG(t) FROM (SELECT SUM(quantity*unit_price) t FROM sales_items GROUP BY sale_id) x);


-- 5. Products whose total stock is below reorder level
SELECT name FROM products p WHERE (SELECT COALESCE(SUM(quantity),0) FROM stock s WHERE s.product_id=p.product_id) <= p.reorder_level;

