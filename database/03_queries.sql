-- 10 SQL queries (SELECT, WHERE, DISTINCT, ORDER BY, INSERT, UPDATE, DELETE, aggregates, GROUP BY/HAVING, string/date functions, CASE)
-- Inventory Management System (MySQL 8.0+)

USE inventory_db;


-- 1. SELECT + WHERE + ORDER BY – products above ₹1000
SELECT name, unit_price FROM products WHERE unit_price > 1000 ORDER BY unit_price DESC;


-- 2. DISTINCT – cities that supply us
SELECT DISTINCT city FROM suppliers;


-- 3. INSERT – add a new product
INSERT INTO products(sku,name,category_id,supplier_id,unit_price,cost_price,reorder_level)
VALUES ('EL-004','USB Cable',1,1,199,110,25);


-- 4. UPDATE – 5% price rise on stationery
UPDATE products SET unit_price = unit_price*1.05 WHERE category_id = 3;


-- 5. DELETE – remove cancelled purchase orders
DELETE FROM purchase_orders WHERE status='Cancelled';


-- 6. Aggregate – total sales value
SELECT COUNT(DISTINCT sale_id) AS bills, SUM(quantity*unit_price) AS revenue FROM sales_items;


-- 7. GROUP BY + HAVING – products sold more than 20 units
SELECT product_id, SUM(quantity) AS units FROM sales_items GROUP BY product_id HAVING units > 20;


-- 8. String functions – SKU prefix and upper-case names
SELECT UPPER(name) AS product, LEFT(sku,2) AS prefix, CONCAT(sku,' - ',name) AS label FROM products;


-- 9. Date functions – sales per month
SELECT DATE_FORMAT(sale_date,'%Y-%m') AS month, COUNT(*) AS bills, DATEDIFF(CURDATE(),MAX(sale_date)) AS days_since_last
FROM sales GROUP BY month;


-- 10. CASE – stock status label
SELECT p.name, SUM(s.quantity) AS qty,
 CASE WHEN SUM(s.quantity)=0 THEN 'Out of Stock'
      WHEN SUM(s.quantity)<=p.reorder_level THEN 'Low Stock' ELSE 'OK' END AS status
FROM products p JOIN stock s ON s.product_id=p.product_id GROUP BY p.product_id, p.name, p.reorder_level;

