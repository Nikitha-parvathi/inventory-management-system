-- 10 JOIN queries with purpose and expected output
-- Inventory Management System (MySQL 8.0+)

USE inventory_db;


-- 1. INNER JOIN – product with category
-- Note: Lists each product with its category name; 11 rows.
SELECT p.name, c.name AS category FROM products p INNER JOIN categories c ON p.category_id=c.category_id;


-- 2. INNER JOIN – product with supplier
-- Note: Shows who supplies each product.
SELECT p.name, s.name AS supplier, s.city FROM products p JOIN suppliers s ON p.supplier_id=s.supplier_id;


-- 3. LEFT JOIN – products never sold
-- Note: Expected: Extension Board, Water Bottle.
SELECT p.name FROM products p LEFT JOIN sales_items si ON p.product_id=si.product_id WHERE si.item_id IS NULL;


-- 4. RIGHT JOIN – warehouses with or without stock rows
-- Note: Every warehouse appears, even if empty.
SELECT w.name, COUNT(s.product_id) AS items FROM stock s RIGHT JOIN warehouses w ON s.warehouse_id=w.warehouse_id GROUP BY w.name;


-- 5. SELF JOIN – products of the same category with higher price
-- Note: Pairs a cheaper product with a costlier one in its category.
SELECT a.name AS cheaper, b.name AS costlier FROM products a JOIN products b
 ON a.category_id=b.category_id AND a.unit_price<b.unit_price;


-- 6. Multi-table – purchase order details
-- Note: PO, supplier, product, quantity and line cost.
SELECT po.po_id, s.name AS supplier, p.name AS product, pi.quantity, pi.quantity*pi.unit_cost AS line_cost
FROM purchase_orders po JOIN suppliers s ON po.supplier_id=s.supplier_id
JOIN purchase_items pi ON pi.po_id=po.po_id JOIN products p ON p.product_id=pi.product_id;


-- 7. Multi-table – sales invoice lines
-- Note: Customer, warehouse, product and amount per sale line.
SELECT sa.sale_id, sa.customer_name, w.name AS warehouse, p.name, si.quantity*si.unit_price AS amount
FROM sales sa JOIN warehouses w USING(warehouse_id) JOIN sales_items si USING(sale_id) JOIN products p USING(product_id);


-- 8. Stock by warehouse
-- Note: Where each product is physically held.
SELECT w.name AS warehouse, p.name AS product, s.quantity FROM stock s
JOIN products p ON p.product_id=s.product_id JOIN warehouses w ON w.warehouse_id=s.warehouse_id ORDER BY w.name;


-- 9. LEFT JOIN – suppliers with no purchase orders
-- Note: Identifies idle suppliers.
SELECT s.name FROM suppliers s LEFT JOIN purchase_orders po ON s.supplier_id=po.supplier_id WHERE po.po_id IS NULL;


-- 10. Stock movement history
-- Note: Audit trail of IN/OUT movement with product and warehouse names.
SELECT t.txn_date, p.name, w.name AS warehouse, t.txn_type, t.quantity, t.reference
FROM stock_transactions t JOIN products p USING(product_id) JOIN warehouses w USING(warehouse_id) ORDER BY t.txn_date;

