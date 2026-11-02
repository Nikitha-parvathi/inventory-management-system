"""Web dashboard for the Inventory Management System.

Run with:  streamlit run dashboard.py
"""
import os
from datetime import date
from decimal import Decimal

import pandas as pd
import streamlit as st

from inventory.db import Database
from inventory.exceptions import InventoryError
from inventory.models import LineItem
from inventory.reports import REPORTS
from inventory.services import InventoryService

st.set_page_config(page_title="Inventory Dashboard", page_icon="📦", layout="wide")


# ---------------------------------------------------------------- helpers
def to_df(rows) -> pd.DataFrame:
    """List of dict rows -> DataFrame, turning Decimal columns into numbers."""
    df = pd.DataFrame(rows)
    for col in df.columns:
        values = df[col].dropna()
        if not values.empty and isinstance(values.iloc[0], Decimal):
            df[col] = pd.to_numeric(df[col])
    return df


def scalar(db, sql):
    rows = db.query(sql)
    return rows[0]["n"] if rows and rows[0]["n"] is not None else 0


def show_table(rows, empty_message="No records."):
    if rows:
        st.dataframe(to_df(rows), width="stretch", hide_index=True)
    else:
        st.info(empty_message)


@st.cache_resource
def get_db(password: str) -> Database:
    db = Database(os.getenv("DB_HOST", "localhost"), os.getenv("DB_USER", "root"),
                  password, os.getenv("DB_NAME", "inventory_db"))
    db.connect()
    return db


def cart_widget(svc, key, kind):
    """Add-line-items form. Returns the list of LineItem objects in the cart."""
    cart = st.session_state.setdefault(key, [])
    products = {f"{p['sku']} - {p['product_name']}": p for p in svc.search_products()}
    price_label = "Unit cost (0 = default)" if kind == "purchase" else "Unit price (0 = default)"
    with st.form(f"{key}_form", clear_on_submit=True):
        c1, c2, c3 = st.columns([3, 1, 1])
        label = c1.selectbox("Product", list(products))
        qty = c2.number_input("Quantity", min_value=1, step=1, value=1)
        amount = c3.number_input(price_label, min_value=0.0, step=1.0, value=0.0)
        if st.form_submit_button("➕ Add item"):
            product = svc.get_product(products[label]["product_id"])
            default = product["cost_price"] if kind == "purchase" else product["selling_price"]
            cart.append({"product_id": product["product_id"], "product": product["product_name"],
                         "quantity": int(qty),
                         "unit_amount": Decimal(str(amount)) if amount > 0 else default})
    if cart:
        table = pd.DataFrame(cart)
        table["line_total"] = table["quantity"] * table["unit_amount"].astype(float)
        st.dataframe(table.drop(columns="product_id"), width="stretch", hide_index=True)
        st.write(f"**Total: {table['line_total'].sum():,.2f}**")
        if st.button("🗑 Clear items", key=f"{key}_clear"):
            cart.clear()
            st.rerun()
    return [LineItem(i["product_id"], i["quantity"], i["unit_amount"]) for i in cart]


# ---------------------------------------------------------------- pages
def page_dashboard(db, svc):
    st.title("📦 Inventory Dashboard")

    c1, c2, c3, c4, c5 = st.columns(5)
    c1.metric("Active products", scalar(db, "SELECT COUNT(*) AS n FROM products WHERE is_active = TRUE"))
    c2.metric("Stock value", f"{float(scalar(db, 'SELECT SUM(stock_value) AS n FROM v_total_stock')):,.0f}")
    c3.metric("Low-stock items", scalar(db, "SELECT COUNT(*) AS n FROM v_low_stock_alerts"))
    c4.metric("Total sales revenue", f"{float(scalar(db, 'SELECT SUM(revenue) AS n FROM v_monthly_sales')):,.0f}")
    c5.metric("Pending purchase orders",
              scalar(db, "SELECT COUNT(*) AS n FROM purchase_orders WHERE status = 'Ordered'"))

    st.divider()
    left, right = st.columns(2)
    with left:
        st.subheader("Monthly revenue and profit")
        sales = to_df(db.query("SELECT * FROM v_monthly_sales ORDER BY sales_month"))
        if sales.empty:
            st.info("No sales yet.")
        else:
            st.bar_chart(sales.set_index("sales_month")[["revenue", "gross_profit"]])
    with right:
        st.subheader("Stock value by category")
        cat = to_df(db.query("SELECT category_name, SUM(stock_value) AS stock_value "
                             "FROM v_current_stock GROUP BY category_name ORDER BY category_name"))
        if cat.empty:
            st.info("No stock yet.")
        else:
            st.bar_chart(cat.set_index("category_name"))

    left, right = st.columns(2)
    with left:
        st.subheader("Stock level vs reorder level")
        stock = to_df(db.query("SELECT product_name, total_qty, reorder_level FROM v_total_stock ORDER BY product_name"))
        if not stock.empty:
            st.bar_chart(stock.set_index("product_name"))
    with right:
        st.subheader("Units sold in last 90 days")
        move = to_df(db.query("SELECT sku, product_name, units_sold_90d, current_stock, movement_class "
                              "FROM v_product_movement ORDER BY units_sold_90d DESC"))
        if not move.empty:
            st.bar_chart(move.set_index("product_name")[["units_sold_90d"]])

    st.divider()
    st.subheader("🚨 Low-stock alerts")
    alerts = db.query("SELECT * FROM v_low_stock_alerts ORDER BY total_qty")
    if alerts:
        st.dataframe(to_df(alerts), width="stretch", hide_index=True)
    else:
        st.success("All products are above their reorder level.")

    st.subheader("Fast / medium / slow-moving products")
    if not move.empty:
        st.dataframe(move, width="stretch", hide_index=True)


def page_stock(db, svc):
    st.title("📋 Stock")
    tab1, tab2, tab3, tab4 = st.tabs(["Products", "By warehouse", "Ledger", "Adjust stock"])
    with tab1:
        c1, c2 = st.columns([3, 1])
        keyword = c1.text_input("Search name or SKU")
        low = c2.checkbox("Low stock only")
        show_table(svc.search_products(keyword or None, None, None, low), "No matching products.")
    with tab2:
        show_table(db.query("SELECT * FROM v_current_stock ORDER BY warehouse_name, product_name"))
    with tab3:
        products = {f"{p['sku']} - {p['product_name']}": p["product_id"] for p in svc.search_products()}
        choice = st.selectbox("Product", list(products), key="ledger_product")
        show_table(svc.stock_ledger(products[choice]), "No movements for this product.")
    with tab4:
        products = {f"{p['sku']} - {p['product_name']}": p["product_id"] for p in svc.search_products()}
        warehouses = {w["warehouse_name"]: w["warehouse_id"] for w in svc.list_warehouses()}
        with st.form("adjust_form"):
            product = st.selectbox("Product", list(products))
            warehouse = st.selectbox("Warehouse", list(warehouses))
            change = st.number_input("Change (+ add / - remove)", step=1, value=0)
            reason = st.text_input("Reason (required)")
            if st.form_submit_button("Apply adjustment"):
                try:
                    if not reason.strip():
                        raise InventoryError("A reason is required.")
                    svc.adjust_stock(products[product], warehouses[warehouse], int(change), reason.strip())
                    st.success("Stock adjusted.")
                except InventoryError as err:
                    st.error(str(err))


def page_sales(db, svc):
    st.title("🧾 Record a sale")
    warehouses = {w["warehouse_name"]: w["warehouse_id"] for w in svc.list_warehouses()}
    c1, c2, c3 = st.columns(3)
    warehouse = c1.selectbox("Sell from warehouse", list(warehouses))
    customer = c2.text_input("Customer", value="Walk-in")
    sale_date = c3.date_input("Date", value=date.today(), max_value=date.today())
    try:
        items = cart_widget(svc, "sale_cart", "sale")
        if st.button("✅ Record sale", type="primary", disabled=not items):
            sale_id = svc.record_sale(warehouses[warehouse], sale_date, customer.strip() or "Walk-in", items)
            st.session_state["sale_cart"] = []
            st.success(f"Sale {sale_id} recorded. Total: {sum(i.total() for i in items):,.2f}")
    except InventoryError as err:
        st.error(f"Sale not recorded: {err}")
    st.subheader("Recent sales")
    show_table(db.query("SELECT s.sale_id, s.sale_date, w.warehouse_name, s.customer_name, s.total_amount "
                        "FROM sales s JOIN warehouses w ON w.warehouse_id = s.warehouse_id "
                        "ORDER BY s.sale_id DESC LIMIT 10"))


def page_purchases(db, svc):
    st.title("🚚 Purchase orders")
    tab1, tab2 = st.tabs(["Receive orders", "Create order"])
    with tab1:
        pending = svc.list_pending_orders()
        show_table(pending, "No pending purchase orders.")
        if pending:
            c1, c2 = st.columns(2)
            po_id = c1.selectbox("Purchase order to receive", [p["po_id"] for p in pending])
            received = c2.date_input("Received date", value=date.today(), max_value=date.today())
            if st.button("📥 Receive into stock", type="primary"):
                try:
                    svc.receive_purchase_order(int(po_id), received)
                    st.success(f"Purchase order {po_id} received. Stock updated.")
                    st.rerun()
                except InventoryError as err:
                    st.error(str(err))
    with tab2:
        suppliers = {s["supplier_name"]: s["supplier_id"] for s in svc.list_suppliers()}
        warehouses = {w["warehouse_name"]: w["warehouse_id"] for w in svc.list_warehouses()}
        c1, c2, c3 = st.columns(3)
        supplier = c1.selectbox("Supplier", list(suppliers))
        warehouse = c2.selectbox("Deliver to", list(warehouses))
        order_date = c3.date_input("Order date", value=date.today(), max_value=date.today())
        try:
            items = cart_widget(svc, "po_cart", "purchase")
            if st.button("✅ Create purchase order", type="primary", disabled=not items):
                po_id = svc.create_purchase_order(suppliers[supplier], warehouses[warehouse], order_date, items)
                st.session_state["po_cart"] = []
                st.success(f"Purchase order {po_id} created (status: Ordered).")
        except InventoryError as err:
            st.error(str(err))


def page_reports(db, svc):
    st.title("📊 Reports")
    titles = {title: (slug, sql) for slug, title, sql in REPORTS.values()}
    choice = st.selectbox("Choose a report", list(titles))
    slug, sql = titles[choice]
    rows = db.query(sql)
    show_table(rows, "This report has no data.")
    if rows:
        st.download_button("⬇ Download CSV", to_df(rows).to_csv(index=False),
                           file_name=f"{slug}.csv", mime="text/csv")


PAGES = {"🏠 Dashboard": page_dashboard, "📋 Stock": page_stock, "🧾 Sales": page_sales,
         "🚚 Purchases": page_purchases, "📊 Reports": page_reports}


# ---------------------------------------------------------------- main
def main():
    st.sidebar.title("Inventory System")
    password = os.getenv("DB_PASSWORD") or st.sidebar.text_input("MySQL password", type="password")
    if not password:
        st.title("📦 Inventory Dashboard")
        st.info("Enter your MySQL password in the sidebar to connect.")
        return
    try:
        db = get_db(password)
        db.ensure_connected()
    except InventoryError as err:
        get_db.clear()
        st.error(f"{err}. Check that MySQL is running, the password is right and the SQL script is loaded.")
        return
    page = st.sidebar.radio("Go to", list(PAGES))
    if st.sidebar.button("🔄 Refresh data"):
        st.rerun()
    svc = InventoryService(db)
    try:
        PAGES[page](db, svc)
    except InventoryError as err:
        st.error(str(err))


main()
