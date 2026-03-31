"""
Chapter 10 – Counter backend

Demonstrates:
  - Signal with typed argument: valueChanged(int)
  - @Property with notify signal
  - @Slot with argument type annotation
  - Guarding against invalid state (value >= 0)
  - Returning a QVariantList for a list property
"""

from __future__ import annotations

from PySide6.QtCore import QObject, Property, Signal, Slot
from PySide6.QtQml import QmlElement

QML_IMPORT_NAME = "com.example.counter"
QML_IMPORT_MAJOR_VERSION = 1

_HISTORY_MAX = 5  # how many past values to keep


@QmlElement
class Counter(QObject):
    """
    A simple integer counter with history tracking.

    Properties
    ----------
    value : int
        Current counter value (minimum 0).  Notifies valueChanged(int).
    history : list
        The last _HISTORY_MAX recorded values as a QVariantList.
        Notifies historyChanged.

    Slots
    -----
    increment()   – add 1
    decrement()   – subtract 1 (clamped at 0)
    reset()       – set value to 0
    setValue(int) – set an arbitrary value (clamped at 0)
    """

    # ------------------------------------------------------------------
    # Signals
    # ------------------------------------------------------------------
    valueChanged = Signal(int)
    historyChanged = Signal()

    # ------------------------------------------------------------------
    # Constructor
    # ------------------------------------------------------------------
    def __init__(self, parent: QObject = None) -> None:
        super().__init__(parent)
        self._value: int = 0
        self._history: list[int] = [0]

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------
    def _set_value(self, new_value: int) -> None:
        """Clamp to >= 0, update history, and emit signals as needed."""
        clamped = max(0, new_value)
        if clamped == self._value:
            return
        self._value = clamped
        self._history.append(clamped)
        # Keep only the last _HISTORY_MAX entries
        if len(self._history) > _HISTORY_MAX:
            self._history = self._history[-_HISTORY_MAX:]
        self.valueChanged.emit(self._value)
        self.historyChanged.emit()

    # ------------------------------------------------------------------
    # Properties
    # ------------------------------------------------------------------
    @Property(int, notify=valueChanged)
    def value(self) -> int:
        return self._value

    @Property("QVariantList", notify=historyChanged)
    def history(self) -> list:
        """Return a copy of the history list as a QVariantList."""
        return list(self._history)

    # ------------------------------------------------------------------
    # Slots
    # ------------------------------------------------------------------
    @Slot()
    def increment(self) -> None:
        """Add 1 to the current value."""
        self._set_value(self._value + 1)

    @Slot()
    def decrement(self) -> None:
        """Subtract 1 from the current value (minimum 0)."""
        self._set_value(self._value - 1)

    @Slot()
    def reset(self) -> None:
        """Reset the counter to 0 and clear history."""
        self._value = 0
        self._history = [0]
        self.valueChanged.emit(0)
        self.historyChanged.emit()

    @Slot(int)
    def setValue(self, new_value: int) -> None:  # noqa: N802
        """Set the counter to an explicit value (clamped at 0)."""
        self._set_value(new_value)
