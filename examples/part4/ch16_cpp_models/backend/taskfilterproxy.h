#pragma once

#include <QSortFilterProxyModel>
#include <QtQml/qqmlregistration.h>

// TaskFilterProxy wraps a TaskModel and hides completed tasks when
// showDoneItems is false.  The proxy is transparent otherwise.
//
// QML_ELEMENT makes it available inside "com.example.models".
class TaskFilterProxy : public QSortFilterProxyModel
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("TaskFilterProxy is created in C++ and passed to QML.")

    Q_PROPERTY(bool showDoneItems
               READ  showDoneItems
               WRITE setShowDoneItems
               NOTIFY showDoneItemsChanged)

public:
    explicit TaskFilterProxy(QObject *parent = nullptr);

    bool showDoneItems() const;
    void setShowDoneItems(bool show);

signals:
    void showDoneItemsChanged(bool showDoneItems);

protected:
    bool filterAcceptsRow(int sourceRow,
                          const QModelIndex &sourceParent) const override;

private:
    bool m_showDoneItems = true;
};
