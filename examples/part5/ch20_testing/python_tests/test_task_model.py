"""
Chapter 20 – PySide6 / pytest test suite for TaskModel

Run with:
    cd python_tests
    pytest -v

Requirements:
    pip install pytest pytest-qt

pytest-qt provides the ``qtbot`` fixture, which:
  - Creates (or reuses) the QApplication singleton for the test session.
  - Offers ``qtbot.waitSignal`` to block until a signal fires and capture
    its arguments.
  - Offers ``qtbot.assertNotEmitted`` to assert a signal is never fired
    inside a block.
"""

from __future__ import annotations

import pytest

from task_model import TaskModel


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

@pytest.fixture()
def model():
    """Return a fresh TaskModel for each test function."""
    return TaskModel()


def _populate(model: TaskModel) -> list[str]:
    """Add three tasks and return their UUIDs — mirrors populateThreeTasks() in C++."""
    return [
        model.addTask("Buy groceries"),
        model.addTask("Write unit tests"),
        model.addTask("Read Qt docs"),
    ]


# ---------------------------------------------------------------------------
# Initial state
# ---------------------------------------------------------------------------

def test_initially_empty(model):
    assert model.rowCount() == 0


# ---------------------------------------------------------------------------
# addTask
# ---------------------------------------------------------------------------

def test_add_task(model):
    task_id = model.addTask("Buy milk")

    assert model.rowCount() == 1
    assert model.data(model.index(0), TaskModel.TitleRole) == "Buy milk"
    assert model.data(model.index(0), TaskModel.DoneRole)  is False
    assert task_id != ""


def test_add_multiple_tasks(model):
    model.addTask("First")
    model.addTask("Second")

    assert model.rowCount() == 2
    assert model.data(model.index(0), TaskModel.TitleRole) == "First"
    assert model.data(model.index(1), TaskModel.TitleRole) == "Second"


# ---------------------------------------------------------------------------
# removeTask
# ---------------------------------------------------------------------------

def test_remove_task(model):
    ids = _populate(model)

    # Remove middle item
    assert model.removeTask(ids[1]) is True
    assert model.rowCount() == 2
    assert model.data(model.index(0), TaskModel.TitleRole) == "Buy groceries"
    assert model.data(model.index(1), TaskModel.TitleRole) == "Read Qt docs"

    # Unknown id returns False and leaves the model unchanged
    assert model.removeTask("does-not-exist") is False
    assert model.rowCount() == 2

    # Remove remaining items
    assert model.removeTask(ids[0]) is True
    assert model.removeTask(ids[2]) is True
    assert model.rowCount() == 0


# ---------------------------------------------------------------------------
# setDone
# ---------------------------------------------------------------------------

def test_set_done(model):
    task_id = model.addTask("Take out trash")

    assert model.data(model.index(0), TaskModel.DoneRole) is False

    assert model.setDone(task_id, True)  is True
    assert model.data(model.index(0), TaskModel.DoneRole) is True

    assert model.setDone(task_id, False) is True
    assert model.data(model.index(0), TaskModel.DoneRole) is False


def test_set_done_unknown_id_returns_false(model):
    model.addTask("Stays untouched")
    assert model.setDone("no-such-id", True) is False
    assert model.data(model.index(0), TaskModel.DoneRole) is False


# ---------------------------------------------------------------------------
# Signal tests — rowsInserted
# ---------------------------------------------------------------------------

def test_add_task_rows_inserted_signal(qtbot, model):
    with qtbot.waitSignal(model.rowsInserted, timeout=1000) as blocker:
        model.addTask("First")

    _parent, first, last = blocker.args
    assert first == 0
    assert last  == 0

    # Second insert goes to row 1
    with qtbot.waitSignal(model.rowsInserted, timeout=1000) as blocker:
        model.addTask("Second")

    _parent, first, last = blocker.args
    assert first == 1
    assert last  == 1


# ---------------------------------------------------------------------------
# Signal tests — rowsRemoved
# ---------------------------------------------------------------------------

def test_remove_task_rows_removed_signal(qtbot, model):
    ids = _populate(model)

    with qtbot.waitSignal(model.rowsRemoved, timeout=1000) as blocker:
        model.removeTask(ids[0])

    _parent, first, last = blocker.args
    assert first == 0
    assert last  == 0


# ---------------------------------------------------------------------------
# Signal tests — dataChanged
# ---------------------------------------------------------------------------

def test_data_changed_emits_done_role(qtbot, model):
    task_id = model.addTask("Attend standup")

    with qtbot.waitSignal(model.dataChanged, timeout=1000) as blocker:
        model.setDone(task_id, True)

    top_left, bottom_right, roles = blocker.args
    assert top_left.row()     == 0
    assert bottom_right.row() == 0
    # Only DoneRole should be in the changed-roles list
    assert TaskModel.DoneRole  in roles
    assert TaskModel.TitleRole not in roles
    assert TaskModel.IdRole    not in roles


# ---------------------------------------------------------------------------
# Model integrity — QAbstractItemModelTester
# ---------------------------------------------------------------------------

def test_model_integrity(model):
    """
    QAbstractItemModelTester attaches to the model and runs an exhaustive
    suite of invariant checks after every mutation — beginInsertRows /
    endInsertRows symmetry, valid index ranges, correct parent() returns, etc.
    Any violation raises immediately, so this test exercises all mutations
    while the tester watches.
    """
    from PySide6.QtTest import QAbstractItemModelTester

    tester = QAbstractItemModelTester(
        model,
        QAbstractItemModelTester.FailureReportingMode.Fatal,
    )

    id1 = model.addTask("Alpha")
    id2 = model.addTask("Beta")
    id3 = model.addTask("Gamma")

    model.setDone(id1, True)
    model.setDone(id2, True)

    model.removeTask(id2)
    model.addTask("Delta")
    model.setDone(id3, True)
    model.removeTask(id1)
    model.removeTask(id3)
