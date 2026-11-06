"""Report queries, table formatting and CSV export."""
import csv
import os
from datetime import datetime

from .exceptions import InventoryError

REPORTS = {
    "1": ("current_stock", "Current Stock Report (per warehouse)",
          "SELECT * FROM v_current_stock ORDER BY warehouse_name, product_name"),
    "2": ("low_stock", "Low-Stock Alerts",
          "SELECT * FROM v_low_stock_alerts ORDER BY total_qty"),
    "3": ("supplier_purchases", "Supplier-wise Purchase Report",
          "SELECT * FROM v_supplier_purchases ORDER BY total_purchase_value DESC"),
    "4": ("monthly_sales", "Monthly Sales Report",
          "SELECT * FROM v_monthly_sales ORDER BY sales_month"),
    "5": ("fast_moving", "Fast-Moving Products (last 90 days)",
          "SELECT * FROM v_product_movement WHERE movement_class='FAST-MOVING' "
          "ORDER BY units_sold_90d DESC"),
    "6": ("slow_moving", "Slow-Moving Products (last 90 days)",
          "SELECT * FROM v_product_movement WHERE movement_class='SLOW-MOVING' "
          "ORDER BY units_sold_90d"),
}


def format_table(headers, rows) -> str:
    """Plain-text table. `rows` is a list of sequences."""
    if not rows:
        return "(no records)"
    text_rows = [["" if c is None else str(c) for c in r] for r in rows]
    widths = [max(len(str(h)), *(len(r[i]) for r in text_rows)) for i, h in enumerate(headers)]
    sep = "+" + "+".join("-" * (w + 2) for w in widths) + "+"
    line = lambda cells: "| " + " | ".join(str(c).ljust(w) for c, w in zip(cells, widths)) + " |"
    out = [sep, line(headers), sep] + [line(r) for r in text_rows] + [sep]
    return "\n".join(out)


def dicts_to_table(rows) -> str:
    if not rows:
        return "(no records)"
    headers = list(rows[0].keys())
    return format_table(headers, [[r[h] for h in headers] for r in rows])


class ReportService:
    def __init__(self, db):
        self.db = db

    def run(self, key: str):
        """Return (slug, title, rows) for report number `key`."""
        if key not in REPORTS:
            raise InventoryError("Unknown report.")
        slug, title, sql = REPORTS[key]
        return slug, title, self.db.query(sql)

    @staticmethod
    def export_csv(slug: str, rows, folder: str = "reports") -> str:
        if not rows:
            raise InventoryError("Nothing to export: the report is empty.")
        os.makedirs(folder, exist_ok=True)
        path = os.path.join(folder, f"{slug}_{datetime.now():%Y%m%d_%H%M%S}.csv")
        try:
            with open(path, "w", newline="", encoding="utf-8") as fh:
                writer = csv.DictWriter(fh, fieldnames=list(rows[0].keys()))
                writer.writeheader()
                writer.writerows(rows)
        except OSError as err:
            raise InventoryError(f"Could not write file: {err}") from err
        return path
