"""
viewmodels/contact_list_viewmodel.py — ViewModel layer (Qt / QML bridge)
=========================================================================
Wraps ContactService and exposes everything QML needs:

  • contacts     — QAbstractListModel (roles: contactId, name, email, phone)
  • searchQuery  — str property; changing it re-filters the contact list
  • loading      — bool property; true while a refresh is in flight
  • isEmpty      — bool computed property; true when contacts model is empty

Slots (callable from QML):
  addContact(name, email, phone)
  removeContact(contactId)
  refresh()   — runs ContactService.get_all() on a thread pool worker
"""

from __future__ import annotations

import sys
from typing import Any

from PySide6.QtCore import (
    QAbstractListModel,
    QByteArray,
    QModelIndex,
    QObject,
    QRunnable,
    QThreadPool,
    Qt,
    Property,
    Signal,
    Slot,
)
from PySide6.QtQml import QmlElement

from services.contact_service import Contact, ContactService

QML_IMPORT_NAME = "com.example.contacts"
QML_IMPORT_MAJOR_VERSION = 1


# ---------------------------------------------------------------------------
# Inner list model — not a QmlElement; exposed only via the ViewModel property
# ---------------------------------------------------------------------------

class ContactModel(QAbstractListModel):
    """Flat list model backed by a Python list[Contact]."""

    # Custom role ids
    ContactIdRole = Qt.UserRole + 1
    NameRole      = Qt.UserRole + 2
    EmailRole     = Qt.UserRole + 3
    PhoneRole     = Qt.UserRole + 4

    _ROLES: dict[int, QByteArray] = {
        ContactIdRole: QByteArray(b"contactId"),
        NameRole:      QByteArray(b"name"),
        EmailRole:     QByteArray(b"email"),
        PhoneRole:     QByteArray(b"phone"),
    }

    def __init__(self, parent: QObject | None = None) -> None:
        super().__init__(parent)
        self._contacts: list[Contact] = []

    # ── QAbstractListModel interface ──────────────────────────────────

    def rowCount(self, parent: QModelIndex = QModelIndex()) -> int:
        if parent.isValid():
            return 0
        return len(self._contacts)

    def data(self, index: QModelIndex, role: int = Qt.DisplayRole) -> Any:
        if not index.isValid() or index.row() >= len(self._contacts):
            return None
        c = self._contacts[index.row()]
        match role:
            case self.ContactIdRole: return c.id
            case self.NameRole:      return c.name
            case self.EmailRole:     return c.email
            case self.PhoneRole:     return c.phone
            case _:                  return None

    def roleNames(self) -> dict[int, QByteArray]:
        return self._ROLES

    # ── Mutation helpers (always called on the GUI thread) ────────────

    def reset_contacts(self, contacts: list[Contact]) -> None:
        self.beginResetModel()
        self._contacts = list(contacts)
        self.endResetModel()

    def append_contact(self, contact: Contact) -> None:
        row = len(self._contacts)
        self.beginInsertRows(QModelIndex(), row, row)
        self._contacts.append(contact)
        self.endInsertRows()

    def remove_contact_by_id(self, contact_id: str) -> bool:
        for i, c in enumerate(self._contacts):
            if c.id == contact_id:
                self.beginRemoveRows(QModelIndex(), i, i)
                del self._contacts[i]
                self.endRemoveRows()
                return True
        return False

    def is_empty(self) -> bool:
        return len(self._contacts) == 0


# ---------------------------------------------------------------------------
# Background worker for loading contacts off the GUI thread
# ---------------------------------------------------------------------------

class _RefreshWorker(QRunnable):
    """Calls ContactService.get_all() on a thread-pool thread."""

    def __init__(
        self,
        service: ContactService,
        query: str,
        on_done,   # callable(list[Contact])
    ) -> None:
        super().__init__()
        self._service = service
        self._query   = query
        self._on_done = on_done
        self.setAutoDelete(True)

    def run(self) -> None:
        try:
            if self._query:
                contacts = self._service.search(self._query)
            else:
                contacts = self._service.get_all()
            self._on_done(contacts)
        except Exception as exc:
            print(f"[_RefreshWorker] error: {exc}", file=sys.stderr)
            self._on_done([])


# ---------------------------------------------------------------------------
# ViewModel — exposed to QML as com.example.contacts.ContactListViewModel
# ---------------------------------------------------------------------------

@QmlElement
class ContactListViewModel(QObject):
    """
    Bridge between the pure-Python ContactService and the QML view layer.

    QML usage example:

        import com.example.contacts
        ContactListViewModel {
            id: vm
            Component.onCompleted: vm.refresh()
        }
    """

    # Signals
    searchQueryChanged   = Signal()
    loadingChanged       = Signal()
    isEmptyChanged       = Signal()
    errorOccurred        = Signal(str, arguments=["message"])

    def __init__(
        self,
        service: ContactService | None = None,
        parent: QObject | None = None,
    ) -> None:
        super().__init__(parent)
        self._service       = service or ContactService()
        self._contact_model = ContactModel(self)
        self._search_query  = ""
        self._loading       = False
        self._thread_pool   = QThreadPool.globalInstance()

        # Do an initial synchronous load so the view has data immediately
        self._sync_load()

    # ── contacts property ─────────────────────────────────────────────

    @Property(QObject, constant=True)
    def contacts(self) -> ContactModel:
        return self._contact_model

    # ── searchQuery property ──────────────────────────────────────────

    @Property(str, notify=searchQueryChanged)
    def searchQuery(self) -> str:                  # noqa: N802
        return self._search_query

    @searchQuery.setter
    def searchQuery(self, value: str) -> None:     # noqa: N802
        if value == self._search_query:
            return
        self._search_query = value
        self.searchQueryChanged.emit()
        self.refresh()

    # ── loading property ──────────────────────────────────────────────

    @Property(bool, notify=loadingChanged)
    def loading(self) -> bool:
        return self._loading

    def _set_loading(self, value: bool) -> None:
        if value == self._loading:
            return
        self._loading = value
        self.loadingChanged.emit()

    # ── isEmpty property ──────────────────────────────────────────────

    @Property(bool, notify=isEmptyChanged)
    def isEmpty(self) -> bool:                     # noqa: N802
        return self._contact_model.is_empty()

    # ── Slots ─────────────────────────────────────────────────────────

    @Slot()
    def refresh(self) -> None:
        """Reload contacts asynchronously from the service."""
        self._set_loading(True)
        worker = _RefreshWorker(
            service=self._service,
            query=self._search_query,
            on_done=self._on_contacts_loaded,
        )
        self._thread_pool.start(worker)

    @Slot(str, str, str)
    def addContact(self, name: str, email: str, phone: str) -> None:   # noqa: N802
        """Add a new contact and append it to the live model."""
        try:
            contact = self._service.add(name, email, phone)
            # Only append if not currently filtered out by the search query
            q = self._search_query.lower()
            if (
                not q
                or q in contact.name.lower()
                or q in contact.email.lower()
                or q in contact.phone.lower()
            ):
                self._contact_model.append_contact(contact)
                self._emit_is_empty_if_changed()
        except ValueError as exc:
            self.errorOccurred.emit(str(exc))

    @Slot(str)
    def removeContact(self, contact_id: str) -> None:                  # noqa: N802
        """Remove a contact by id from both the service and the model."""
        removed = self._service.remove(contact_id)
        if removed:
            self._contact_model.remove_contact_by_id(contact_id)
            self._emit_is_empty_if_changed()

    # ── Private helpers ───────────────────────────────────────────────

    def _sync_load(self) -> None:
        """Blocking initial load — safe to call during __init__."""
        contacts = (
            self._service.search(self._search_query)
            if self._search_query
            else self._service.get_all()
        )
        self._contact_model.reset_contacts(contacts)
        self._emit_is_empty_if_changed()

    def _on_contacts_loaded(self, contacts: list[Contact]) -> None:
        """Slot called from the worker thread — Qt marshals it to the GUI thread
        via the signal/slot mechanism when using QThreadPool."""
        self._contact_model.reset_contacts(contacts)
        self._set_loading(False)
        self._emit_is_empty_if_changed()

    def _emit_is_empty_if_changed(self) -> None:
        # Always emit; QML bindings will short-circuit if the value hasn't
        # actually changed, but we need to notify in case the model just
        # gained or lost its last item.
        self.isEmptyChanged.emit()
