"""
Chapter 11 – Contact Model
Demonstrates QAbstractListModel with add / remove / swipe-to-delete.
"""

import sys

from backend.contact_model import ContactModel

from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine

# ---------------------------------------------------------------------------
# Sample data
# ---------------------------------------------------------------------------
SAMPLE_CONTACTS = [
    ("Alice Andersen",  "alice@example.com",   "+1 555-0101"),
    ("Bob Bergmann",    "bob@example.com",      "+1 555-0102"),
    ("Carol Chen",      "carol@example.com",    "+44 20 7946 0103"),
    ("David Dubois",    "david@example.com",    "+33 1 70 36 0104"),
    ("Eve Eriksson",    "eve@example.com",      "+46 8 123 456 05"),
]


def main() -> None:
    app = QGuiApplication(sys.argv)

    # Build and pre-populate the model before the engine loads QML.
    model = ContactModel()
    for name, email, phone in SAMPLE_CONTACTS:
        model.addContact(name, email, phone)

    engine = QQmlApplicationEngine()
    engine.addImportPath("qml")

    # Pass the model as a property on the root QML context.
    # QML accesses it as the "contactModel" context property.
    engine.setInitialProperties({"contactModel": model})

    engine.loadFromModule("ContactApp", "Main")

    if not engine.rootObjects():
        sys.exit(-1)

    sys.exit(app.exec())


if __name__ == "__main__":
    main()
