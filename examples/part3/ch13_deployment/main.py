"""
Chapter 13 – Deployment

This file is a minimal placeholder application that follows the same
bootstrap pattern as Chapter 9 (Hello PySide6).  Its primary purpose is
to serve as the *input_file* for pyside6-deploy so the chapter can show a
complete, working deployment workflow.

---------------------------------------------------------------------------
How pyside6-deploy processes this file
---------------------------------------------------------------------------

1.  Read pyproject.toml / pysidedeploy.spec to discover configuration.

2.  Collect all QML files listed under qml_files and embed them as Qt
    resources so the executable does not need external .qml files.

3.  Collect all Python files (this file + any imports) and pass them to
    Nuitka as the compilation root.

4.  Detect which Qt modules are actually used (via import analysis) and
    strip all others from the final bundle.

5.  Invoke Nuitka with the extra-args from pyproject.toml:
        --standalone        – bundle Python runtime + Qt libs
        --follow-imports    – follow all Python imports
        --enable-plugin=pyside6 – Nuitka PySide6 integration

6.  Output a self-contained binary (Linux/macOS) or folder (Windows) in
    the deployment/ directory.

Run manually:
    pyside6-deploy main.py

Or via Nuitka directly (advanced):
    python -m nuitka --standalone --enable-plugin=pyside6 main.py
---------------------------------------------------------------------------
"""

import sys

import PySide6
from PySide6.QtCore import QObject, Property, qVersion
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QmlElement

QML_IMPORT_NAME = "com.example.deploy"
QML_IMPORT_MAJOR_VERSION = 1


@QmlElement
class AppInfo(QObject):
    """Exposes version strings – identical to the Chapter 9 example."""

    @Property(str, constant=True)
    def qtVersion(self) -> str:  # noqa: N802
        return qVersion()

    @Property(str, constant=True)
    def pysideVersion(self) -> str:
        return PySide6.__version__


def main() -> None:
    app = QGuiApplication(sys.argv)

    from PySide6.QtQml import QQmlApplicationEngine
    engine = QQmlApplicationEngine()
    engine.addImportPath("qml")
    engine.loadFromModule("DeployApp", "Main")

    if not engine.rootObjects():
        sys.exit(-1)

    sys.exit(app.exec())


if __name__ == "__main__":
    main()
