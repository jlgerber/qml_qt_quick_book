"""
Chapter 10 – Counter App
Demonstrates Property / Signal / Slot with proper type annotations.
"""

import sys

# Importing the backend package triggers @QmlElement registration.
import backend.counter  # noqa: F401  (side-effect import)

from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine


def main() -> None:
    app = QGuiApplication(sys.argv)

    engine = QQmlApplicationEngine()
    engine.addImportPath("qml")
    engine.loadFromModule("CounterApp", "Main")

    if not engine.rootObjects():
        sys.exit(-1)

    sys.exit(app.exec())


if __name__ == "__main__":
    main()
