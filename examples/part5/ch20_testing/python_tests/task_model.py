"""
Chapter 20 – Python test target: TaskModel

A minimal QAbstractListModel that mirrors the C++ TaskModel defined in
cpp_tests/tst_taskmodel.cpp.  Keeping the same roles, method names, and
return-value conventions means the same logical behaviour is verified in
all three test surfaces (C++, QML, Python).

This file is intentionally self-contained — no QML registration, no
external dependencies beyond PySide6.
"""

from __future__ import annotations

import uuid
from dataclasses import dataclass, field

from PySide6.QtCore import QAbstractListModel, QModelIndex, Qt, Slot


# ---------------------------------------------------------------------------
# Domain type
# ---------------------------------------------------------------------------

@dataclass
class _Task:
    title: str
    done: bool = False
    id: str = field(default_factory=lambda: str(uuid.uuid4()))


# ---------------------------------------------------------------------------
# TaskModel
# ---------------------------------------------------------------------------

class TaskModel(QAbstractListModel):
    """
    List model storing Task objects.

    Roles
    -----
    IdRole    – task.id    (str)   — role name ``"taskId"``
    TitleRole – task.title (str)   — role name ``"title"``
    DoneRole  – task.done  (bool)  — role name ``"done"``

    Methods
    -------
    addTask(title)       – appends a new task; returns its UUID string
    removeTask(task_id)  – removes by UUID; returns True if found
    setDone(task_id, done) – sets done flag; emits dataChanged; returns True if found
    """

    IdRole    = Qt.UserRole + 1
    TitleRole = Qt.UserRole + 2
    DoneRole  = Qt.UserRole + 3

    def __init__(self, parent=None) -> None:
        super().__init__(parent)
        self._tasks: list[_Task] = []

    # ------------------------------------------------------------------
    # QAbstractListModel overrides
    # ------------------------------------------------------------------

    def rowCount(self, parent: QModelIndex = QModelIndex()) -> int:
        if parent.isValid():
            return 0
        return len(self._tasks)

    def data(self, index: QModelIndex, role: int = Qt.DisplayRole):
        if not index.isValid() or not (0 <= index.row() < len(self._tasks)):
            return None
        task = self._tasks[index.row()]
        if role == self.IdRole:
            return task.id
        if role == self.TitleRole:
            return task.title
        if role == self.DoneRole:
            return task.done
        return None

    def roleNames(self) -> dict:
        return {
            self.IdRole:    b"taskId",
            self.TitleRole: b"title",
            self.DoneRole:  b"done",
        }

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------

    @Slot(str, result=str)
    def addTask(self, title: str) -> str:
        """Append a new task; return its UUID string."""
        task = _Task(title=title)
        row = len(self._tasks)
        self.beginInsertRows(QModelIndex(), row, row)
        self._tasks.append(task)
        self.endInsertRows()
        return task.id

    @Slot(str, result=bool)
    def removeTask(self, task_id: str) -> bool:
        """Remove the task with the given UUID. Returns True if found."""
        for row, task in enumerate(self._tasks):
            if task.id == task_id:
                self.beginRemoveRows(QModelIndex(), row, row)
                del self._tasks[row]
                self.endRemoveRows()
                return True
        return False

    @Slot(str, bool, result=bool)
    def setDone(self, task_id: str, done: bool) -> bool:
        """Set the done flag for the task with the given UUID. Returns True if found."""
        for row, task in enumerate(self._tasks):
            if task.id == task_id:
                task.done = done
                idx = self.index(row)
                self.dataChanged.emit(idx, idx, [self.DoneRole])
                return True
        return False
