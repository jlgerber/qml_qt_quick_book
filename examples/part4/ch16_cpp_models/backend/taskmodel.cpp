#include "taskmodel.h"

TaskModel::TaskModel(QObject *parent)
    : QAbstractListModel(parent)
{}

int TaskModel::rowCount(const QModelIndex &parent) const
{
    // A list model should return 0 for any valid parent index.
    if (parent.isValid())
        return 0;
    return static_cast<int>(m_tasks.size());
}

QVariant TaskModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_tasks.size())
        return {};

    const Task &task = m_tasks.at(index.row());

    switch (static_cast<TaskRole>(role)) {
        case TitleRole:    return task.title;
        case DoneRole:     return task.done;
        case PriorityRole: return task.priority;
        default:           return {};
    }
}

bool TaskModel::setData(const QModelIndex &index, const QVariant &value, int role)
{
    if (!index.isValid() || index.row() >= m_tasks.size())
        return false;

    Task &task = m_tasks[index.row()];
    bool changed = false;

    switch (static_cast<TaskRole>(role)) {
        case DoneRole:
            if (task.done != value.toBool()) {
                task.done = value.toBool();
                changed = true;
            }
            break;
        case PriorityRole:
            if (task.priority != value.toInt()) {
                task.priority = value.toInt();
                changed = true;
            }
            break;
        default:
            break;
    }

    if (changed)
        emit dataChanged(index, index, {role});

    return changed;
}

Qt::ItemFlags TaskModel::flags(const QModelIndex &index) const
{
    if (!index.isValid())
        return Qt::NoItemFlags;
    return Qt::ItemIsEnabled | Qt::ItemIsSelectable | Qt::ItemIsEditable;
}

QHash<int, QByteArray> TaskModel::roleNames() const
{
    return {
        { TitleRole,    "title"    },
        { DoneRole,     "done"     },
        { PriorityRole, "priority" }
    };
}

// ---------------------------------------------------------------------------
// Q_INVOKABLE helpers
// ---------------------------------------------------------------------------

void TaskModel::addTask(const QString &title, bool done, int priority)
{
    if (title.trimmed().isEmpty())
        return;

    const int row = static_cast<int>(m_tasks.size());
    beginInsertRows({}, row, row);
    m_tasks.append(Task{ title.trimmed(), done, priority });
    endInsertRows();
}

void TaskModel::removeTask(int row)
{
    if (row < 0 || row >= m_tasks.size())
        return;

    beginRemoveRows({}, row, row);
    m_tasks.removeAt(row);
    endRemoveRows();
}

void TaskModel::setDone(int row, bool done)
{
    if (row < 0 || row >= m_tasks.size())
        return;

    setData(index(row), done, DoneRole);
}
