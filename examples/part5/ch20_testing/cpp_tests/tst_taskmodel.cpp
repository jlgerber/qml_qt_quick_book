// tst_taskmodel.cpp — QTest suite for a self-contained TaskModel
// ---------------------------------------------------------------
// Build & run:
//   cmake -S . -B build && cmake --build build
//   ./build/tst_taskmodel
//   # or via CTest:
//   ctest --test-dir build --output-on-failure
//
// The TaskModel implementation lives entirely in this file so the test
// is self-contained — no external library dependency beyond Qt.

#include <QAbstractItemModelTester>
#include <QAbstractListModel>
#include <QHash>
#include <QList>
#include <QObject>
#include <QSignalSpy>
#include <QString>
#include <QTest>
#include <QUuid>
#include <QVariant>
#include <QVector>

// ======================================================================
// Domain type
// ======================================================================

struct Task {
    QString id;
    QString title;
    bool    done = false;

    static Task create(const QString &title) {
        return { QUuid::createUuid().toString(QUuid::WithoutBraces), title, false };
    }
};

// ======================================================================
// TaskModel — minimal QAbstractListModel implementation under test
// ======================================================================

class TaskModel : public QAbstractListModel {
    Q_OBJECT

public:
    enum Roles {
        IdRole    = Qt::UserRole + 1,
        TitleRole,
        DoneRole,
    };

    explicit TaskModel(QObject *parent = nullptr)
        : QAbstractListModel(parent) {}

    // ── QAbstractListModel interface ──────────────────────────────────

    int rowCount(const QModelIndex &parent = QModelIndex()) const override {
        if (parent.isValid())
            return 0;
        return static_cast<int>(m_tasks.size());
    }

    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override {
        if (!index.isValid() || index.row() >= static_cast<int>(m_tasks.size()))
            return {};

        const Task &t = m_tasks.at(index.row());
        switch (role) {
        case IdRole:    return t.id;
        case TitleRole: return t.title;
        case DoneRole:  return t.done;
        default:        return {};
        }
    }

    QHash<int, QByteArray> roleNames() const override {
        return {
            { IdRole,    "taskId" },
            { TitleRole, "title"  },
            { DoneRole,  "done"   },
        };
    }

    // ── Mutation helpers ──────────────────────────────────────────────

    QString addTask(const QString &title) {
        Task t = Task::create(title);
        const int row = static_cast<int>(m_tasks.size());
        beginInsertRows({}, row, row);
        m_tasks.append(t);
        endInsertRows();
        return t.id;
    }

    bool removeTask(const QString &id) {
        for (int i = 0; i < m_tasks.size(); ++i) {
            if (m_tasks[i].id == id) {
                beginRemoveRows({}, i, i);
                m_tasks.removeAt(i);
                endRemoveRows();
                return true;
            }
        }
        return false;
    }

    bool setDone(const QString &id, bool done) {
        for (int i = 0; i < m_tasks.size(); ++i) {
            if (m_tasks[i].id == id) {
                m_tasks[i].done = done;
                const QModelIndex idx = index(i);
                emit dataChanged(idx, idx, { DoneRole });
                return true;
            }
        }
        return false;
    }

    // ── Convenience accessors used by tests ───────────────────────────

    QString idAt(int row) const {
        return m_tasks.at(row).id;
    }

    QString titleAt(int row) const {
        return m_tasks.at(row).title;
    }

    bool doneAt(int row) const {
        return m_tasks.at(row).done;
    }

private:
    QList<Task> m_tasks;
};

// ======================================================================
// Test class
// ======================================================================

class TestTaskModel : public QObject {
    Q_OBJECT

private:
    // ── Helpers ───────────────────────────────────────────────────────

    // Populate a fresh model with three tasks and return their ids.
    static QStringList populateThreeTasks(TaskModel &model) {
        return {
            model.addTask("Buy groceries"),
            model.addTask("Write unit tests"),
            model.addTask("Read Qt docs"),
        };
    }

private slots:

    // ── test_initiallyEmpty ───────────────────────────────────────────
    void test_initiallyEmpty() {
        TaskModel model;
        QCOMPARE(model.rowCount(), 0);
    }

    // ── test_addTask ──────────────────────────────────────────────────
    void test_addTask() {
        TaskModel model;

        QString id = model.addTask("Buy milk");
        QCOMPARE(model.rowCount(), 1);
        QCOMPARE(model.titleAt(0), QString("Buy milk"));
        QCOMPARE(model.doneAt(0),  false);
        QVERIFY(!id.isEmpty());

        model.addTask("Walk the dog");
        QCOMPARE(model.rowCount(), 2);
        QCOMPARE(model.titleAt(1), QString("Walk the dog"));
    }

    // ── test_removeTask ───────────────────────────────────────────────
    void test_removeTask() {
        TaskModel model;
        auto ids = populateThreeTasks(model);

        // Remove middle item
        QVERIFY(model.removeTask(ids[1]));
        QCOMPARE(model.rowCount(), 2);
        QCOMPARE(model.titleAt(0), QString("Buy groceries"));
        QCOMPARE(model.titleAt(1), QString("Read Qt docs"));

        // Removing a non-existent id returns false
        QVERIFY(!model.removeTask("does-not-exist"));
        QCOMPARE(model.rowCount(), 2);

        // Remove remaining items
        QVERIFY(model.removeTask(ids[0]));
        QVERIFY(model.removeTask(ids[2]));
        QCOMPARE(model.rowCount(), 0);
    }

    // ── test_setDone ──────────────────────────────────────────────────
    void test_setDone() {
        TaskModel model;
        QString id = model.addTask("Take out trash");

        QCOMPARE(model.doneAt(0), false);

        model.setDone(id, true);
        QCOMPARE(model.doneAt(0), true);

        model.setDone(id, false);
        QCOMPARE(model.doneAt(0), false);

        // Non-existent id returns false
        QVERIFY(!model.setDone("no-such-id", true));
    }

    // ── test_dataChanged_roles ────────────────────────────────────────
    void test_dataChanged_roles() {
        TaskModel model;
        QString id = model.addTask("Attend standup");

        QSignalSpy spy(&model, &TaskModel::dataChanged);
        QVERIFY(spy.isValid());

        model.setDone(id, true);

        QCOMPARE(spy.count(), 1);

        const QList<QVariant> args = spy.takeFirst();
        // args[0] = topLeft QModelIndex, args[1] = bottomRight, args[2] = roles
        const QModelIndex topLeft     = qvariant_cast<QModelIndex>(args[0]);
        const QModelIndex bottomRight = qvariant_cast<QModelIndex>(args[1]);
        const QList<int>  roles       = qvariant_cast<QVector<int>>(args[2]).toList();

        QCOMPARE(topLeft.row(),     0);
        QCOMPARE(bottomRight.row(), 0);
        QVERIFY(roles.contains(TaskModel::DoneRole));
        // Title and Id roles must NOT be in the list — only done changed
        QVERIFY(!roles.contains(TaskModel::TitleRole));
        QVERIFY(!roles.contains(TaskModel::IdRole));
    }

    // ── test_addTask_rowsInserted_signal ──────────────────────────────
    void test_addTask_rowsInserted_signal() {
        TaskModel model;

        QSignalSpy spy(&model, &TaskModel::rowsInserted);
        QVERIFY(spy.isValid());

        model.addTask("First");
        QCOMPARE(spy.count(), 1);
        const QList<QVariant> args = spy.takeFirst();
        QCOMPARE(args[1].toInt(), 0);   // first
        QCOMPARE(args[2].toInt(), 0);   // last

        model.addTask("Second");
        QCOMPARE(spy.count(), 1);
        const QList<QVariant> args2 = spy.takeFirst();
        QCOMPARE(args2[1].toInt(), 1);
        QCOMPARE(args2[2].toInt(), 1);
    }

    // ── test_removeTask_rowsRemoved_signal ────────────────────────────
    void test_removeTask_rowsRemoved_signal() {
        TaskModel model;
        auto ids = populateThreeTasks(model);

        QSignalSpy spy(&model, &TaskModel::rowsRemoved);
        QVERIFY(spy.isValid());

        model.removeTask(ids[0]);
        QCOMPARE(spy.count(), 1);
        const QList<QVariant> args = spy.takeFirst();
        QCOMPARE(args[1].toInt(), 0);
        QCOMPARE(args[2].toInt(), 0);
    }

    // ── test_modelIntegrity ───────────────────────────────────────────
    // QAbstractItemModelTester performs an exhaustive set of invariant
    // checks every time the model is mutated.
    void test_modelIntegrity() {
        TaskModel model;

        // Attach the tester — it will QFAIL automatically on any violation
        QAbstractItemModelTester tester(
            &model,
            QAbstractItemModelTester::FailureReportingMode::QtTest
        );

        // Exercise the model while the tester watches
        const QString id1 = model.addTask("Alpha");
        const QString id2 = model.addTask("Beta");
        const QString id3 = model.addTask("Gamma");

        model.setDone(id1, true);
        model.setDone(id2, true);

        model.removeTask(id2);
        model.addTask("Delta");
        model.setDone(id3, true);
        model.removeTask(id1);
        model.removeTask(id3);
    }
};

// ======================================================================
// Test runner entry point
// ======================================================================

QTEST_MAIN(TestTaskModel)

#include "tst_taskmodel.moc"
