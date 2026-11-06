-- Business reports (run 07_advanced.sql first - report 2 uses a view)
-- Inventory Management System (MySQL 8.0+)

USE inventory_db;


-- 1. Current Stock Report
SELECT p.sku, p.name, c.name AS category, SUM(s.quantity) AS total_stock
FROM products p JOIN categories c USING(category_id) LEFT JOIN stock s USING(product_id) GROUP BY p.product_id, p.sku, p.name, c.name;


-- 2. Low-Stock Alert Report
SELECT * FROM v_low_stock;   -- view defined in Advanced SQL


-- 3. Supplier-wise Purchase Report
SELECT s.name AS supplier, COUNT(DISTINCT po.po_id) AS orders, SUM(pi.quantity*pi.unit_cost) AS purchase_value
FROM suppliers s JOIN purchase_orders po USING(supplier_id) JOIN purchase_items pi USING(po_id) GROUP BY s.supplier_id, s.name ORDER BY purchase_value DESC;


-- 4. Monthly Sales Report
SELECT DATE_FORMAT(sale_date,'%Y-%m') AS month, COUNT(DISTINCT sale_id) AS bills, SUM(quantity*unit_price) AS revenue
FROM sales JOIN sales_items USING(sale_id) GROUP BY month ORDER BY month;


-- 5. Fast-Moving Products (top sellers)
SELECT p.name, SUM(si.quantity) AS units_sold FROM sales_items si JOIN products p USING(product_id)
GROUP BY p.product_id, p.name ORDER BY units_sold DESC LIMIT 5;


-- 6. Slow-Moving Products (few or no sales)
SELECT p.name, COALESCE(SUM(si.quantity),0) AS units_sold FROM products p LEFT JOIN sales_items si USING(product_id)
GROUP BY p.product_id, p.name HAVING units_sold < 5 ORDER BY units_sold;


-- 7. Pending Purchase Orders
SELECT po.po_id, s.name, po.order_date FROM purchase_orders po JOIN suppliers s USING(supplier_id) WHERE po.status='Pending';

-- Note: Run each query on the sample data and capture the output screenshots for submission.
