"""Menu-driven command-line interface."""
import getpass
import os

from . import validators as v
from .db import Database
from .exceptions import InventoryError
from .models import Category, LineItem, Product, Supplier, Warehouse
from .reports import REPORTS, ReportService, dicts_to_table
from .services import InventoryService

MAIN_MENU = """
=========== INVENTORY MANAGEMENT SYSTEM ===========
 1. Master data (suppliers, categories, warehouses, products)
 2. Purchase orders
 3. Sales
 4. Stock (search, ledger, adjustment)
 5. Reports
 0. Exit
"""

MASTER_MENU = """
-- Master data --
 1. Add supplier      2. Add category     3. Add warehouse     4. Add product
 5. List suppliers    6. List categories  7. List warehouses   0. Back
"""

PURCHASE_MENU = """
-- Purchase orders --
 1. Create purchase order   2. Receive purchase order   3. List pending orders   0. Back
"""

STOCK_MENU = """
-- Stock --
 1. Search / filter products   2. Stock ledger for a product   3. Manual stock adjustment   0. Back
"""


def ask(prompt, parser=lambda x: x, default=None):
    """Keep asking until the parser accepts the input."""
    while True:
        raw = input(f"{prompt}{f' [{default}]' if default is not None else ''}: ").strip()
        if not raw and default is not None:
            raw = str(default)
        try:
            return parser(raw)
        except InventoryError as err:
            print(f"  ! {err}")


def show(rows):
    print(dicts_to_table(rows))


def ask_items(svc, kind, warehouse_id=None):
    """Collect line items; blank product ID finishes. kind: 'purchase' or 'sale'."""
    items = []
    while True:
        raw = input("Product ID (blank to finish): ").strip()
        if not raw:
            break
        try:
            pid = v.positive_int(raw, "Product ID")
            product = svc.get_product(pid)
        except InventoryError as err:
            print(f"  ! {err}")
            continue
        print(f"  {product['product_name']}")
        if kind == "sale":
            print(f"  Available in this warehouse: {svc.available_stock(pid, warehouse_id)}")
        default = product["cost_price"] if kind == "purchase" else product["selling_price"]
        qty = ask("  Quantity", lambda x: v.positive_int(x, "Quantity"))
        amount = ask("  Unit cost" if kind == "purchase" else "  Unit price",
                     lambda x: v.non_negative_decimal(x, "Amount"), default)
        items.append(LineItem(pid, qty, amount))
    return items


# ---------------- menu handlers ----------------
def master_menu(svc):
    while True:
        print(MASTER_MENU)
        choice = input("Choice: ").strip()
        try:
            if choice == "1":
                s = Supplier(ask("Name", lambda x: v.required_text(x, "Name")),
                             ask("Contact person (optional)"),
                             ask("Phone (optional)", v.valid_phone),
                             ask("Email (optional)", v.valid_email),
                             ask("Address (optional)"))
                print(f"Supplier added with ID {svc.add_supplier(s)}.")
            elif choice == "2":
                c = Category(ask("Category name", lambda x: v.required_text(x, "Name", 80)),
                             ask("Description (optional)"))
                print(f"Category added with ID {svc.add_category(c)}.")
            elif choice == "3":
                w = Warehouse(ask("Warehouse name", lambda x: v.required_text(x, "Name", 80)),
                              ask("Location (optional)"))
                print(f"Warehouse added with ID {svc.add_warehouse(w)}.")
            elif choice == "4":
                p = Product(ask("SKU", lambda x: v.required_text(x, "SKU", 30)),
                            ask("Product name", lambda x: v.required_text(x, "Name", 120)),
                            ask("Category ID", lambda x: v.positive_int(x, "Category ID")),
                            ask("Supplier ID", lambda x: v.positive_int(x, "Supplier ID")),
                            ask("Cost price", lambda x: v.non_negative_decimal(x, "Cost price")),
                            ask("Selling price", lambda x: v.non_negative_decimal(x, "Selling price")),
                            ask("Reorder level", lambda x: v.non_negative_int(x, "Reorder level"), 10))
                print(f"Product added with ID {svc.add_product(p)}. Margin per unit: {p.margin()}")
            elif choice == "5":
                show(svc.list_suppliers())
            elif choice == "6":
                show(svc.list_categories())
            elif choice == "7":
                show(svc.list_warehouses())
            elif choice == "0":
                return
            else:
                print("Invalid choice.")
        except InventoryError as err:
            print(f"Error: {err}")


def purchase_menu(svc):
    while True:
        print(PURCHASE_MENU)
        choice = input("Choice: ").strip()
        try:
            if choice == "1":
                show(svc.list_suppliers())
                supplier = ask("Supplier ID", lambda x: v.positive_int(x, "Supplier ID"))
                show(svc.list_warehouses())
                warehouse = ask("Delivery warehouse ID", lambda x: v.positive_int(x, "Warehouse ID"))
                order_date = ask("Order date YYYY-MM-DD (blank = today)", lambda x: v.parse_date(x, "Order date"))
                items = ask_items(svc, "purchase")
                po_id = svc.create_purchase_order(supplier, warehouse, order_date, items)
                print(f"Purchase order {po_id} created (status: Ordered).")
            elif choice == "2":
                show(svc.list_pending_orders())
                po_id = ask("PO ID to receive", lambda x: v.positive_int(x, "PO ID"))
                received = ask("Received date YYYY-MM-DD (blank = today)", lambda x: v.parse_date(x, "Received date"))
                svc.receive_purchase_order(po_id, received)
                print(f"Purchase order {po_id} received. Stock updated.")
            elif choice == "3":
                show(svc.list_pending_orders())
            elif choice == "0":
                return
            else:
                print("Invalid choice.")
        except InventoryError as err:
            print(f"Error: {err}")


def sales_menu(svc):
    try:
        show(svc.list_warehouses())
        warehouse = ask("Sell from warehouse ID", lambda x: v.positive_int(x, "Warehouse ID"))
        sale_date = ask("Sale date YYYY-MM-DD (blank = today)", lambda x: v.parse_date(x, "Sale date"))
        customer = ask("Customer name (blank = Walk-in)", lambda x: v.optional_text(x, "Customer", 100) or "Walk-in")
        items = ask_items(svc, "sale", warehouse)
        sale_id = svc.record_sale(warehouse, sale_date, customer, items)
        total = sum(i.total() for i in items)
        print(f"Sale {sale_id} recorded. Total: {total}")
    except InventoryError as err:
        print(f"Sale not recorded: {err}")


def stock_menu(svc):
    while True:
        print(STOCK_MENU)
        choice = input("Choice: ").strip()
        try:
            if choice == "1":
                keyword = input("Name/SKU contains (blank = any): ").strip() or None
                cat = input("Category ID (blank = any): ").strip()
                sup = input("Supplier ID (blank = any): ").strip()
                low = input("Only low stock? (y/N): ").strip().lower() == "y"
                show(svc.search_products(keyword,
                                         v.positive_int(cat, "Category ID") if cat else None,
                                         v.positive_int(sup, "Supplier ID") if sup else None,
                                         low))
            elif choice == "2":
                pid = ask("Product ID", lambda x: v.positive_int(x, "Product ID"))
                svc.get_product(pid)
                show(svc.stock_ledger(pid))
            elif choice == "3":
                pid = ask("Product ID", lambda x: v.positive_int(x, "Product ID"))
                svc.get_product(pid)
                wh = ask("Warehouse ID", lambda x: v.positive_int(x, "Warehouse ID"))
                print(f"Current stock there: {svc.available_stock(pid, wh)}")
                change = ask("Change (+ add / - remove)", lambda x: _signed_int(x))
                remarks = ask("Reason", lambda x: v.required_text(x, "Reason", 255))
                svc.adjust_stock(pid, wh, change, remarks)
                print("Stock adjusted.")
            elif choice == "0":
                return
            else:
                print("Invalid choice.")
        except InventoryError as err:
            print(f"Error: {err}")


def _signed_int(text):
    try:
        return int(text.strip())
    except ValueError:
        raise v.ValidationError("Enter a whole number such as 10 or -3.") from None


def report_menu(reports):
    while True:
        print("\n-- Reports --")
        for key, (_, title, _) in REPORTS.items():
            print(f" {key}. {title}")
        print(" 0. Back")
        choice = input("Choice: ").strip()
        if choice == "0":
            return
        try:
            slug, title, rows = reports.run(choice)
        except InventoryError as err:
            print(f"Error: {err}")
            continue
        print(f"\n{title}")
        show(rows)
        if rows and input("Export to CSV? (y/N): ").strip().lower() == "y":
            try:
                print(f"Saved: {reports.export_csv(slug, rows)}")
            except InventoryError as err:
                print(f"Error: {err}")


def connect():
    password = os.getenv("DB_PASSWORD") or getpass.getpass("MySQL password: ")
    db = Database(os.getenv("DB_HOST", "localhost"), os.getenv("DB_USER", "root"),
                  password, os.getenv("DB_NAME", "inventory_db"))
    db.connect()
    return db


def run():
    try:
        db = connect()
    except InventoryError as err:
        print(f"Startup failed: {err}")
        print("Check that MySQL is running, the password is right and the SQL script has been loaded.")
        return
    svc, reports = InventoryService(db), ReportService(db)
    handlers = {"1": master_menu, "2": purchase_menu, "3": sales_menu, "4": stock_menu}
    try:
        while True:
            print(MAIN_MENU)
            choice = input("Choice: ").strip()
            if choice == "0":
                print("Goodbye.")
                break
            elif choice == "5":
                report_menu(reports)
            elif choice in handlers:
                handlers[choice](svc)
            else:
                print("Invalid choice.")
    except (KeyboardInterrupt, EOFError):
        print("\nExiting.")
    finally:
        db.close()
