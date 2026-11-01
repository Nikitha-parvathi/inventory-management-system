"""Custom exceptions used across the application."""


class InventoryError(Exception):
    """Base class for all application errors."""


class ValidationError(InventoryError):
    """User input or data failed validation."""


class NotFoundError(InventoryError):
    """A requested record does not exist."""


class InsufficientStockError(InventoryError):
    """A sale/issue would take stock below zero."""


class DatabaseError(InventoryError):
    """Connection or unexpected database failure."""
