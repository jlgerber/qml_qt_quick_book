#pragma once

#include <QAbstractListModel>
#include <QString>
#include <QList>
#include <QtQml/qqmlregistration.h>

// ---------------------------------------------------------------------------
// Task — plain data struct that represents a single to-do item.
// ---------------------------------------------------------------------------
struct Task
{
    QString title;
    bool    done     = false;
    int     priority = 1;   // 1 = low, 2 = medium, 3 = high
};

// ---------------------------------------------------------------------------
// TaskModel — a QAbstractListModel that owns a list of Task items.
//
// QML_ELEMENT makes this type available inside the "com.example.models"
// module so QML can hold a reference to it via a property.
// ---------------------------------------------------------------------------
class TaskModel : public QAbstractListModel
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("TaskModel is created in C++ and passed to QML.")

public:
    // Custom roles returned by roleNames().
    enum TaskRole {
        TitleRole    = Qt::UserRole + 1,
        DoneRole,
        PriorityRole
    };
    Q_ENUM(TaskRole)

    explicit TaskModel(QObject *parent = nullptr);

    // QAbstractListModel interface
    int      rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    bool     setData(const QModelIndex &index, const QVariant &value, int role) override;
    Qt::ItemFlags flags(const QModelIndex &index) const override;
    QHash<int, QByteArray> roleNames() const override;

    // Mutating operations exposed to QML.
    Q_INVOKABLE void addTask(const QString &title, bool done = false, int priority = 1);
    Q_INVOKABLE void removeTask(int row);
    Q_INVOKABLE void setDone(int row, bool done);

private:
    QList<Task> m_tasks;
};
