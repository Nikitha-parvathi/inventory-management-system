"""Unit tests that need no database:  python -m unittest discover tests -v"""
import os
import tempfile
import unittest
from datetime import date, timedelta
from decimal import Decimal

from inventory import validators as v
from inventory.exceptions import InventoryError, ValidationError
from inventory.models import LineItem, Product, Supplier
from inventory.reports import ReportService, format_table


class ValidatorTests(unittest.TestCase):
    def test_required_text_rejects_blank(self):
        with self.assertRaises(ValidationError):
            v.required_text("   ", "Name")

    def test_positive_int(self):
        self.assertEqual(v.positive_int(" 5 ", "Qty"), 5)
        for bad in ("0", "-2", "abc", "2.5", ""):
            with self.assertRaises(ValidationError):
                v.positive_int(bad, "Qty")

    def test_non_negative_decimal(self):
        self.assertEqual(v.non_negative_decimal("12.5", "Price"), Decimal("12.50"))
        for bad in ("-1", "x", "NaN"):
            with self.assertRaises(ValidationError):
                v.non_negative_decimal(bad, "Price")

    def test_parse_date(self):
        self.assertEqual(v.parse_date("2026-08-04"), date(2026, 8, 4))
        self.assertEqual(v.parse_date(""), date.today())
        with self.assertRaises(ValidationError):
            v.parse_date("04/08/2026")
        with self.assertRaises(ValidationError):
            v.parse_date((date.today() + timedelta(days=3)).isoformat())

    def test_email_and_phone(self):
        self.assertEqual(v.valid_email("A@B.com"), "a@b.com")
        self.assertIsNone(v.valid_email(""))
        with self.assertRaises(ValidationError):
            v.valid_email("not-an-email")
        self.assertEqual(v.valid_phone("98100-00001"), "9810000001")
        with self.assertRaises(ValidationError):
            v.valid_phone("12ab")


class ModelTests(unittest.TestCase):
    def test_product_valid_and_margin(self):
        p = Product("gro-001", "Rice", 1, 1, "420", "520", 20)
        self.assertEqual(p.sku, "GRO-001")
        self.assertEqual(p.margin(), Decimal("100.00"))

    def test_product_selling_below_cost_rejected(self):
        with self.assertRaises(ValidationError):
            Product("X1", "Item", 1, 1, "50", "40", 5)

    def test_product_negative_reorder_rejected(self):
        with self.assertRaises(ValidationError):
            Product("X1", "Item", 1, 1, "5", "10", -1)

    def test_supplier_bad_email_rejected(self):
        with self.assertRaises(ValidationError):
            Supplier("Acme", email="bad")

    def test_line_item_total(self):
        self.assertEqual(LineItem(1, 5, "520").total(), Decimal("2600.00"))
        with self.assertRaises(ValidationError):
            LineItem(1, 0, "10")


class ReportTests(unittest.TestCase):
    def test_format_table(self):
        out = format_table(["sku", "qty"], [["A", 5], ["BB", None]])
        self.assertIn("| sku | qty |", out)
        self.assertIn("| BB  |     |", out)

    def test_format_table_empty(self):
        self.assertEqual(format_table(["a"], []), "(no records)")

    def test_export_csv(self):
        rows = [{"sku": "A", "qty": 5}]
        with tempfile.TemporaryDirectory() as folder:
            path = ReportService.export_csv("demo", rows, folder)
            with open(path, encoding="utf-8") as fh:
                self.assertEqual(fh.read().splitlines(), ["sku,qty", "A,5"])

    def test_export_empty_report_fails(self):
        with self.assertRaises(InventoryError):
            ReportService.export_csv("demo", [], tempfile.gettempdir())


if __name__ == "__main__":
    unittest.main()
