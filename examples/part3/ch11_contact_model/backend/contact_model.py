"""
Chapter 11 – ContactModel

Demonstrates QAbstractListModel subclassing:
  - Custom role names exposed to QML
  - beginInsertRows / endInsertRows / beginRemoveRows / endRemoveRows
  - @Slot annotations for addContact / removeContact / clear
"""

from __future__ import annotations

from PySide6.QtCore import (
    QAbstractListModel,
    QModelIndex,
    Qt,
    Slot,
)
from PySide6.QtQml import QmlElement

QML_IMPORT_NAME = "com.example.contacts"
QML_IMPORT_MAJOR_VERSION = 1


@QmlElement
class ContactModel(QAbstractListModel):
    """
    A list model that stores contacts as plain dicts.

    Each contact dict has the keys: "name", "email", "phone".

    Roles (accessible from QML via model.name, model.email, model.phone)
    ---------------------------------------------------------------------
    NameRole  – display name
    EmailRole – e-mail address
    PhoneRole – phone number
    """

    # ------------------------------------------------------------------
    # Role constants
    # ------------------------------------------------------------------
    NameRole  = Qt.UserRole + 1
    EmailRole = Qt.UserRole + 2
    PhoneRole = Qt.UserRole + 3

    # ------------------------------------------------------------------
    # Constructor
    # ------------------------------------------------------------------
    def __init__(self, parent=None) -> None:
        super().__init__(parent)
        self._contacts: list[dict] = []

    # ------------------------------------------------------------------
    # QAbstractListModel required overrides
    # ------------------------------------------------------------------
    def rowCount(self, parent: QModelIndex = QModelIndex()) -> int:
        if parent.isValid():
            return 0
        return len(self._contacts)

    def data(self, index: QModelIndex, role: int = Qt.DisplayRole):
        if not index.isValid() or not (0 <= index.row() < len(self._contacts)):
            return None
        contact = self._contacts[index.row()]
        if role == self.NameRole:
            return contact["name"]
        if role == self.EmailRole:
            return contact["email"]
        if role == self.PhoneRole:
            return contact["phone"]
        return None

    def roleNames(self) -> dict:
        return {
            self.NameRole:  b"name",
            self.EmailRole: b"email",
            self.PhoneRole: b"phone",
        }

    # ------------------------------------------------------------------
    # Public slots
    # ------------------------------------------------------------------
    @Slot(str, str, str)
    def addContact(self, name: str, email: str, phone: str) -> None:
        """Append a new contact to the end of the list."""
        row = len(self._contacts)
        self.beginInsertRows(QModelIndex(), row, row)
        self._contacts.append({"name": name, "email": email, "phone": phone})
        self.endInsertRows()

    @Slot(int)
    def removeContact(self, row: int) -> None:
        """Remove the contact at the given row index."""
        if not (0 <= row < len(self._contacts)):
            return
        self.beginRemoveRows(QModelIndex(), row, row)
        del self._contacts[row]
        self.endRemoveRows()

    @Slot()
    def clear(self) -> None:
        """Remove all contacts."""
        if not self._contacts:
            return
        self.beginRemoveRows(QModelIndex(), 0, len(self._contacts) - 1)
        self._contacts.clear()
        self.endRemoveRows()
