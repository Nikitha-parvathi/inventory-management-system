# INVENTORY MANAGEMENT SYSTEM

**Python Console Application with MySQL Database**

---

## 1. Project Overview

The Inventory Management System is a Python-based console application connected to a MySQL database. It helps a retail business manage its products, suppliers, purchases, sales and available stock, and warns the business before stock runs out.

The system allows users to:

- Manage suppliers, product categories, warehouses and products
- Create purchase orders and receive goods into stock
- Record sales and reduce stock automatically
- Block sales when stock is insufficient
- Track every stock movement in a ledger
- Search and filter products
- Generate low-stock alerts
- Generate stock, purchase, sales and product-movement reports
- Export reports to CSV
- Validate user input and handle errors safely

---

## 2. Problem Statement

A retail business handles many products from several suppliers and sells them from more than one warehouse. Tracking purchases, sales and remaining stock manually makes it easy to run out of popular items, over-order slow items, or sell goods that are not in stock.

This project provides a simple console-based solution that keeps stock accurate and shows the business what to reorder.

The system helps users:

- Record suppliers, products and warehouses
- Place and receive purchase orders
- Record sales
- Monitor stock in every warehouse
- Detect products below their reorder level
- Review purchases by supplier
- Review monthly sales and profit
- Identify fast-moving and slow-moving products

---

## 3. Project Objectives

1. To develop a Python-based inventory management application.
2. To store data in a normalized MySQL database with nine modules.
3. To update stock automatically when goods are purchased or sold.
4. To prevent sales that exceed available stock.
5. To maintain a stock-transaction ledger for tracking and auditing.
6. To generate low-stock alerts with suggested reorder quantities.
7. To generate supplier-wise purchase, monthly sales, current stock and product-movement reports.
8. To validate user input and prevent invalid data.
9. To implement exception handling for reliable execution.
10. To export reports to CSV files.

---

## 4. Features

### 4.1 Master Data Management
- Add and list suppliers
- Add and list product categories
- Add and list warehouses
- Add products with SKU, prices and reorder level
- Validate names, email, phone, prices and reorder level
- Prevent duplicate SKUs, supplier emails, category names and warehouse names

### 4.2 Purchase Management
- Create purchase orders with several items
- View pending purchase orders
- Receive a purchase order (adds stock to the delivery warehouse)
- Prevent receiving the same order twice
- Purchase order total calculated automatically

### 4.3 Sales Management
- Record sales with several items
- Show available stock before asking for the quantity
- Default unit price taken from the product's selling price
- Sale total calculated automatically
- A failed sale is rolled back completely

### 4.4 Stock Management
- Current quantity per product and warehouse
- Stock ledger for every product (purchases, sales, adjustments)
- Manual stock adjustment with a reason (damage, count correction)
- Search and filter products by keyword, category, supplier and low stock

### 4.5 Low-Stock Alerts
A product is flagged when its total stock across all warehouses is at or below its reorder level. The alert shows the supplier, their phone number and a suggested order quantity.

### 4.6 Reports
- Current stock report
- Low-stock alerts
- Supplier-wise purchase report
- Monthly sales report
- Fast-moving products
- Slow-moving products
- CSV export for every report

---

## 5. Technologies Used

| Technology | Purpose |
|---|---|
| Python 3.9+ | Application development |
| MySQL 8.0 | Data storage, triggers, stored procedures and views |
| mysql-connector-python | Connecting Python to MySQL |
| unittest | Automated testing |
| VS Code / MySQL Workbench | Development and database tools |
| Git and GitHub | Version control and collaboration |

---

## 6. Python Concepts Used

**Variables and Data Types** - store product, supplier and quantity information; `Decimal` is used for money.

**Conditional Statements** - validation and business-rule decisions.

**Loops** - menus, repeated input until valid, collecting line items, printing tables.

**Lists and Dictionaries** - query results are lists of dictionaries; items are collected in lists.

**Functions** - the application is split into small reusable functions.

**Classes and Objects** - represent Supplier, Category, Warehouse, Product and LineItem; services and database access are also classes.

**Object-Oriented Programming** - classes with attributes and methods, `@dataclass`, and separation of responsibilities between model, service, report and database classes.

**File Handling** - reports are exported to CSV files using the `csv` module.

**Exception Handling** - `try`, `except`, `finally`, `raise ... from`, a custom exception hierarchy, and a context manager for database transactions.

**Regular Expressions** - validate email addresses and phone numbers.

**Date and Time** - `datetime` is used for order, sale and received dates, and for timestamped CSV file names.

**Modules and Packages** - code is organised in the `inventory` package.

**Database Access** - parameterised SQL queries (protection against SQL injection), transactions, stored procedure calls.

---

## 7. Project Structure

```
inventory-management-system/
│
├── main.py
├── README.md
├── requirements.txt
├── .gitignore
├── inventory_management_system.sql
│
├── inventory/
│   ├── __init__.py
│   ├── cli.py
│   ├── services.py
│   ├── reports.py
│   ├── models.py
│   ├── validators.py
│   ├── db.py
│   └── exceptions.py
│
├── reports/
│   └── .gitkeep
│
└── tests/
    ├── __init__.py
    └── test_app.py
```

### File Description

**main.py** - starting point of the application.

**inventory_management_system.sql** - creates the database `inventory_db`: tables, triggers, stored procedures, report views and sample data.

**inventory/cli.py** - menus and user interaction, input loops, report display and CSV export prompts.

**inventory/services.py** - business logic: master data, search, purchase orders, sales, stock adjustments, ledger (`InventoryService`).

**inventory/reports.py** - report queries, table formatting and CSV export (`ReportService`).

**inventory/models.py** - `Supplier`, `Category`, `Warehouse`, `Product`, `LineItem` classes.

**inventory/validators.py** - input validation functions.

**inventory/db.py** - `Database` class: connection, queries, transactions and MySQL error translation.

**inventory/exceptions.py** - custom exception classes.

**reports/** - folder where exported CSV files are saved.

**tests/test_app.py** - automated unit tests.

**requirements.txt** - Python dependencies.

**.gitignore** - prevents cache files and generated CSV files from being committed.

---

## 8. Module Description

### Models (`models.py`)

**Supplier** - Attributes: supplier_name, contact_person, phone, email, address. Validates data when created.

**Category** - Attributes: category_name, description.

**Warehouse** - Attributes: warehouse_name, location.

**Product** - Attributes: sku, product_name, category_id, supplier_id, cost_price, selling_price, reorder_level. Methods: `margin()` returns profit per unit. Rejects a selling price lower than the cost price.

**LineItem** - Attributes: product_id, quantity, unit_amount. Methods: `total()`. Used for both purchase and sale lines.

### Services (`services.py`) - `InventoryService`
- `add_supplier()`, `add_category()`, `add_warehouse()`, `add_product()`
- `search_products()`
- `create_purchase_order()`, `receive_purchase_order()`, `list_pending_orders()`
- `record_sale()`
- `adjust_stock()`, `stock_ledger()`, `available_stock()`

### Reports (`reports.py`) - `ReportService`
- `run()` executes a report
- `export_csv()` writes a report to a CSV file
- `format_table()` formats rows as a text table

### Database (`db.py`) - `Database`
- `connect()`, `close()`
- `query()` for SELECT statements
- `execute()` for INSERT, UPDATE and CALL statements
- `transaction()` runs several statements as one unit

### Database Tables

| Table | Purpose |
|---|---|
| suppliers | Supplier details |
| product_categories | Product grouping |
| products | Items sold, prices, reorder level |
| warehouses | Storage locations |
| warehouse_stock | Current quantity per product and warehouse |
| purchase_orders | Orders placed with suppliers |
| purchase_items | Items on each purchase order |
| sales | Sales invoices |
| sales_items | Items on each sale |
| stock_transactions | Ledger of every stock movement |

### Database Automation

| Object | Responsibility |
|---|---|
| trigger `trg_txn_update_stock` | Updates current stock whenever a ledger entry is added |
| trigger `trg_po_item_total` | Updates the purchase order total |
| trigger `trg_sale_item_check` | Rejects a sale line if stock is insufficient |
| trigger `trg_sale_item_after` | Adds a SALE ledger entry and updates the sale total |
| procedure `sp_receive_po` | Marks an order Received and adds its items to stock |
| procedure `sp_adjust_stock` | Records manual stock corrections |

---

## 9. Data Persistence

The application stores all data permanently in a MySQL database named `inventory_db`.

The system:

- Connects to the database when the application starts.
- Reads and writes records through SQL queries.
- Commits changes after each successful operation.
- Rolls back changes if an operation fails.
- Keeps all data between application sessions.

Reports can also be saved as CSV files in the `reports/` folder.

---

## 10. Inventory Workflow

```
Supplier
   ↓
Create Purchase Order  (status: Ordered)
   ↓
Goods Arrive
   ↓
Receive Purchase Order
   ↓
Stock Ledger Entry (PURCHASE, +quantity)
   ↓
Current Stock Increases
   ↓
Customer Buys Product
   ↓
Stock Check
   ↓
Sale Recorded  →  Stock Ledger Entry (SALE, -quantity)
   ↓
Current Stock Decreases
   ↓
Stock at or below Reorder Level?  →  Low-Stock Alert
   ↓
Create New Purchase Order
```

### Purchase Order Creation
1. Choose a supplier and delivery warehouse.
2. Enter the order date (blank means today; future dates are rejected).
3. Add one or more products with quantity and unit cost.
4. The order is saved with status `Ordered` and its total is calculated.

### Receiving a Purchase Order
Before receiving, the system checks that:
- The purchase order exists.
- It is still in `Ordered` status.
- The received date is not before the order date.

Then each item is added to stock in the delivery warehouse and the status becomes `Received`.

### Recording a Sale
1. Choose the warehouse and date.
2. Enter products; available stock is displayed for each.
3. The sale header and all items are saved together.
4. If any item has insufficient stock, nothing is saved.

---

## 11. Stock Check and Alert Logic

### Sale Stock Check

```
Sale Item Entered
      ↓
Find stock of product in the selling warehouse
      ↓
Stock >= Quantity?
     /      \
   Yes       No
    ↓         ↓
 Accept    Reject sale
  item     "Insufficient stock"
    ↓
Ledger entry (negative quantity)
    ↓
Stock reduced
```

### Low-Stock Alert

```
Total stock of product (all warehouses)
      ↓
Total <= Reorder Level?
     /      \
   Yes       No
    ↓         ↓
 Alert      No alert
    ↓
Suggested order = (2 x reorder level) - total stock
```

Example:

```
Product       : Basmati Rice 5kg
Total stock   : 5
Reorder level : 20
Result        : LOW STOCK, suggested order = 35, supplier = Fresh Foods Ltd
```

### Product Movement Classification (last 90 days)

| Units sold | Class |
|---|---|
| 50 or more | FAST-MOVING |
| 20 to 49 | MEDIUM |
| Less than 20 | SLOW-MOVING |

---

## 12. Validation and Exception Handling

### Supplier Validation
- Name required
- Phone must have 7 to 15 digits
- Email format checked
- Duplicate email rejected

### Product Validation
- SKU required and unique
- Name required
- Category and supplier IDs must be positive numbers and must exist
- Cost price and selling price must be numeric and not negative
- Selling price cannot be lower than cost price
- Reorder level must be a whole number, 0 or more

### Purchase and Sale Validation
- Product must exist
- Quantity must be a whole number greater than 0
- Unit cost or price must be numeric and not negative
- Date must be `YYYY-MM-DD` and not in the future
- At least one item is required

### Stock Adjustment Validation
- Product and warehouse must exist
- Change must be a non-zero whole number
- A reason is required
- Stock can never become negative

### Exception Handling

The application defines its own exceptions:

| Exception | Meaning |
|---|---|
| `InventoryError` | Base class for all application errors |
| `ValidationError` | Invalid user input |
| `NotFoundError` | Record does not exist |
| `InsufficientStockError` | Not enough stock for a sale |
| `DatabaseError` | Connection or unexpected database problem |

Other handling:
- MySQL errors (duplicate value, missing reference, rule violation) are converted into clear messages.
- Every menu action catches `InventoryError`, shows the message and continues running.
- Transactions are rolled back automatically on failure.
- If MySQL is not running or the password is wrong, a clear start-up message is shown.
- File errors while exporting CSV are caught and reported.
- `Ctrl+C` exits cleanly.

---

## 13. Business Rules

1. A sale cannot exceed the stock in the selling warehouse.
2. Stock changes only through the ledger (purchase, sale, adjustment).
3. A purchase order adds stock only when it is received, and only once.
4. The received date cannot be before the order date.
5. A sale is all-or-nothing: if one item fails, the whole sale is cancelled.
6. SKUs, supplier emails, category names and warehouse names must be unique.
7. Selling price cannot be lower than cost price.
8. Quantities must be greater than zero; stock can never be negative.
9. A product is low on stock when total stock across warehouses is at or below its reorder level.
10. Fast, medium and slow classification is based on units sold in the last 90 days.
11. Every stock movement is recorded in the stock-transactions ledger.

---

## 14. Reports

### Available Reports

**1. Current Stock** - quantity and stock value of each product in each warehouse.

**2. Low-Stock Alerts** - products at or below reorder level, with supplier details and suggested order quantity.

**3. Supplier-wise Purchases** - number of orders, units ordered, total purchase value and orders received per supplier.

**4. Monthly Sales** - invoices, units sold, revenue and gross profit for each month.

**5. Fast-Moving Products** - products selling 50 or more units in the last 90 days.

**6. Slow-Moving Products** - products selling fewer than 20 units in the last 90 days.

Every report can be exported to `reports/<name>_<date>_<time>.csv`.

### Example

```
+---------+------------------+-----------+---------------+-----------+---------------------+
| sku     | product_name     | total_qty | reorder_level | alert     | suggested_order_qty |
+---------+------------------+-----------+---------------+-----------+---------------------+
| GRO-001 | Basmati Rice 5kg |         5 |            20 | LOW STOCK |                  35 |
| GRO-002 | Sunflower Oil 1L |         5 |            40 | LOW STOCK |                  75 |
| HOU-002 | Bath Soap        |        20 |            60 | LOW STOCK |                 100 |
+---------+------------------+-----------+---------------+-----------+---------------------+
```

---

## 15. How to Run the Project

### Requirements
- Python 3.9 or newer
- MySQL Server 8.0 or newer
- MySQL Workbench (optional)

### Step 1: Clone the Repository
```
git clone <your-repository-url>
```

### Step 2: Open the Project
Open the project folder in Visual Studio Code.

### Step 3: Install the Python Package
In the VS Code terminal (Terminal → New Terminal):
```
pip install -r requirements.txt
```

### Step 4: Load the Database (first time only)
Option A, MySQL Workbench: **File → Open SQL Script**, choose `inventory_management_system.sql`, and click the lightning-bolt button.

Option B, command line: log in to MySQL and run
```
source C:/path/to/inventory_management_system.sql
```
The script creates `inventory_db` with sample data. Running it again resets the data.

### Step 5: Run the Application
```
python main.py
```
Enter your MySQL password when asked.

Optional environment variables: `DB_HOST` (default `localhost`), `DB_USER` (default `root`), `DB_PASSWORD`, `DB_NAME` (default `inventory_db`).

### Step 6: Use the Main Menu
```
=========== INVENTORY MANAGEMENT SYSTEM ===========
 1. Master data (suppliers, categories, warehouses, products)
 2. Purchase orders
 3. Sales
 4. Stock (search, ledger, adjustment)
 5. Reports
 0. Exit
```
Select an option by entering its number.

### Sample Data Included
4 suppliers, 4 categories, 2 warehouses, 8 products, 5 purchase orders (4 received, 1 pending) and 6 sales.

---

## 16. Testing

### Automated Tests
```
python -m unittest discover tests -v
```
14 tests check validators, model rules, table formatting and CSV export. They do not need a database.

### Manual Test Cases

| # | Test | Steps | Expected Result | Result |
|---|---|---|---|---|
| 1 | Blank supplier name | Add supplier with empty name | "Name cannot be empty." and asks again | |
| 2 | Invalid email | Enter `abc` as email | "Email address is not valid." | |
| 3 | Invalid phone | Enter `12ab` as phone | "Phone must have 7-15 digits" | |
| 4 | Selling below cost | Add product cost 50, price 40 | "Selling price cannot be lower than cost price." | |
| 5 | Duplicate SKU | Add a product with an existing SKU | "A record with the same unique value already exists." | |
| 6 | Invalid quantity | Enter `abc`, `0`, `-3` as quantity | Rejected and asks again | |
| 7 | Future date | Enter a future sale date | "Sale date cannot be in the future." | |
| 8 | Create purchase order | Menu 2 → 1 with valid data | Order created with status Ordered | |
| 9 | Receive purchase order | Menu 2 → 2, PO 5 | Sunflower Oil stock rises from 5 to 65 | |
| 10 | Receive twice | Receive PO 5 again | "Purchase order 5 is already Received." | |
| 11 | Valid sale | Sell 2 Detergent from warehouse 2 | Sale recorded; stock decreases by 2 | |
| 12 | Overselling | Sell 999 Basmati Rice | "Sale not recorded: Insufficient stock..."; no empty sale left | |
| 13 | Low-stock alert | Report 2 | Rice, Oil and Bath Soap listed | |
| 14 | Alert clears | Receive PO 5, run report 2 | Sunflower Oil no longer listed | |
| 15 | Search filter | Menu 4 → 1, low stock only = y | Only low-stock products shown | |
| 16 | Stock ledger | Menu 4 → 2, product 2 | Purchases and sales listed in date order | |
| 17 | Stock adjustment | Menu 4 → 3, change -3 with reason | Stock reduces; ADJUSTMENT row in ledger | |
| 18 | CSV export | Run a report and answer `y` | File created in `reports/` | |
| 19 | Wrong password | Start with a wrong password | Clear "Could not connect" message, no crash | |
| 20 | Invalid menu choice | Enter `9` in the main menu | "Invalid choice." and menu shown again | |

_The Result column is for the team to fill in (PASS / FAIL) after running each test._

---

## 17. Sample Error Handling

The application displays clear messages for invalid operations.

Examples:

- Name cannot be empty.
- Email address is not valid.
- Quantity must be greater than 0.
- Sale date cannot be in the future.
- Selling price cannot be lower than cost price.
- A record with the same unique value already exists.
- Product 99 not found.
- Purchase order 5 is already Received.
- Received date cannot be before the order date.
- Sale not recorded: Insufficient stock in warehouse for this sale.
- Could not connect to MySQL.
- Invalid choice.

These validations prevent incorrect data from being stored.

---

## 18. Future Enhancements

- Graphical or web-based interface
- User login and role-based access
- Barcode scanning
- Stock transfer between warehouses
- Sales and purchase returns
- Automatic purchase order creation for low-stock items
- Email or SMS alerts
- Expiry-date tracking for perishable goods
- Export reports to PDF or Excel
- Charts and dashboards
- Cloud deployment

---

## 19. Conclusion

The Inventory Management System provides a structured way to manage suppliers, products, purchases, sales and stock.

The project demonstrates practical use of:

- Object-Oriented Programming
- Functions
- Lists and dictionaries
- Database programming with MySQL
- Transactions
- Regular expressions
- Date and time handling
- File handling (CSV export)
- Exception handling
- Input validation
- Unit testing

Database triggers keep stock accurate, the stock check prevents overselling, and low-stock alerts help the business reorder before products run out. The reports give the owner a clear view of stock, purchases, sales and product movement.

---

## 20. Project Status

**Development Status: COMPLETED**

### Completed Components
- Supplier, category, warehouse and product management
- Purchase order creation and receiving
- Sales recording
- Automatic stock updates
- Oversell protection
- Stock ledger and manual adjustments
- Product search and filter
- Low-stock alerts
- Six reports with CSV export
- Input validation
- Exception handling
- Automated unit tests
- Project documentation

---

## 21. Screenshots

_Add screenshots to a `screenshots/` folder and keep the lines below._

### 1. Main Menu
![Main Menu](screenshots/main_menu.png)

### 2. Master Data Management
![Master Data](screenshots/master_data.png)

### 3. Purchase Orders
![Purchase Orders](screenshots/purchase_orders.png)

### 4. Sales
![Sales](screenshots/sales.png)

### 5. Low-Stock Alerts
![Low Stock Alerts](screenshots/low_stock.png)

### 6. Reports
![Reports](screenshots/reports.png)

### 7. Validation and Blocked Sale
![Validation](screenshots/validation.png)

### 8. Stock Ledger
![Stock Ledger](screenshots/stock_ledger.png)

---

## Team Members

| Name | Role | Contribution |
|---|---|---|
| _Member 1_ | Team Lead | _Database design, SQL script, integration and final testing_ |
| _Member 2_ | Developer | _Models, validators, master data and purchase management_ |
| _Member 3_ | Developer | _Sales, stock management, reports, CSV export and documentation_ |

_Replace the placeholders with your real names, roles and contributions._

---

## Repository

GitHub Repository: `<add your repository link here>`

---

**INVENTORY MANAGEMENT SYSTEM - Python Console Application with MySQL Database**
