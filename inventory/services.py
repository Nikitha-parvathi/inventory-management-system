"""Business logic: master data, purchases, sales, stock and search."""
from datetime import date
from typing import List, Optional

from .exceptions import InventoryError, NotFoundError, ValidationError
from .models import Category, LineItem, Product, Supplier, Warehouse


class InventoryService:
    def __init__(self, db):
        self.db = db

    # ---------- master data ----------
    def add_supplier(self, s: Supplier) -> int:
        return self.db.execute(
            "INSERT INTO suppliers (supplier_name, contact_person, phone, email, address) "
            "VALUES (%s,%s,%s,%s,%s)",
            (s.supplier_name, s.contact_person, s.phone, s.email, s.address))

    def add_category(self, c: Category) -> int:
        return self.db.execute(
            "INSERT INTO product_categories (category_name, description) VALUES (%s,%s)",
            (c.category_name, c.description))

    def add_warehouse(self, w: Warehouse) -> int:
        return self.db.execute(
            "INSERT INTO warehouses (warehouse_name, location) VALUES (%s,%s)",
            (w.warehouse_name, w.location))

    def add_product(self, p: Product) -> int:
        return self.db.execute(
            "INSERT INTO products (sku, product_name, category_id, supplier_id, "
            "cost_price, selling_price, reorder_level) VALUES (%s,%s,%s,%s,%s,%s,%s)",
            (p.sku, p.product_name, p.category_id, p.supplier_id,
             p.cost_price, p.selling_price, p.reorder_level))

    def list_suppliers(self):
        return self.db.query("SELECT supplier_id, supplier_name, phone, email FROM suppliers ORDER BY supplier_id")

    def list_categories(self):
        return self.db.query("SELECT category_id, category_name FROM product_categories ORDER BY category_id")

    def list_warehouses(self):
        return self.db.query("SELECT warehouse_id, warehouse_name, location FROM warehouses ORDER BY warehouse_id")

    def get_product(self, product_id: int) -> dict:
        rows = self.db.query(
            "SELECT product_id, sku, product_name, cost_price, selling_price, reorder_level "
            "FROM products WHERE product_id=%s AND is_active=TRUE", (product_id,))
        if not rows:
            raise NotFoundError(f"Product {product_id} not found.")
        return rows[0]

    def available_stock(self, product_id: int, warehouse_id: int) -> int:
        rows = self.db.query(
            "SELECT quantity FROM warehouse_stock WHERE product_id=%s AND warehouse_id=%s",
            (product_id, warehouse_id))
        return int(rows[0]["quantity"]) if rows else 0

    # ---------- search / filter ----------
    def search_products(self, keyword: Optional[str] = None, category_id: Optional[int] = None,
                        supplier_id: Optional[int] = None, low_stock_only: bool = False):
        sql = ("SELECT p.product_id, p.sku, p.product_name, c.category_name, s.supplier_name, "
               "p.selling_price, COALESCE(SUM(ws.quantity),0) AS stock, p.reorder_level "
               "FROM products p "
               "JOIN product_categories c ON c.category_id = p.category_id "
               "JOIN suppliers s ON s.supplier_id = p.supplier_id "
               "LEFT JOIN warehouse_stock ws ON ws.product_id = p.product_id "
               "WHERE p.is_active = TRUE")
        params: list = []
        if keyword:
            sql += " AND (p.product_name LIKE %s OR p.sku LIKE %s)"
            params += [f"%{keyword}%", f"%{keyword}%"]
        if category_id:
            sql += " AND p.category_id = %s"
            params.append(category_id)
        if supplier_id:
            sql += " AND p.supplier_id = %s"
            params.append(supplier_id)
        sql += (" GROUP BY p.product_id, p.sku, p.product_name, c.category_name, "
                "s.supplier_name, p.selling_price, p.reorder_level")
        if low_stock_only:
            sql += " HAVING COALESCE(SUM(ws.quantity),0) <= p.reorder_level"
        sql += " ORDER BY p.product_name"
        return self.db.query(sql, params)

    # ---------- purchases ----------
    def create_purchase_order(self, supplier_id: int, warehouse_id: int,
                              order_date: date, items: List[LineItem]) -> int:
        if not items:
            raise ValidationError("A purchase order needs at least one item.")
        with self.db.transaction():
            po_id = self.db.execute(
                "INSERT INTO purchase_orders (supplier_id, warehouse_id, order_date) VALUES (%s,%s,%s)",
                (supplier_id, warehouse_id, order_date))
            for it in items:
                self.db.execute(
                    "INSERT INTO purchase_items (po_id, product_id, quantity, unit_cost) VALUES (%s,%s,%s,%s)",
                    (po_id, it.product_id, it.quantity, it.unit_amount))
        return po_id

    def list_pending_orders(self):
        return self.db.query(
            "SELECT po.po_id, s.supplier_name, w.warehouse_name, po.order_date, po.total_amount "
            "FROM purchase_orders po JOIN suppliers s ON s.supplier_id = po.supplier_id "
            "JOIN warehouses w ON w.warehouse_id = po.warehouse_id "
            "WHERE po.status = 'Ordered' ORDER BY po.po_id")

    def receive_purchase_order(self, po_id: int, received_date: date) -> None:
        rows = self.db.query(
            "SELECT status, order_date FROM purchase_orders WHERE po_id=%s", (po_id,))
        if not rows:
            raise NotFoundError(f"Purchase order {po_id} not found.")
        if rows[0]["status"] != "Ordered":
            raise InventoryError(f"Purchase order {po_id} is already {rows[0]['status']}.")
        if received_date < rows[0]["order_date"]:
            raise ValidationError("Received date cannot be before the order date.")
        self.db.execute("CALL sp_receive_po(%s, %s)", (po_id, received_date))

    # ---------- sales ----------
    def record_sale(self, warehouse_id: int, sale_date: date, customer: str,
                    items: List[LineItem]) -> int:
        """Header and items are one transaction: a failed item leaves no empty sale behind."""
        if not items:
            raise ValidationError("A sale needs at least one item.")
        with self.db.transaction():
            sale_id = self.db.execute(
                "INSERT INTO sales (sale_date, warehouse_id, customer_name) VALUES (%s,%s,%s)",
                (sale_date, warehouse_id, customer or "Walk-in"))
            for it in items:
                self.db.execute(
                    "INSERT INTO sales_items (sale_id, product_id, quantity, unit_price) VALUES (%s,%s,%s,%s)",
                    (sale_id, it.product_id, it.quantity, it.unit_amount))
        return sale_id

    # ---------- stock ----------
    def adjust_stock(self, product_id: int, warehouse_id: int, change: int, remarks: str) -> None:
        if change == 0:
            raise ValidationError("Adjustment cannot be zero.")
        self.db.execute("CALL sp_adjust_stock(%s,%s,%s,%s)",
                        (product_id, warehouse_id, change, remarks))

    def stock_ledger(self, product_id: int):
        return self.db.query(
            "SELECT txn_date, txn_type, quantity_change, reference_type, reference_id, remarks "
            "FROM stock_transactions WHERE product_id=%s ORDER BY txn_date, txn_id", (product_id,))
