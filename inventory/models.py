"""Entity classes. Each validates its own data when created."""
from dataclasses import dataclass
from decimal import Decimal
from typing import Optional

from . import validators as v
from .exceptions import ValidationError


@dataclass
class Supplier:
    supplier_name: str
    contact_person: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[str] = None
    address: Optional[str] = None
    supplier_id: Optional[int] = None

    def __post_init__(self):
        self.supplier_name = v.required_text(self.supplier_name, "Supplier name")
        self.contact_person = v.optional_text(self.contact_person, "Contact person", 100)
        self.phone = v.valid_phone(self.phone)
        self.email = v.valid_email(self.email)
        self.address = v.optional_text(self.address, "Address")


@dataclass
class Category:
    category_name: str
    description: Optional[str] = None
    category_id: Optional[int] = None

    def __post_init__(self):
        self.category_name = v.required_text(self.category_name, "Category name", 80)
        self.description = v.optional_text(self.description, "Description")


@dataclass
class Warehouse:
    warehouse_name: str
    location: Optional[str] = None
    warehouse_id: Optional[int] = None

    def __post_init__(self):
        self.warehouse_name = v.required_text(self.warehouse_name, "Warehouse name", 80)
        self.location = v.optional_text(self.location, "Location", 150)


@dataclass
class Product:
    sku: str
    product_name: str
    category_id: int
    supplier_id: int
    cost_price: Decimal
    selling_price: Decimal
    reorder_level: int = 10
    product_id: Optional[int] = None

    def __post_init__(self):
        self.sku = v.required_text(self.sku, "SKU", 30).upper()
        self.product_name = v.required_text(self.product_name, "Product name", 120)
        self.category_id = v.positive_int(self.category_id, "Category ID")
        self.supplier_id = v.positive_int(self.supplier_id, "Supplier ID")
        self.cost_price = v.non_negative_decimal(self.cost_price, "Cost price")
        self.selling_price = v.non_negative_decimal(self.selling_price, "Selling price")
        self.reorder_level = v.non_negative_int(self.reorder_level, "Reorder level")
        if self.selling_price < self.cost_price:
            raise ValidationError("Selling price cannot be lower than cost price.")

    def margin(self) -> Decimal:
        """Profit per unit."""
        return self.selling_price - self.cost_price


@dataclass
class LineItem:
    """One row of a purchase order or sale."""
    product_id: int
    quantity: int
    unit_amount: Decimal  # unit cost (purchase) or unit price (sale)

    def __post_init__(self):
        self.product_id = v.positive_int(self.product_id, "Product ID")
        self.quantity = v.positive_int(self.quantity, "Quantity")
        self.unit_amount = v.non_negative_decimal(self.unit_amount, "Unit amount")

    def total(self) -> Decimal:
        return self.unit_amount * self.quantity
