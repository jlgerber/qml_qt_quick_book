"""
Chapter 12 – SearchViewModel

Connects the pure-Python SearchService to QML using:
  - QAbstractListModel (ResultModel) for the results list
  - QThreadPool + QRunnable for off-thread search
  - Signal/Slot for posting results back to the main thread
  - @Property for query, searching flag, and result count
"""

from __future__ import annotations

from PySide6.QtCore import (
    QAbstractListModel,
    QModelIndex,
    QObject,
    QRunnable,
    QThreadPool,
    Property,
    Signal,
    Slot,
    Qt,
)
from PySide6.QtQml import QmlElement

from services.search_service import SearchResult, SearchService

QML_IMPORT_NAME = "com.example.search"
QML_IMPORT_MAJOR_VERSION = 1


# ---------------------------------------------------------------------------
# ResultModel – inner list model exposed to QML
# ---------------------------------------------------------------------------

@QmlElement
class ResultModel(QAbstractListModel):
    """
    Exposes a list of SearchResult objects to QML.

    Roles
    -----
    TitleRole       – result.title       (string)
    DescriptionRole – result.description (string)
    ScoreRole       – result.score       (float, formatted as %)
    """

    TitleRole       = Qt.UserRole + 1
    DescriptionRole = Qt.UserRole + 2
    ScoreRole       = Qt.UserRole + 3

    def __init__(self, parent: QObject = None) -> None:
        super().__init__(parent)
        self._results: list[SearchResult] = []

    # -- QAbstractListModel overrides --------------------------------------

    def rowCount(self, parent: QModelIndex = QModelIndex()) -> int:
        if parent.isValid():
            return 0
        return len(self._results)

    def data(self, index: QModelIndex, role: int = Qt.DisplayRole):
        if not index.isValid() or not (0 <= index.row() < len(self._results)):
            return None
        result = self._results[index.row()]
        if role == self.TitleRole:
            return result.title
        if role == self.DescriptionRole:
            return result.description
        if role == self.ScoreRole:
            return f"{result.score * 100:.0f}%"
        return None

    def roleNames(self) -> dict:
        return {
            self.TitleRole:       b"title",
            self.DescriptionRole: b"description",
            self.ScoreRole:       b"score",
        }

    # -- Internal API used by SearchViewModel ------------------------------

    def set_results(self, results: list[SearchResult]) -> None:
        self.beginResetModel()
        self._results = results
        self.endResetModel()

    def clear(self) -> None:
        self.set_results([])


# ---------------------------------------------------------------------------
# QRunnable worker – runs on a background thread
# ---------------------------------------------------------------------------

class _SearchWorker(QRunnable):
    """
    Calls SearchService.search on a background thread then emits the
    supplied *done* signal with the results.

    We use a plain QRunnable rather than QThread so that QThreadPool can
    reuse threads from its pool.
    """

    def __init__(
        self,
        service: SearchService,
        query: str,
        done_signal: Signal,
    ) -> None:
        super().__init__()
        self._service = service
        self._query = query
        self._done = done_signal
        self.setAutoDelete(True)

    def run(self) -> None:  # runs on worker thread
        results = self._service.search(self._query)
        self._done.emit(results)  # posted to main thread via Qt's event loop


# ---------------------------------------------------------------------------
# SearchViewModel
# ---------------------------------------------------------------------------

@QmlElement
class SearchViewModel(QObject):
    """
    ViewModel that wires SearchService to QML.

    Properties (all notify their respective changed signals)
    ---------
    query       : str   – current search text (two-way bindable)
    searching   : bool  – True while background search is running
    resultCount : int   – number of results in the model

    Slots
    -----
    performSearch()  – starts an async search using QThreadPool
    clearSearch()    – resets query and results
    """

    # ------------------------------------------------------------------
    # Signals
    # ------------------------------------------------------------------
    queryChanged        = Signal()
    searchingChanged    = Signal()
    resultCountChanged  = Signal()
    # Internal: worker posts results back via this signal (list of SearchResult).
    _searchDone         = Signal(object)

    # ------------------------------------------------------------------
    # Constructor
    # ------------------------------------------------------------------
    def __init__(self, service: SearchService, parent: QObject = None) -> None:
        super().__init__(parent)
        self._service  = service
        self._query    = ""
        self._searching = False

        self._result_model = ResultModel(self)
        self._thread_pool  = QThreadPool.globalInstance()

        # Worker posts results to _searchDone; we handle on main thread.
        self._searchDone.connect(self._on_search_done)

    # ------------------------------------------------------------------
    # Properties
    # ------------------------------------------------------------------
    @Property(str, notify=queryChanged)
    def query(self) -> str:
        return self._query

    @query.setter
    def query(self, value: str) -> None:
        if value != self._query:
            self._query = value
            self.queryChanged.emit()

    @Property(bool, notify=searchingChanged)
    def searching(self) -> bool:
        return self._searching

    @Property(int, notify=resultCountChanged)
    def resultCount(self) -> int:
        return self._result_model.rowCount()

    @Property(ResultModel, constant=True)
    def results(self) -> ResultModel:
        """The live ResultModel; safe to bind to ListView.model in QML."""
        return self._result_model

    # ------------------------------------------------------------------
    # Slots
    # ------------------------------------------------------------------
    @Slot()
    def performSearch(self) -> None:
        """Start a background search for the current query."""
        if not self._query.strip():
            return
        if self._searching:
            return  # prevent double-submit

        self._set_searching(True)
        worker = _SearchWorker(self._service, self._query, self._searchDone)
        self._thread_pool.start(worker)

    @Slot()
    def clearSearch(self) -> None:
        """Reset the query and clear all results."""
        self._query = ""
        self.queryChanged.emit()
        self._result_model.clear()
        self._emit_count_changed()

    # ------------------------------------------------------------------
    # Private helpers
    # ------------------------------------------------------------------
    def _set_searching(self, value: bool) -> None:
        if value != self._searching:
            self._searching = value
            self.searchingChanged.emit()

    def _emit_count_changed(self) -> None:
        self.resultCountChanged.emit()

    @Slot(object)
    def _on_search_done(self, results: list) -> None:
        """Receives search results on the main thread."""
        self._result_model.set_results(results)
        self._set_searching(False)
        self._emit_count_changed()
