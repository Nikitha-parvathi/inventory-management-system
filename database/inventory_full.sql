-- inventory_full.sql : one-file import (schema + data + views/procedures/trigger + reports)

-- Database schema (CREATE TABLE statements)
-- Inventory Management System (MySQL 8.0+)

CREATE DATABASE inventory_db; USE inventory_db;

CREATE TABLE suppliers(
 supplier_id INT AUTO_INCREMENT PRIMARY KEY,
 name VARCHAR(80) NOT NULL, email VARCHAR(80) UNIQUE,
 phone VARCHAR(15), city VARCHAR(40),
 status VARCHAR(10) NOT NULL DEFAULT 'Active' CHECK (status IN ('Active','Inactive')));

CREATE TABLE categories(
 category_id INT AUTO_INCREMENT PRIMARY KEY,
 name VARCHAR(50) NOT NULL UNIQUE, description VARCHAR(120));

CREATE TABLE products(
 product_id INT AUTO_INCREMENT PRIMARY KEY,
 sku VARCHAR(15) NOT NULL UNIQUE, name VARCHAR(80) NOT NULL,
 category_id INT NOT NULL, supplier_id INT NOT NULL,
 unit_price DECIMAL(10,2) NOT NULL CHECK (unit_price > 0),
 cost_price DECIMAL(10,2) NOT NULL CHECK (cost_price >= 0),
 reorder_level INT NOT NULL DEFAULT 10,
 FOREIGN KEY (category_id) REFERENCES categories(category_id),
 FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id));

CREATE TABLE warehouses(
 warehouse_id INT AUTO_INCREMENT PRIMARY KEY,
 name VARCHAR(50) NOT NULL, city VARCHAR(40) NOT NULL);

CREATE TABLE stock(
 product_id INT, warehouse_id INT,
 quantity INT NOT NULL DEFAULT 0 CHECK (quantity >= 0),
 PRIMARY KEY (product_id, warehouse_id),
 FOREIGN KEY (product_id) REFERENCES products(product_id),
 FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id));

CREATE TABLE purchase_orders(
 po_id INT AUTO_INCREMENT PRIMARY KEY, supplier_id INT NOT NULL,
 order_date DATE NOT NULL,
 status VARCHAR(10) NOT NULL DEFAULT 'Pending' CHECK (status IN ('Pending','Received','Cancelled')),
 FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id));

CREATE TABLE purchase_items(
 item_id INT AUTO_INCREMENT PRIMARY KEY, po_id INT NOT NULL, product_id INT NOT NULL,
 quantity INT NOT NULL CHECK (quantity > 0), unit_cost DECIMAL(10,2) NOT NULL,
 FOREIGN KEY (po_id) REFERENCES purchase_orders(po_id),
 FOREIGN KEY (product_id) REFERENCES products(product_id));

CREATE TABLE sales(
 sale_id INT AUTO_INCREMENT PRIMARY KEY, customer_name VARCHAR(60) NOT NULL,
 sale_date DATE NOT NULL, warehouse_id INT NOT NULL,
 payment_status VARCHAR(10) NOT NULL DEFAULT 'Pending' CHECK (payment_status IN ('Paid','Pending')),
 FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id));

CREATE TABLE sales_items(
 item_id INT AUTO_INCREMENT PRIMARY KEY, sale_id INT NOT NULL, product_id INT NOT NULL,
 quantity INT NOT NULL CHECK (quantity > 0), unit_price DECIMAL(10,2) NOT NULL,
 FOREIGN KEY (sale_id) REFERENCES sales(sale_id),
 FOREIGN KEY (product_id) REFERENCES products(product_id));

CREATE TABLE stock_transactions(
 txn_id INT AUTO_INCREMENT PRIMARY KEY, product_id INT NOT NULL, warehouse_id INT NOT NULL,
 txn_type VARCHAR(3) NOT NULL CHECK (txn_type IN ('IN','OUT')),
 quantity INT NOT NULL CHECK (quantity > 0),
 txn_date DATE NOT NULL, reference VARCHAR(30),
 FOREIGN KEY (product_id) REFERENCES products(product_id),
 FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id));


-- Sample data
-- Inventory Management System (MySQL 8.0+)

USE inventory_db;

-- Note: Simulated retail data (Aug–Oct 2026) with valid PK/FK links.
INSERT INTO suppliers(name,email,phone,city) VALUES
('TechSource Pvt Ltd','sales@techsource.in','9000000001','Hyderabad'),
('HomeNest Furnishings','info@homenest.in','9000000002','Bengaluru'),
('PaperPlus Traders','orders@paperplus.in','9000000003','Chennai'),
('BrightWire Electricals','hello@brightwire.in','9000000004','Mumbai'),
('KitchenKart','care@kitchenkart.in','9000000005','Pune');

INSERT INTO categories(name,description) VALUES
('Electronics','Computers and accessories'),('Furniture','Office and home furniture'),
('Stationery','Paper and writing items'),('Electrical','Bulbs and wiring'),('Home','Household items');

INSERT INTO products(sku,name,category_id,supplier_id,unit_price,cost_price,reorder_level) VALUES
('EL-001','Laptop',1,1,55000,48000,5),('EL-002','Wireless Mouse',1,1,799,500,20),
('EL-003','Keyboard',1,1,1499,950,15),('FU-001','Office Chair',2,2,6500,4500,5),
('FU-002','Study Desk',2,2,8200,6000,4),('ST-001','A4 Paper Ream',3,3,320,240,50),
('ST-002','Ball Pens Box',3,3,120,80,40),('ST-003','Notebook',3,3,60,35,60),
('EC-001','LED Bulb',4,4,150,90,30),('EC-002','Extension Board',4,4,450,300,15),
('HM-001','Water Bottle',5,5,350,200,20);

INSERT INTO warehouses(name,city) VALUES ('Main Warehouse','Hyderabad'),('South Hub','Bengaluru'),('Stationery Depot','Chennai');

INSERT INTO stock VALUES (1,1,12),(1,2,3),(2,1,45),(3,1,8),(4,2,14),(5,2,2),
(6,3,120),(7,3,25),(8,3,30),(9,1,60),(10,1,18),(11,3,0);

INSERT INTO purchase_orders(supplier_id,order_date,status) VALUES
(1,'2026-08-05','Received'),(2,'2026-08-12','Received'),(3,'2026-09-01','Received'),
(4,'2026-09-10','Pending'),(1,'2026-09-25','Received'),(5,'2026-10-08','Pending');

INSERT INTO purchase_items(po_id,product_id,quantity,unit_cost) VALUES
(1,1,10,48000),(1,2,50,500),(2,4,15,4500),(2,5,6,6000),(3,6,150,240),
(3,7,60,80),(3,8,100,35),(4,9,80,90),(5,3,20,950),(6,11,40,200);

INSERT INTO sales(customer_name,sale_date,warehouse_id,payment_status) VALUES
('Ravi Kumar','2026-09-03',1,'Paid'),('Anita Rao','2026-09-15',2,'Paid'),
('Sri Traders','2026-09-20',3,'Paid'),('Kiran Reddy','2026-10-02',1,'Pending'),
('Meena Iyer','2026-10-05',3,'Paid'),('Sri Traders','2026-10-12',3,'Paid'),
('Arjun Das','2026-10-18',2,'Pending'),('Ravi Kumar','2026-10-25',1,'Paid');

INSERT INTO sales_items(sale_id,product_id,quantity,unit_price) VALUES
(1,1,1,55000),(1,2,2,799),(2,4,2,6500),(3,6,40,320),(3,7,20,120),(3,8,50,60),(4,3,1,1499),
(5,8,10,60),(6,6,30,320),(6,8,40,60),(7,5,1,8200),(8,2,3,799),(8,9,10,150),(8,3,2,1499);

INSERT INTO stock_transactions(product_id,warehouse_id,txn_type,quantity,txn_date,reference) VALUES
(1,1,'IN',10,'2026-08-07','PO-1'),(2,1,'IN',50,'2026-08-07','PO-1'),(4,2,'IN',15,'2026-08-14','PO-2'),
(6,3,'IN',150,'2026-09-03','PO-3'),(1,1,'OUT',1,'2026-09-03','SALE-1'),(6,3,'OUT',40,'2026-09-20','SALE-3'),
(8,3,'OUT',50,'2026-09-20','SALE-3'),(3,1,'IN',20,'2026-09-27','PO-5'),(9,1,'OUT',10,'2026-10-25','SALE-8'),(2,1,'OUT',3,'2026-10-25','SALE-8');


-- Views, transactions, stored procedures, trigger, indexes
-- Inventory Management System (MySQL 8.0+)

USE inventory_db;


-- ==== Views ====
CREATE VIEW v_low_stock AS
SELECT p.product_id, p.name, p.reorder_level, COALESCE(SUM(s.quantity),0) AS total_stock
FROM products p LEFT JOIN stock s USING(product_id) GROUP BY p.product_id, p.name, p.reorder_level
HAVING total_stock <= p.reorder_level;

CREATE VIEW v_monthly_sales AS
SELECT DATE_FORMAT(sale_date,'%Y-%m') AS month, SUM(quantity*unit_price) AS revenue
FROM sales JOIN sales_items USING(sale_id) GROUP BY month;


-- ==== Transactions ====
-- Note: Transfer 5 Notebooks from Chennai to Main Warehouse atomically; ROLLBACK if anything fails.
START TRANSACTION;
UPDATE stock SET quantity = quantity-5 WHERE product_id=8 AND warehouse_id=3;
INSERT INTO stock VALUES (8,1,5) ON DUPLICATE KEY UPDATE quantity = quantity+5;
COMMIT;

START TRANSACTION;
DELETE FROM stock WHERE product_id=8;
ROLLBACK;   -- undo: stock rows restored


-- ==== Stored Procedures ====
DELIMITER //
CREATE PROCEDURE sp_receive_po(IN p_po INT, IN p_wh INT)
BEGIN
 START TRANSACTION;
 INSERT INTO stock(product_id,warehouse_id,quantity)
  SELECT product_id,p_wh,quantity FROM purchase_items WHERE po_id=p_po
  ON DUPLICATE KEY UPDATE quantity = stock.quantity + VALUES(quantity);
 INSERT INTO stock_transactions(product_id,warehouse_id,txn_type,quantity,txn_date,reference)
  SELECT product_id,p_wh,'IN',quantity,CURDATE(),CONCAT('PO-',p_po) FROM purchase_items WHERE po_id=p_po;
 UPDATE purchase_orders SET status='Received' WHERE po_id=p_po;
 COMMIT;
END//

CREATE PROCEDURE sp_sell_item(IN p_sale INT, IN p_prod INT, IN p_qty INT, IN p_wh INT)
BEGIN
 DECLARE avail INT;
 SELECT quantity INTO avail FROM stock WHERE product_id=p_prod AND warehouse_id=p_wh;
 IF avail IS NULL OR avail < p_qty THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Insufficient stock';
 ELSE
  INSERT INTO sales_items(sale_id,product_id,quantity,unit_price)
   SELECT p_sale,p_prod,p_qty,unit_price FROM products WHERE product_id=p_prod;
 END IF;
END//
DELIMITER ;
-- CALL sp_receive_po(4,1);   -- run manually to receive purchase order 4 into warehouse 1


-- ==== Trigger ====
-- Note: Automatically reduces stock and logs an OUT transaction whenever a sale line is added.
DELIMITER //
CREATE TRIGGER trg_sale_item_ai AFTER INSERT ON sales_items FOR EACH ROW
BEGIN
 DECLARE wh INT;
 SELECT warehouse_id INTO wh FROM sales WHERE sale_id=NEW.sale_id;
 UPDATE stock SET quantity = quantity-NEW.quantity WHERE product_id=NEW.product_id AND warehouse_id=wh;
 INSERT INTO stock_transactions(product_id,warehouse_id,txn_type,quantity,txn_date,reference)
 VALUES (NEW.product_id,wh,'OUT',NEW.quantity,CURDATE(),CONCAT('SALE-',NEW.sale_id));
END//
DELIMITER ;

-- Note: If you load the sample data above with this trigger already created, stock will be reduced twice – create the trigger after loading the data.

-- ==== Index and Performance Comparison ====
EXPLAIN SELECT * FROM sales_items WHERE product_id=8;   -- type=ALL (full scan)
CREATE INDEX idx_sales_items_product ON sales_items(product_id);
EXPLAIN SELECT * FROM sales_items WHERE product_id=8;   -- type=ref, rows scanned drop
CREATE INDEX idx_sales_date ON sales(sale_date);        -- speeds monthly reports

-- Note: With a small sample the difference is tiny, but on thousands of rows the index replaces a full table scan with a direct lookup.

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

