"""
Chapter 21 — MVVM Contacts Application
=======================================
Demonstrates a clean service / viewmodel / view architecture in PySide6.

Layer responsibilities
----------------------
services/    Pure Python, no Qt.  Unit-testable without a QApplication.
viewmodels/  QObject subclasses that bridge the service layer to QML.
qml/         Declarative UI — reads/writes viewmodel properties and calls slots.

Run:
    python main.py
"""

import sys
import os
from pathlib import Path

# ---------------------------------------------------------------------------
# Ensure local packages are importable regardless of working directory
# ---------------------------------------------------------------------------
ROOT = Path(__file__).parent
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from PySide6.QtCore import QCoreApplication
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine

# Import triggers @QmlElement registration for ContactListViewModel
from services.contact_service import ContactService                    # noqa: F401
from viewmodels.contact_list_viewmodel import ContactListViewModel     # noqa: F401

QML_DIR = ROOT / "qml"


def main() -> int:
    app = QGuiApplication(sys.argv)
    app.setApplicationName("MVVMContacts")
    app.setOrganizationName("QtBookExamples")
    app.setApplicationDisplayName("Contacts")

    # ------------------------------------------------------------------ #
    # Service + ViewModel
    # ------------------------------------------------------------------ #
    service   = ContactService()
    viewmodel = ContactListViewModel(service=service)

    # ------------------------------------------------------------------ #
    # Engine
    # ------------------------------------------------------------------ #
    engine = QQmlApplicationEngine()

    # Register the QML module so `import com.example.contacts` works
    engine.addImportPath(str(QML_DIR.parent))

    # Inject the viewmodel as a named root context property
    engine.setInitialProperties({"vm": viewmodel})

    def _on_object_created(obj, url):
        if obj is None:
            print(f"[main] Error: failed to load {url}", file=sys.stderr)
            QCoreApplication.exit(1)

    engine.objectCreated.connect(_on_object_created)
    engine.load(str(QML_DIR / "Main.qml"))

    return app.exec()


if __name__ == "__main__":
    sys.exit(main())
