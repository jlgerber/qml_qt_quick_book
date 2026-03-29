"""
Chapter 12 – MVVM Search
Demonstrates service / viewmodel / view separation with async search.
"""

import sys

from services.search_service import SearchService
from viewmodels.search_viewmodel import SearchViewModel

from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine


def main() -> None:
    app = QGuiApplication(sys.argv)

    # Wire service into viewmodel (dependency injection).
    service   = SearchService()
    viewmodel = SearchViewModel(service)

    engine = QQmlApplicationEngine()
    engine.addImportPath("qml")

    # Expose the viewmodel as "vm" on the root object.
    engine.setInitialProperties({"vm": viewmodel})

    engine.loadFromModule("SearchApp", "Main")

    if not engine.rootObjects():
        sys.exit(-1)

    sys.exit(app.exec())


if __name__ == "__main__":
    main()
