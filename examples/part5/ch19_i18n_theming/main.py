"""
Chapter 19 — Internationalization and Runtime Theming
======================================================
Demonstrates:
  - Loading a QTranslator based on QLocale.system()
  - A QmlElement/QmlSingleton LanguageManager that reinstalls
    translators and calls engine.retranslate() at runtime
  - A QML-side Theme singleton for dark/light colour tokens

Run:
    python main.py
    python main.py --lang de
"""

import sys
import os
from pathlib import Path

from PySide6.QtCore import (
    QObject, QLocale, QTranslator, QCoreApplication,
    Property, Signal, Slot,
)
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import (
    QQmlApplicationEngine, QmlElement, QmlSingleton,
    qmlRegisterSingletonType,
)

QML_IMPORT_NAME = "com.example.i18n"
QML_IMPORT_MAJOR_VERSION = 1

TRANSLATIONS_DIR = Path(__file__).parent / "translations"
QML_DIR = Path(__file__).parent / "qml"


# ---------------------------------------------------------------------------
# LanguageManager singleton exposed to QML
# ---------------------------------------------------------------------------

@QmlElement
@QmlSingleton
class LanguageManager(QObject):
    """Manages the active language and reinstalls translators at runtime."""

    currentLanguageChanged = Signal()

    # Class-level references shared with the factory
    _instance = None
    _engine: QQmlApplicationEngine | None = None
    _translator: QTranslator | None = None

    def __init__(self, parent: QObject | None = None) -> None:
        super().__init__(parent)
        self._current_language: str = "en"
        self._available_languages: list[dict] = [
            {"code": "en", "name": "English"},
            {"code": "de", "name": "Deutsch"},
            {"code": "fr", "name": "Français"},
        ]
        LanguageManager._instance = self

    # ------------------------------------------------------------------
    # Properties
    # ------------------------------------------------------------------

    @Property(list, constant=True)
    def availableLanguages(self) -> list:          # noqa: N802
        return self._available_languages

    @Property(str, notify=currentLanguageChanged)
    def currentLanguage(self) -> str:              # noqa: N802
        return self._current_language

    # ------------------------------------------------------------------
    # Slots
    # ------------------------------------------------------------------

    @Slot(str)
    def setLanguage(self, code: str) -> None:      # noqa: N802
        """Reinstall translator for *code* and trigger QML retranslation."""
        if code == self._current_language:
            return

        app = QCoreApplication.instance()

        # Remove previous translator
        if LanguageManager._translator is not None:
            app.removeTranslator(LanguageManager._translator)
            LanguageManager._translator = None

        if code != "en":
            ts_path = TRANSLATIONS_DIR / f"app_{code}.qm"
            translator = QTranslator(app)
            if ts_path.exists() and translator.load(str(ts_path)):
                app.installTranslator(translator)
                LanguageManager._translator = translator
            else:
                print(
                    f"[LanguageManager] Translation file not found: {ts_path}\n"
                    "  (Run lrelease to compile .ts → .qm)"
                )

        self._current_language = code
        self.currentLanguageChanged.emit()

        # Ask the engine to re-evaluate all qsTr() calls
        if LanguageManager._engine is not None:
            LanguageManager._engine.retranslate()

    # ------------------------------------------------------------------
    # Internal helper called from main() after engine creation
    # ------------------------------------------------------------------

    @classmethod
    def set_engine(cls, engine: QQmlApplicationEngine) -> None:
        cls._engine = engine


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main() -> int:
    app = QGuiApplication(sys.argv)
    app.setApplicationName("I18nTheming")
    app.setOrganizationName("QtBookExamples")

    # ------------------------------------------------------------------ #
    # Install system translator on startup
    # ------------------------------------------------------------------ #
    locale = QLocale.system()
    lang_code = locale.name()[:2]           # e.g. "de" from "de_DE"

    translator = QTranslator(app)
    ts_path = TRANSLATIONS_DIR / f"app_{lang_code}.qm"
    if ts_path.exists() and translator.load(str(ts_path)):
        app.installTranslator(translator)
        LanguageManager._translator = translator
        print(f"[main] Loaded translator for '{lang_code}'")
    else:
        lang_code = "en"

    # Allow --lang override from command line (useful for testing)
    for i, arg in enumerate(sys.argv[1:], 1):
        if arg == "--lang" and i < len(sys.argv):
            lang_code = sys.argv[i + 1] if i + 1 < len(sys.argv) else lang_code

    # ------------------------------------------------------------------ #
    # Engine setup
    # ------------------------------------------------------------------ #
    engine = QQmlApplicationEngine()

    # Give the singleton access to the engine for retranslate()
    # The singleton is created lazily on first QML access; we hook in via
    # the objectCreated signal.
    def _on_object_created(obj, url):
        if obj is None:
            print(f"[main] Failed to create QML object from {url}")
            QCoreApplication.exit(1)

    engine.objectCreated.connect(_on_object_created)

    # Register the QML module path so Theme.qml / qmldir are found
    engine.addImportPath(str(QML_DIR.parent))

    engine.load(str(QML_DIR / "Main.qml"))

    # Store engine reference on the singleton class (instance may not
    # exist yet if QML hasn't been parsed; set_engine caches the ref).
    LanguageManager.set_engine(engine)
    if LanguageManager._instance is not None:
        LanguageManager._instance._current_language = lang_code

    return app.exec()


if __name__ == "__main__":
    sys.exit(main())
