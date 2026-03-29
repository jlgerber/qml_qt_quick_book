"""
Chapter 12 – SearchService

Pure Python service layer – absolutely no Qt imports.
This is intentional: business logic should not depend on the UI framework.

The service searches a hardcoded catalogue of Qt-related topics.
In a real application this could be a database query, HTTP call, etc.
"""

from __future__ import annotations

from dataclasses import dataclass


@dataclass
class SearchResult:
    """A single search result."""
    title: str
    description: str
    score: float          # relevance score 0.0–1.0


# ---------------------------------------------------------------------------
# Catalogue: 15 Qt / QML topics
# ---------------------------------------------------------------------------
_CATALOGUE: list[dict] = [
    {
        "title": "Qt Quick",
        "description": "A high-level UI toolkit for building fluid, animated interfaces "
                       "using QML and JavaScript.",
        "keywords": ["quick", "qml", "ui", "animation", "fluid"],
    },
    {
        "title": "QML Language",
        "description": "A declarative language for describing user interface trees. "
                       "Combines JSON-like syntax with JavaScript expressions.",
        "keywords": ["qml", "declarative", "language", "javascript", "syntax"],
    },
    {
        "title": "PySide6",
        "description": "The official Python bindings for Qt 6, maintained by The Qt Company. "
                       "Exposes the full Qt API to Python.",
        "keywords": ["pyside6", "python", "bindings", "qt6"],
    },
    {
        "title": "QAbstractListModel",
        "description": "Base class for list models. Subclass it to expose Python data "
                       "structures to QML ListView and Repeater.",
        "keywords": ["model", "listmodel", "abstractlistmodel", "data", "backend"],
    },
    {
        "title": "Signal and Slot",
        "description": "Qt's observer pattern: objects communicate via typed signals "
                       "connected to slots, decoupling sender and receiver.",
        "keywords": ["signal", "slot", "observer", "connect", "event"],
    },
    {
        "title": "Property Binding",
        "description": "QML property bindings create live dependencies: when one value "
                       "changes, all dependent properties update automatically.",
        "keywords": ["property", "binding", "reactive", "dependency"],
    },
    {
        "title": "Qt Widgets",
        "description": "The classic C++ widget toolkit. Available in PySide6 as QWidget, "
                       "QMainWindow, QDialog, and hundreds of ready-made controls.",
        "keywords": ["widgets", "qwidget", "mainwindow", "dialog", "classic"],
    },
    {
        "title": "QThreadPool and QRunnable",
        "description": "Run tasks off the main thread using a managed thread pool. "
                       "QRunnable defines the unit of work; QThreadPool schedules it.",
        "keywords": ["thread", "threadpool", "runnable", "concurrent", "async"],
    },
    {
        "title": "Qt Model/View",
        "description": "Separates data (models) from presentation (views) and editing "
                       "(delegates). Works in both Widgets and Qt Quick.",
        "keywords": ["model", "view", "delegate", "mvc", "separation"],
    },
    {
        "title": "ApplicationWindow",
        "description": "The top-level window type in Qt Quick Controls. Provides a menu bar, "
                       "toolbar, status bar, and footer out of the box.",
        "keywords": ["applicationwindow", "window", "controls", "menubar"],
    },
    {
        "title": "ListView",
        "description": "Displays items from a model in a scrollable vertical or horizontal list. "
                       "Highly customisable via delegate and section properties.",
        "keywords": ["listview", "list", "scroll", "delegate", "model"],
    },
    {
        "title": "Qt Networking",
        "description": "QNetworkAccessManager provides HTTP/HTTPS, including async replies "
                       "via signals. Available from Python as PySide6.QtNetwork.",
        "keywords": ["network", "http", "https", "rest", "api", "request"],
    },
    {
        "title": "Animations and Transitions",
        "description": "Qt Quick animations (NumberAnimation, SequentialAnimation, Behavior) "
                       "let you create smooth, GPU-accelerated UI transitions.",
        "keywords": ["animation", "transition", "behavior", "smooth", "gpu"],
    },
    {
        "title": "pyside6-deploy",
        "description": "Command-line tool that packages a PySide6 application for distribution "
                       "using Nuitka, producing a standalone native executable.",
        "keywords": ["deploy", "package", "nuitka", "distribute", "executable"],
    },
    {
        "title": "Qt Quick Controls",
        "description": "A set of ready-to-use, style-able UI controls (Button, TextField, "
                       "ComboBox, Slider…) built on top of Qt Quick.",
        "keywords": ["controls", "button", "textfield", "combobox", "slider", "style"],
    },
]


class SearchService:
    """
    Searches the catalogue using a simple keyword-match scoring algorithm.

    Scoring rules
    -------------
    - Each word in *query* is matched against item keywords (case-insensitive).
    - Title substring match:       +0.5 per word
    - Description substring match: +0.2 per word
    - Keyword exact match:         +0.3 per word

    The final score is normalised to [0, 1] and items with score == 0 are
    excluded.  Results are sorted by descending score.
    """

    def search(self, query: str) -> list[SearchResult]:
        if not query or not query.strip():
            return []

        words = [w.lower() for w in query.strip().split() if w]
        results: list[SearchResult] = []

        for item in _CATALOGUE:
            score = 0.0
            title_lower = item["title"].lower()
            desc_lower  = item["description"].lower()
            keywords    = item["keywords"]

            for word in words:
                if word in title_lower:
                    score += 0.5
                if word in desc_lower:
                    score += 0.2
                if word in keywords:
                    score += 0.3

            if score > 0.0:
                # Clamp to 1.0
                normalised = min(score / max(len(words), 1), 1.0)
                results.append(
                    SearchResult(
                        title=item["title"],
                        description=item["description"],
                        score=round(normalised, 3),
                    )
                )

        results.sort(key=lambda r: r.score, reverse=True)
        return results
