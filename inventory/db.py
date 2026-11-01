"""Thin MySQL wrapper: connection, queries, transactions, error translation."""
from contextlib import contextmanager

import mysql.connector
from mysql.connector import Error

from .exceptions import (DatabaseError, InsufficientStockError, InventoryError,
                         ValidationError)


def translate_error(err: Error) -> Exception:
    """Convert MySQL errors into friendly application exceptions."""
    errno = getattr(err, "errno", None)
    msg = getattr(err, "msg", str(err))
    if errno == 1062:
        return ValidationError("A record with the same unique value already exists.")
    if errno == 1452:
        return ValidationError("A referenced record (supplier, product, warehouse...) does not exist.")
    if errno == 3819:
        return ValidationError("A value violates a database rule (e.g. negative quantity or price).")
    if errno == 1644:  # SIGNAL raised by our triggers/procedures
        if "insufficient stock" in msg.lower():
            return InsufficientStockError(msg)
        return InventoryError(msg)
    return DatabaseError(msg)


class Database:
    def __init__(self, host, user, password, database):
        self._config = dict(host=host, user=user, password=password, database=database)
        self._conn = None
        self._in_tx = False

    def connect(self):
        try:
            self._conn = mysql.connector.connect(**self._config)
        except Error as err:
            raise DatabaseError(f"Could not connect to MySQL: {err.msg}") from err

    def close(self):
        if self._conn and self._conn.is_connected():
            self._conn.close()

    def query(self, sql, params=None):
        """Run a SELECT and return a list of dict rows."""
        cur = self._conn.cursor(dictionary=True)
        try:
            cur.execute(sql, params or ())
            return cur.fetchall()
        except Error as err:
            raise translate_error(err) from err
        finally:
            cur.close()

    def execute(self, sql, params=None):
        """Run INSERT/UPDATE/CALL. Commits unless inside transaction()."""
        cur = self._conn.cursor()
        try:
            cur.execute(sql, params or ())
            last_id = cur.lastrowid
            if not self._in_tx:
                self._conn.commit()
            return last_id
        except Error as err:
            if not self._in_tx:
                self._conn.rollback()
            raise translate_error(err) from err
        finally:
            cur.close()

    @contextmanager
    def transaction(self):
        """All statements inside succeed together or are rolled back together."""
        self._in_tx = True
        try:
            yield
            self._conn.commit()
        except Exception:
            self._conn.rollback()
            raise
        finally:
            self._in_tx = False
