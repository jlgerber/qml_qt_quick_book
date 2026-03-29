#include "taskfilterproxy.h"
#include "taskmodel.h"

TaskFilterProxy::TaskFilterProxy(QObject *parent)
    : QSortFilterProxyModel(parent)
{}

bool TaskFilterProxy::showDoneItems() const
{
    return m_showDoneItems;
}

void TaskFilterProxy::setShowDoneItems(bool show)
{
    if (m_showDoneItems == show)
        return;

    m_showDoneItems = show;
    emit showDoneItemsChanged(m_showDoneItems);

    // Trigger a re-evaluation of every row.
    invalidateFilter();
}

bool TaskFilterProxy::filterAcceptsRow(int sourceRow,
                                        const QModelIndex &sourceParent) const
{
    // When showDoneItems is true we accept every row unconditionally.
    if (m_showDoneItems)
        return true;

    // Otherwise, hide rows where done == true.
    const QModelIndex idx = sourceModel()->index(sourceRow, 0, sourceParent);
    const bool done = sourceModel()->data(idx, TaskModel::DoneRole).toBool();
    return !done;
}
