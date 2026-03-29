"""
Chapter 9 – Hello PySide6
Minimal PySide6 + QML application.

Demonstrates:
  - QGuiApplication / QQmlApplicationEngine bootstrap
  - @QmlElement registration (no manual qmlRegisterType call)
  - @Property(str, constant=True) exposed to QML
  - Loading a QML module by URI ("HelloApp") and component name ("Main")
"""

import sys

import PySide6
from PySide6.QtCore import QObject, Property, qVersion
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine, QML_IMPORT_NAME, QmlElement

# ---------------------------------------------------------------------------
# QML module registration
# Every @QmlElement in this file is registered under this URI.
# ---------------------------------------------------------------------------
QML_IMPORT_NAME = "com.example.hello"
QML_IMPORT_MAJOR_VERSION = 1

# ---------------------------------------------------------------------------
# Backend type
# ---------------------------------------------------------------------------

@QmlElement
class AppInfo(QObject):
    """Exposes version strings to QML as constant properties."""

    def __init__(self, parent: QObject = None) -> None:
        super().__init__(parent)

    @Property(str, constant=True)
    def qtVersion(self) -> str:  # noqa: N802  (Qt naming convention)
        """Return the runtime Qt version string, e.g. '6.7.2'."""
        return qVersion()

    @Property(str, constant=True)
    def pysideVersion(self) -> str:
        """Return the PySide6 package version string."""
        return PySide6.__version__


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main() -> None:
    app = QGuiApplication(sys.argv)

    engine = QQmlApplicationEngine()

    # Load Main.qml from the HelloApp QML module (defined in qml/qmldir).
    # The engine resolves "com.example.hello" via the import path we add below.
    engine.addImportPath("qml")          # makes "HelloApp" module discoverable
    engine.loadFromModule("HelloApp", "Main")

    if not engine.rootObjects():
        sys.exit(-1)

    sys.exit(app.exec())


if __name__ == "__main__":
    main()
