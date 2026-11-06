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
