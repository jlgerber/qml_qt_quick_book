# Chapter 16: C++ Models and Data Pipelines

## High-Performance `QAbstractItemModel` Implementations

The C++ implementation of `QAbstractItemModel` gives full control over data layout, change notification granularity, and memory management — enabling models that outperform Python equivalents by an order of magnitude for large datasets.

### Template Pattern for List Models

Most application list models share the same structural boilerplate. A base template reduces repetition:

```cpp
// listmodelbase.h
#pragma once
#include <QAbstractListModel>
#include <vector>

template<typename T>
class ListModelBase : public QAbstractListModel
{
public:
    explicit ListModelBase(QObject *parent = nullptr)
        : QAbstractListModel(parent) {}

    int rowCount(const QModelIndex &parent = QModelIndex()) const override {
        return parent.isValid() ? 0 : static_cast<int>(m_items.size());
    }

    void setItems(std::vector<T> items) {
        beginResetModel();
        m_items = std::move(items);
        endResetModel();
    }

    void appendItem(T item) {
        const int row = static_cast<int>(m_items.size());
        beginInsertRows(QModelIndex(), row, row);
        m_items.push_back(std::move(item));
        endInsertRows();
    }

    void removeItem(int row) {
        if (row < 0 || row >= static_cast<int>(m_items.size()))
            return;
        beginRemoveRows(QModelIndex(), row, row);
        m_items.erase(m_items.begin() + row);
        endRemoveRows();
    }

    void updateItem(int row, T item) {
        if (row < 0 || row >= static_cast<int>(m_items.size()))
            return;
        m_items[row] = std::move(item);
        const QModelIndex idx = index(row);
        emit dataChanged(idx, idx);
    }

protected:
    std::vector<T> m_items;
};
```

Concrete model inherits and adds roles:

```cpp
// contactmodel.h
struct Contact {
    QString name;
    QString email;
    QUrl avatarUrl;
};

class ContactModel : public ListModelBase<Contact>
{
    Q_OBJECT
    QML_ELEMENT

public:
    enum Roles {
        NameRole = Qt.UserRole + 1,
        EmailRole,
        AvatarUrlRole
    };
    Q_ENUM(Roles)

    explicit ContactModel(QObject *parent = nullptr);

    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;
};
```

```cpp
// contactmodel.cpp
QHash<int, QByteArray> ContactModel::roleNames() const {
    return {
        {NameRole,     "name"},
        {EmailRole,    "email"},
        {AvatarUrlRole, "avatar"},
    };
}

QVariant ContactModel::data(const QModelIndex &index, int role) const {
    if (!index.isValid() || index.row() >= static_cast<int>(m_items.size()))
        return {};

    const Contact &c = m_items[index.row()];
    switch (role) {
    case NameRole:     return c.name;
    case EmailRole:    return c.email;
    case AvatarUrlRole: return c.avatarUrl;
    case Qt::DisplayRole: return c.name;
    default: return {};
    }
}
```

### Minimizing `dataChanged` Overhead

`dataChanged(topLeft, bottomRight, roles)` takes a roles list as the third argument. When roles is empty, the view assumes all roles changed and re-queries all of them. Specify roles precisely:

```cpp
void ContactModel::updateEmail(int row, const QString &email) {
    if (row < 0 || row >= static_cast<int>(m_items.size()))
        return;
    if (m_items[row].email == email)
        return;
    m_items[row].email = email;
    const QModelIndex idx = index(row);
    emit dataChanged(idx, idx, {EmailRole});  // only EmailRole changed
}
```

For bulk updates (e.g., updating a status field on all items), batch the change:

```cpp
void ContactModel::markAllAsRead() {
    if (m_items.empty()) return;
    for (auto &c : m_items)
        c.unread = false;
    emit dataChanged(index(0), index(rowCount() - 1), {UnreadRole});
}
```

---

## Role-Based Data, `QSortFilterProxyModel`, and Custom Proxy Chains

### `QSortFilterProxyModel`

`QSortFilterProxyModel` wraps any `QAbstractItemModel` and provides sorting and filtering without copying data. The view uses the proxy; the proxy delegates to the source model.

```cpp
// Setup in C++
auto *source = new ContactModel(this);
auto *proxy = new QSortFilterProxyModel(this);
proxy->setSourceModel(source);
proxy->setSortRole(ContactModel::NameRole);
proxy->setFilterRole(ContactModel::NameRole);
proxy->setFilterCaseSensitivity(Qt::CaseInsensitive);
proxy->sort(0, Qt::AscendingOrder);
```

```qml
// In QML
TextField {
    onTextChanged: contactProxy.setFilterFixedString(text)
}

ListView {
    model: contactProxy   // the proxy, not the source
}
```

### Custom `QSortFilterProxyModel`

For multi-field filtering, subclass and override `filterAcceptsRow`:

```cpp
class ContactFilterProxy : public QSortFilterProxyModel
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QString nameFilter READ nameFilter
               WRITE setNameFilter NOTIFY nameFilterChanged)
    Q_PROPERTY(bool showFavoritesOnly READ showFavoritesOnly
               WRITE setShowFavoritesOnly NOTIFY showFavoritesOnlyChanged)

public:
    bool filterAcceptsRow(int row, const QModelIndex &parent) const override {
        const QModelIndex idx = sourceModel()->index(row, 0, parent);
        const QString name = sourceModel()->data(idx, ContactModel::NameRole).toString();
        const bool fav = sourceModel()->data(idx, ContactModel::FavoriteRole).toBool();

        if (m_showFavoritesOnly && !fav)
            return false;
        if (!m_nameFilter.isEmpty() &&
            !name.contains(m_nameFilter, Qt::CaseInsensitive))
            return false;

        return true;
    }

    bool lessThan(const QModelIndex &left, const QModelIndex &right) const override {
        const QString lName = sourceModel()->data(left, ContactModel::NameRole).toString();
        const QString rName = sourceModel()->data(right, ContactModel::NameRole).toString();
        return lName.localeAwareCompare(rName) < 0;
    }

    // ... property accessors and signals
};
```

### Proxy Chains

Proxies can be chained — the output of one proxy feeds into another:

```
Source Model
    │
    ▼
FilterProxy (apply search filter)
    │
    ▼
SortProxy (sort by name)
    │
    ▼
GroupingProxy (add section headers)
    │
    ▼
ListView
```

Each proxy is a `QAbstractItemModel` from the next proxy's perspective. This is a powerful composition model for building complex data pipelines without modifying the source model.

---

## Feeding Live Data: Worker Threads, `QFuture`, and `QPromise`

### `QFuture` and `QtConcurrent`

`QtConcurrent` provides high-level APIs for running work on a thread pool and monitoring results via `QFuture`:

```cpp
#include <QtConcurrent/QtConcurrent>

class SearchModel : public QAbstractListModel
{
    Q_OBJECT
    QML_ELEMENT

public:
    Q_INVOKABLE void search(const QString &query) {
        // Cancel any running search
        if (m_watcher.isRunning()) {
            m_future.cancel();
            m_watcher.waitForFinished();
        }

        m_future = QtConcurrent::run([query]() -> QList<SearchResult> {
            return performExpensiveSearch(query);  // runs on thread pool
        });

        m_watcher.setFuture(m_future);
    }

private slots:
    void onSearchFinished() {
        if (m_future.isCanceled())
            return;
        setResults(m_future.result());
    }

private:
    void setResults(const QList<SearchResult> &results) {
        beginResetModel();
        m_results = results;
        endResetModel();
    }

    QFuture<QList<SearchResult>> m_future;
    QFutureWatcher<QList<SearchResult>> m_watcher{this};
    QList<SearchResult> m_results;

    // Constructor connects watcher:
    // connect(&m_watcher, &QFutureWatcher<...>::finished, this,
    //         &SearchModel::onSearchFinished);
};
```

`QFutureWatcher` emits signals on the main thread even though the work runs on a pool thread — the connection is automatically a `QueuedConnection`.

### `QPromise` for Progressive Results

`QPromise` (Qt 6.0+) allows a worker to push results incrementally as they become available:

```cpp
Q_INVOKABLE void loadProgressively(const QStringList &urls) {
    QPromise<ImageData> promise;
    m_future = promise.future();

    // Watch for progressive results
    connect(&m_watcher, &QFutureWatcher<ImageData>::resultReadyAt,
            this, [this](int index) {
                // Called on main thread each time a result is pushed
                appendItem(m_watcher.resultAt(index));
            });
    m_watcher.setFuture(m_future);

    // Run the work
    QtConcurrent::run([urls, p = std::move(promise)]() mutable {
        p.start();
        for (const QString &url : urls) {
            if (p.isCanceled()) break;
            ImageData data = downloadAndDecode(url);
            p.addResult(std::move(data));
        }
        p.finish();
    });
}
```

As each image loads, `resultReadyAt` fires on the main thread and `appendItem` inserts it into the model. The view updates incrementally — users see content appear as it arrives.

### Timer-Driven Live Data

For sensor data, log tailing, or real-time dashboards, a `QTimer` drives periodic model updates:

```cpp
class TelemetryModel : public QAbstractListModel
{
    Q_OBJECT
    QML_ELEMENT

public:
    explicit TelemetryModel(QObject *parent = nullptr) : QAbstractListModel(parent) {
        m_timer.setInterval(100);   // 10 Hz
        connect(&m_timer, &QTimer::timeout, this, &TelemetryModel::onTick);
    }

    Q_INVOKABLE void start() { m_timer.start(); }
    Q_INVOKABLE void stop()  { m_timer.stop(); }

private slots:
    void onTick() {
        // Read new data from a lock-free queue filled by a hardware thread
        QList<TelemetryPoint> batch;
        m_queue.drainTo(batch);

        if (batch.isEmpty())
            return;

        // Trim old data
        const int maxRows = 1000;
        if (m_data.size() + batch.size() > maxRows) {
            const int toRemove = m_data.size() + batch.size() - maxRows;
            beginRemoveRows(QModelIndex(), 0, toRemove - 1);
            m_data.erase(m_data.begin(), m_data.begin() + toRemove);
            endRemoveRows();
        }

        // Append new batch
        const int first = m_data.size();
        beginInsertRows(QModelIndex(), first, first + batch.size() - 1);
        m_data.append(batch);
        endInsertRows();
    }

    QTimer m_timer;
    LockFreeQueue<TelemetryPoint> m_queue;   // filled by hardware thread
    QList<TelemetryPoint> m_data;
};
```

### Thread Safety for Model Data

The golden rule: the model's `data()`, `rowCount()`, `beginInsertRows()`, and all other interface methods must be called from the main thread only. Worker threads write to a staging buffer (a queue, a local `std::vector`) and post to the main thread.

For the lock-free queue pattern above:
- Hardware/network thread: pushes to `m_queue` (lock-free)
- Main thread timer: drains `m_queue` and mutates the model

This pattern gives sub-millisecond latency from data arrival to model update, with no main-thread blocking.

---

## Summary

High-performance C++ models use `std::vector` for data storage (cache-friendly, O(1) random access), precise role-based `dataChanged` notifications, and the begin/end mutation API for incremental updates. `QSortFilterProxyModel` and custom proxy chains compose filtering, sorting, and grouping without touching the source model. `QtConcurrent` and `QPromise` provide ergonomic patterns for off-thread data loading with automatic main-thread delivery via `QFutureWatcher`. Timer-driven models with lock-free staging queues serve real-time data scenarios. Together, these patterns support models that remain smooth and responsive at any data scale.
