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

