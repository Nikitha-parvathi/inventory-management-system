-- =====================================================================
-- PROJECT 8: INVENTORY MANAGEMENT SYSTEM  (MySQL 8.0+)
-- Modules: Suppliers, Product Categories, Products, Warehouses,
--          Purchase Orders, Purchase Items, Sales, Sales Items,
--          Stock Transactions
-- Design idea:
--   * stock_transactions is the audit ledger (every stock movement).
--   * warehouse_stock holds the current quantity per product/warehouse
--     and is updated automatically by a trigger on the ledger.
--   * Sales are blocked if stock is insufficient.
--   * Purchase orders add stock when received (sp_receive_po).
-- =====================================================================

DROP DATABASE IF EXISTS inventory_db;
CREATE DATABASE inventory_db;
USE inventory_db;

-- ---------------------------------------------------------------------
-- 1. TABLES
-- ---------------------------------------------------------------------
CREATE TABLE suppliers (
    supplier_id    INT AUTO_INCREMENT PRIMARY KEY,
    supplier_name  VARCHAR(100) NOT NULL,
    contact_person VARCHAR(100),
    phone          VARCHAR(20),
    email          VARCHAR(100) UNIQUE,
    address        VARCHAR(255),
    created_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE product_categories (
    category_id   INT AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(80) NOT NULL UNIQUE,
    description   VARCHAR(255)
);

CREATE TABLE warehouses (
    warehouse_id   INT AUTO_INCREMENT PRIMARY KEY,
    warehouse_name VARCHAR(80) NOT NULL UNIQUE,
    location       VARCHAR(150)
);

CREATE TABLE products (
    product_id    INT AUTO_INCREMENT PRIMARY KEY,
    sku           VARCHAR(30)  NOT NULL UNIQUE,
    product_name  VARCHAR(120) NOT NULL,
    category_id   INT NOT NULL,
    supplier_id   INT NOT NULL,                 -- preferred supplier
    cost_price    DECIMAL(10,2) NOT NULL CHECK (cost_price >= 0),
    selling_price DECIMAL(10,2) NOT NULL CHECK (selling_price >= 0),
    reorder_level INT NOT NULL DEFAULT 10 CHECK (reorder_level >= 0),
    is_active     BOOLEAN NOT NULL DEFAULT TRUE,
    FOREIGN KEY (category_id) REFERENCES product_categories(category_id),
    FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id)
);

-- Current stock snapshot (maintained by trigger)
CREATE TABLE warehouse_stock (
    product_id   INT NOT NULL,
    warehouse_id INT NOT NULL,
    quantity     INT NOT NULL DEFAULT 0 CHECK (quantity >= 0),
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (product_id, warehouse_id),
    FOREIGN KEY (product_id)   REFERENCES products(product_id),
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id)
);

CREATE TABLE purchase_orders (
    po_id         INT AUTO_INCREMENT PRIMARY KEY,
    supplier_id   INT NOT NULL,
    warehouse_id  INT NOT NULL,                 -- delivery warehouse
    order_date    DATE NOT NULL,
    received_date DATE NULL,
    status        ENUM('Ordered','Received','Cancelled') NOT NULL DEFAULT 'Ordered',
    total_amount  DECIMAL(12,2) NOT NULL DEFAULT 0,
    FOREIGN KEY (supplier_id)  REFERENCES suppliers(supplier_id),
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id)
);

CREATE TABLE purchase_items (
    po_item_id INT AUTO_INCREMENT PRIMARY KEY,
    po_id      INT NOT NULL,
    product_id INT NOT NULL,
    quantity   INT NOT NULL CHECK (quantity > 0),
    unit_cost  DECIMAL(10,2) NOT NULL CHECK (unit_cost >= 0),
    line_total DECIMAL(12,2) GENERATED ALWAYS AS (quantity * unit_cost) STORED,
    FOREIGN KEY (po_id)      REFERENCES purchase_orders(po_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

CREATE TABLE sales (
    sale_id       INT AUTO_INCREMENT PRIMARY KEY,
    sale_date     DATE NOT NULL,
    warehouse_id  INT NOT NULL,                 -- stock is issued from here
    customer_name VARCHAR(100) DEFAULT 'Walk-in',
    total_amount  DECIMAL(12,2) NOT NULL DEFAULT 0,
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id)
);

CREATE TABLE sales_items (
    sale_item_id INT AUTO_INCREMENT PRIMARY KEY,
    sale_id      INT NOT NULL,
    product_id   INT NOT NULL,
    quantity     INT NOT NULL CHECK (quantity > 0),
    unit_price   DECIMAL(10,2) NOT NULL CHECK (unit_price >= 0),
    line_total   DECIMAL(12,2) GENERATED ALWAYS AS (quantity * unit_price) STORED,
    FOREIGN KEY (sale_id)    REFERENCES sales(sale_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- Ledger of every stock movement (+ in, - out)
CREATE TABLE stock_transactions (
    txn_id          BIGINT AUTO_INCREMENT PRIMARY KEY,
    product_id      INT NOT NULL,
    warehouse_id    INT NOT NULL,
    txn_type        ENUM('PURCHASE','SALE','ADJUSTMENT','TRANSFER_IN','TRANSFER_OUT','RETURN') NOT NULL,
    quantity_change INT NOT NULL,               -- positive = in, negative = out
    reference_type  VARCHAR(20),                -- 'PO', 'SALE', 'MANUAL'
    reference_id    INT,
    txn_date        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    remarks         VARCHAR(255),
    FOREIGN KEY (product_id)   REFERENCES products(product_id),
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id)
);

-- Indexes for reporting
CREATE INDEX idx_sales_date      ON sales(sale_date);
CREATE INDEX idx_po_date         ON purchase_orders(order_date);
CREATE INDEX idx_txn_product     ON stock_transactions(product_id, txn_date);
CREATE INDEX idx_products_cat    ON products(category_id);

-- ---------------------------------------------------------------------
-- 2. TRIGGERS & STORED PROCEDURE
-- ---------------------------------------------------------------------
DELIMITER //

-- Ledger -> current stock
CREATE TRIGGER trg_txn_update_stock
AFTER INSERT ON stock_transactions
FOR EACH ROW
BEGIN
    -- make sure a row exists (starting at 0), then apply the change
    INSERT INTO warehouse_stock (product_id, warehouse_id, quantity)
    VALUES (NEW.product_id, NEW.warehouse_id, 0)
    ON DUPLICATE KEY UPDATE quantity = quantity;

    UPDATE warehouse_stock
       SET quantity = quantity + NEW.quantity_change
     WHERE product_id = NEW.product_id
       AND warehouse_id = NEW.warehouse_id;
END//

-- Keep PO total up to date
CREATE TRIGGER trg_po_item_total
AFTER INSERT ON purchase_items
FOR EACH ROW
BEGIN
    UPDATE purchase_orders
       SET total_amount = total_amount + (NEW.quantity * NEW.unit_cost)
     WHERE po_id = NEW.po_id;
END//

-- Prevent selling more than available
CREATE TRIGGER trg_sale_item_check
BEFORE INSERT ON sales_items
FOR EACH ROW
BEGIN
    DECLARE v_wh  INT;
    DECLARE v_qty INT DEFAULT 0;

    SELECT warehouse_id INTO v_wh FROM sales WHERE sale_id = NEW.sale_id;

    SELECT quantity INTO v_qty
      FROM warehouse_stock
     WHERE product_id = NEW.product_id AND warehouse_id = v_wh;

    IF v_qty < NEW.quantity THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Insufficient stock in warehouse for this sale';
    END IF;
END//

-- After a sale line: reduce stock (via ledger) and update sale total
CREATE TRIGGER trg_sale_item_after
AFTER INSERT ON sales_items
FOR EACH ROW
BEGIN
    INSERT INTO stock_transactions
        (product_id, warehouse_id, txn_type, quantity_change,
         reference_type, reference_id, txn_date)
    SELECT NEW.product_id, s.warehouse_id, 'SALE', -NEW.quantity,
           'SALE', NEW.sale_id, s.sale_date
      FROM sales s
     WHERE s.sale_id = NEW.sale_id;

    UPDATE sales
       SET total_amount = total_amount + (NEW.quantity * NEW.unit_price)
     WHERE sale_id = NEW.sale_id;
END//

-- Receive a purchase order: adds stock for every line item
CREATE PROCEDURE sp_receive_po (IN p_po_id INT, IN p_received_date DATE)
BEGIN
    DECLARE v_status VARCHAR(20);

    SELECT status INTO v_status FROM purchase_orders WHERE po_id = p_po_id;

    IF v_status IS NULL OR v_status <> 'Ordered' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'PO not found or not in Ordered status';
    END IF;

    INSERT INTO stock_transactions
        (product_id, warehouse_id, txn_type, quantity_change,
         reference_type, reference_id, txn_date)
    SELECT pi.product_id, po.warehouse_id, 'PURCHASE', pi.quantity,
           'PO', po.po_id, p_received_date
      FROM purchase_items pi
      JOIN purchase_orders po ON po.po_id = pi.po_id
     WHERE po.po_id = p_po_id;

    UPDATE purchase_orders
       SET status = 'Received', received_date = p_received_date
     WHERE po_id = p_po_id;
END//

-- Manual stock adjustment (damage, count correction ...)
CREATE PROCEDURE sp_adjust_stock (IN p_product INT, IN p_wh INT,
                                  IN p_change INT, IN p_remarks VARCHAR(255))
BEGIN
    INSERT INTO stock_transactions
        (product_id, warehouse_id, txn_type, quantity_change,
         reference_type, remarks)
    VALUES (p_product, p_wh, 'ADJUSTMENT', p_change, 'MANUAL', p_remarks);
END//

DELIMITER ;

-- ---------------------------------------------------------------------
-- 3. SAMPLE DATA
-- ---------------------------------------------------------------------
INSERT INTO suppliers (supplier_name, contact_person, phone, email, address) VALUES
('Fresh Foods Ltd',        'Anil Rao',    '9810000001', 'sales@freshfoods.com',  'Pune'),
('PaperWorld Traders',     'Meera Shah',  '9810000002', 'orders@paperworld.com', 'Mumbai'),
('HomeCare Distributors',  'Rohit Verma', '9810000003', 'info@homecare.com',     'Nashik'),
('BrightLite Electricals', 'Sana Khan',   '9810000004', 'sales@brightlite.com',  'Surat');

INSERT INTO product_categories (category_name, description) VALUES
('Grocery',    'Food and staples'),
('Stationery', 'Paper and writing items'),
('Household',  'Cleaning and personal care'),
('Electrical', 'Bulbs and accessories');

INSERT INTO warehouses (warehouse_name, location) VALUES
('Main Warehouse',  'Pune - Hadapsar'),
('City Store Depot','Pune - Kothrud');

INSERT INTO products (sku, product_name, category_id, supplier_id, cost_price, selling_price, reorder_level) VALUES
('GRO-001', 'Basmati Rice 5kg',   1, 1, 420.00, 520.00,  20),
('GRO-002', 'Sunflower Oil 1L',   1, 1, 110.00, 135.00,  40),
('STA-001', 'Notebook A4',        2, 2,  25.00,  40.00,  50),
('STA-002', 'Ballpoint Pen',      2, 2,   5.00,  10.00, 100),
('HOU-001', 'Detergent 1kg',      3, 3,  90.00, 120.00,  25),
('HOU-002', 'Bath Soap',          3, 3,  25.00,  38.00,  60),
('ELE-001', 'LED Bulb 9W',        4, 4,  55.00,  85.00,  30),
('ELE-002', 'Extension Board',    4, 4, 220.00, 320.00,  10);

-- Purchase orders
INSERT INTO purchase_orders (supplier_id, warehouse_id, order_date) VALUES
(1, 1, '2026-08-01'),
(2, 1, '2026-08-05'),
(3, 2, '2026-08-10'),
(4, 2, '2026-08-12'),
(1, 1, '2026-10-30');   -- still pending

INSERT INTO purchase_items (po_id, product_id, quantity, unit_cost) VALUES
(1, 1,  50, 420.00), (1, 2, 100, 110.00),
(2, 3, 200,  25.00), (2, 4, 300,   5.00),
(3, 5,  60,  90.00), (3, 6, 120,  25.00),
(4, 7,  80,  55.00), (4, 8,  20, 220.00),
(5, 2,  60, 112.00);

-- Receive first four orders (adds stock)
CALL sp_receive_po(1, '2026-08-04');
CALL sp_receive_po(2, '2026-08-08');
CALL sp_receive_po(3, '2026-08-13');
CALL sp_receive_po(4, '2026-08-15');

-- Sales
INSERT INTO sales (sale_date, warehouse_id, customer_name) VALUES
('2026-08-20', 1, 'Walk-in'),
('2026-09-02', 1, 'Sharma Stores'),
('2026-09-18', 2, 'Walk-in'),
('2026-10-05', 1, 'Patil Mart'),
('2026-10-20', 2, 'Walk-in'),
('2026-10-28', 1, 'Sharma Stores');

INSERT INTO sales_items (sale_id, product_id, quantity, unit_price) VALUES
(1, 1,   5, 520.00), (1, 4,  20, 10.00),
(2, 2,  30, 135.00), (2, 3,  40, 40.00),
(3, 5,  10, 120.00), (3, 6,  30, 38.00), (3, 7, 10, 85.00),
(4, 2,  50, 135.00), (4, 3,  60, 40.00), (4, 4, 150, 10.00),
(5, 6,  70,  38.00), (5, 7,  25, 85.00), (5, 8,   1, 320.00),
(6, 2,  15, 135.00), (6, 1,  40, 520.00);

-- Example manual adjustment (3 damaged notebooks)
CALL sp_adjust_stock(3, 1, -3, 'Damaged in storage');

-- ---------------------------------------------------------------------
-- 4. REPORT VIEWS
-- ---------------------------------------------------------------------

-- 4.1 Current stock report (per warehouse)
CREATE VIEW v_current_stock AS
SELECT p.sku, p.product_name, c.category_name, w.warehouse_name,
       ws.quantity, p.reorder_level,
       ROUND(ws.quantity * p.cost_price, 2) AS stock_value
FROM warehouse_stock ws
JOIN products           p ON p.product_id   = ws.product_id
JOIN product_categories c ON c.category_id  = p.category_id
JOIN warehouses         w ON w.warehouse_id = ws.warehouse_id;

-- 4.2 Current stock, all warehouses combined
CREATE VIEW v_total_stock AS
SELECT p.product_id, p.sku, p.product_name, p.reorder_level,
       COALESCE(SUM(ws.quantity), 0) AS total_qty,
       ROUND(COALESCE(SUM(ws.quantity), 0) * p.cost_price, 2) AS stock_value
FROM products p
LEFT JOIN warehouse_stock ws ON ws.product_id = p.product_id
WHERE p.is_active = TRUE
GROUP BY p.product_id, p.sku, p.product_name, p.reorder_level, p.cost_price;

-- 4.3 Low-stock alerts (with suggested reorder quantity and supplier)
CREATE VIEW v_low_stock_alerts AS
SELECT t.sku, t.product_name, t.total_qty, t.reorder_level,
       CASE WHEN t.total_qty = 0 THEN 'OUT OF STOCK' ELSE 'LOW STOCK' END AS alert,
       (t.reorder_level * 2 - t.total_qty) AS suggested_order_qty,
       s.supplier_name, s.phone AS supplier_phone
FROM v_total_stock t
JOIN products  p ON p.product_id  = t.product_id
JOIN suppliers s ON s.supplier_id = p.supplier_id
WHERE t.total_qty <= t.reorder_level;

-- 4.4 Supplier-wise purchase report
CREATE VIEW v_supplier_purchases AS
SELECT s.supplier_name,
       COUNT(DISTINCT po.po_id)             AS total_orders,
       COALESCE(SUM(pi.quantity), 0)        AS units_ordered,
       COALESCE(SUM(pi.line_total), 0)      AS total_purchase_value,
       COUNT(DISTINCT CASE WHEN po.status = 'Received' THEN po.po_id END) AS orders_received
FROM suppliers s
LEFT JOIN purchase_orders po ON po.supplier_id = s.supplier_id AND po.status <> 'Cancelled'
LEFT JOIN purchase_items  pi ON pi.po_id = po.po_id
GROUP BY s.supplier_id, s.supplier_name;

-- 4.5 Monthly sales report
CREATE VIEW v_monthly_sales AS
SELECT DATE_FORMAT(s.sale_date, '%Y-%m')                  AS sales_month,
       COUNT(DISTINCT s.sale_id)                          AS invoices,
       SUM(si.quantity)                                   AS units_sold,
       SUM(si.line_total)                                 AS revenue,
       SUM(si.quantity * (si.unit_price - p.cost_price))  AS gross_profit
FROM sales s
JOIN sales_items si ON si.sale_id    = s.sale_id
JOIN products    p  ON p.product_id  = si.product_id
GROUP BY DATE_FORMAT(s.sale_date, '%Y-%m');

-- 4.6 Fast / medium / slow-moving products (last 90 days)
--     Fast >= 50 units, Medium 20-49, Slow < 20 (adjust thresholds as needed)
CREATE VIEW v_product_movement AS
SELECT p.sku, p.product_name,
       COALESCE(SUM(si.quantity), 0) AS units_sold_90d,
       COALESCE(t.total_qty, 0)      AS current_stock,
       CASE
            WHEN COALESCE(SUM(si.quantity), 0) >= 50 THEN 'FAST-MOVING'
            WHEN COALESCE(SUM(si.quantity), 0) >= 20 THEN 'MEDIUM'
            ELSE 'SLOW-MOVING'
       END AS movement_class
FROM products p
LEFT JOIN v_total_stock t ON t.product_id = p.product_id
LEFT JOIN sales_items  si ON si.product_id = p.product_id
LEFT JOIN sales        s  ON s.sale_id = si.sale_id
                         AND s.sale_date >= DATE_SUB(CURDATE(), INTERVAL 90 DAY)
WHERE p.is_active = TRUE
GROUP BY p.product_id, p.sku, p.product_name, t.total_qty;

-- ---------------------------------------------------------------------
-- 5. RUN THE REPORTS
-- ---------------------------------------------------------------------
-- Current stock
SELECT * FROM v_current_stock ORDER BY warehouse_name, product_name;
SELECT * FROM v_total_stock   ORDER BY product_name;

-- Low-stock alerts
SELECT * FROM v_low_stock_alerts ORDER BY total_qty;

-- Supplier-wise purchases
SELECT * FROM v_supplier_purchases ORDER BY total_purchase_value DESC;

-- Monthly sales
SELECT * FROM v_monthly_sales ORDER BY sales_month;

-- Fast-moving and slow-moving
SELECT * FROM v_product_movement WHERE movement_class = 'FAST-MOVING' ORDER BY units_sold_90d DESC;
SELECT * FROM v_product_movement WHERE movement_class = 'SLOW-MOVING' ORDER BY units_sold_90d;

-- Stock ledger for one product (audit trail)
SELECT txn_date, txn_type, quantity_change, reference_type, reference_id, remarks
FROM stock_transactions WHERE product_id = 2 ORDER BY txn_date, txn_id;

-- Test: this fails with 'Insufficient stock in warehouse for this sale'
-- INSERT INTO sales (sale_date, warehouse_id) VALUES (CURDATE(), 1);
-- INSERT INTO sales_items (sale_id, product_id, quantity, unit_price) VALUES (LAST_INSERT_ID(), 1, 999, 520);
