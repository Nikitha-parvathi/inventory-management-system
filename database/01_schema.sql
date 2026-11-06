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

