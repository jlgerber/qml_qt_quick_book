"""
services/contact_service.py — Pure-Python domain layer
=======================================================
No Qt imports.  This layer can be unit-tested with plain pytest without
starting a QApplication.

Domain type
-----------
Contact(id, name, email, phone)

ContactService
--------------
In-memory store, pre-populated with six sample contacts.

Public API
----------
get_all()                        -> list[Contact]
search(query: str)               -> list[Contact]   (case-insensitive, any field)
add(name, email, phone)          -> Contact
remove(contact_id: str)          -> bool
update(contact_id, **kwargs)     -> Contact | None
"""

from __future__ import annotations

import uuid
from dataclasses import dataclass, field, replace


# ---------------------------------------------------------------------------
# Domain model
# ---------------------------------------------------------------------------

@dataclass
class Contact:
    id:    str
    name:  str
    email: str
    phone: str

    @staticmethod
    def _new_id() -> str:
        return str(uuid.uuid4())


# ---------------------------------------------------------------------------
# Service
# ---------------------------------------------------------------------------

class ContactService:
    """In-memory contact repository.

    All mutations return new Contact instances; the original objects
    stored internally are never exposed directly (defensive copies).
    """

    # ------------------------------------------------------------------
    # Construction / seeding
    # ------------------------------------------------------------------

    _SEED_DATA: list[tuple[str, str, str]] = [
        ("Alice Johnson",   "alice@example.com",   "+1-202-555-0101"),
        ("Bob Smith",       "bob@example.com",     "+1-202-555-0102"),
        ("Carol Williams",  "carol@example.com",   "+44-20-7946-0103"),
        ("David Brown",     "david@example.com",   "+49-30-12345678"),
        ("Eva Martinez",    "eva@example.com",      "+34-91-123-4567"),
        ("Frank Nguyen",    "frank@example.com",   "+81-3-1234-5678"),
    ]

    def __init__(self) -> None:
        self._store: dict[str, Contact] = {}
        self._seed()

    def _seed(self) -> None:
        for name, email, phone in self._SEED_DATA:
            c = Contact(id=str(uuid.uuid4()), name=name, email=email, phone=phone)
            self._store[c.id] = c

    # ------------------------------------------------------------------
    # Queries
    # ------------------------------------------------------------------

    def get_all(self) -> list[Contact]:
        """Return all contacts sorted by name (defensive copies)."""
        return [replace(c) for c in sorted(self._store.values(), key=lambda c: c.name)]

    def get_by_id(self, contact_id: str) -> Contact | None:
        """Return a single contact by id, or None if not found."""
        c = self._store.get(contact_id)
        return replace(c) if c else None

    def search(self, query: str) -> list[Contact]:
        """Case-insensitive substring search across name, email, and phone."""
        if not query or not query.strip():
            return self.get_all()

        q = query.strip().lower()
        results = [
            replace(c)
            for c in self._store.values()
            if q in c.name.lower()
            or q in c.email.lower()
            or q in c.phone.lower()
        ]
        return sorted(results, key=lambda c: c.name)

    # ------------------------------------------------------------------
    # Mutations
    # ------------------------------------------------------------------

    def add(self, name: str, email: str = "", phone: str = "") -> Contact:
        """Create and store a new contact; return a copy."""
        if not name or not name.strip():
            raise ValueError("Contact name must not be empty")

        c = Contact(
            id=str(uuid.uuid4()),
            name=name.strip(),
            email=email.strip(),
            phone=phone.strip(),
        )
        self._store[c.id] = c
        return replace(c)

    def remove(self, contact_id: str) -> bool:
        """Remove a contact by id.  Returns True if it existed."""
        if contact_id in self._store:
            del self._store[contact_id]
            return True
        return False

    def update(self, contact_id: str, **kwargs: str) -> Contact | None:
        """
        Update allowed fields (name, email, phone) on an existing contact.
        Returns the updated Contact copy, or None if id not found.

        Raises ValueError if an unknown field key is supplied.
        """
        allowed = {"name", "email", "phone"}
        unknown = set(kwargs) - allowed
        if unknown:
            raise ValueError(f"Unknown field(s): {unknown}")

        c = self._store.get(contact_id)
        if c is None:
            return None

        updated = replace(c, **{k: v.strip() for k, v in kwargs.items()})
        self._store[contact_id] = updated
        return replace(updated)

    # ------------------------------------------------------------------
    # Utility
    # ------------------------------------------------------------------

    def count(self) -> int:
        return len(self._store)

    def __repr__(self) -> str:  # pragma: no cover
        return f"<ContactService contacts={self.count()}>"
