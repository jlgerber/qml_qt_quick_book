#include "sensormodel.h"

#include <cmath>
#include <algorithm>

SensorModel::SensorModel(QObject *parent)
    : QAbstractListModel(parent)
{
    // Source timer: fires every 1 ms to simulate a high-frequency sensor.
    m_sourceTimer.setInterval(k_sourceIntervalMs);
    m_sourceTimer.setTimerType(Qt::PreciseTimer);
    connect(&m_sourceTimer, &QTimer::timeout,
            this, &SensorModel::onNewReading);

    // Flush timer: fires every ~16 ms to batch-insert into the model.
    m_flushTimer.setInterval(k_flushIntervalMs);
    m_flushTimer.setTimerType(Qt::CoarseTimer);
    connect(&m_flushTimer, &QTimer::timeout,
            this, &SensorModel::flushUpdates);
}

// ---------------------------------------------------------------------------
// QAbstractListModel interface
// ---------------------------------------------------------------------------

int SensorModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return static_cast<int>(m_readings.size());
}

QVariant SensorModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= static_cast<int>(m_readings.size()))
        return {};

    if (role == ValueRole)
        return m_readings[static_cast<std::size_t>(index.row())];

    return {};
}

QHash<int, QByteArray> SensorModel::roleNames() const
{
    return { { ValueRole, "value" } };
}

// ---------------------------------------------------------------------------
// Properties
// ---------------------------------------------------------------------------

int SensorModel::updateCount() const  { return m_updateCount; }
int SensorModel::pendingCount() const { return static_cast<int>(m_pendingBuffer.size()); }

// ---------------------------------------------------------------------------
// Public slots
// ---------------------------------------------------------------------------

void SensorModel::startUpdates()
{
    m_sourceTimer.start();
    m_flushTimer.start();
}

void SensorModel::stopUpdates()
{
    m_sourceTimer.stop();
    m_flushTimer.stop();
}

// ---------------------------------------------------------------------------
// Private slots
// ---------------------------------------------------------------------------

void SensorModel::onNewReading()
{
    // Simulate a noisy sine wave as the sensor signal.
    m_time += k_sourceIntervalMs * 0.001;  // advance by 1 ms in seconds
    const double value = 0.5
        + 0.4 * std::sin(2.0 * M_PI * 3.0 * m_time)   // 3 Hz carrier
        + 0.1 * std::sin(2.0 * M_PI * 17.0 * m_time);  // 17 Hz noise

    m_pendingBuffer.push_back(value);

    // Notify QML about the pending buffer size on every tick so the UI
    // can display it in real time.  This is intentionally a lightweight
    // signal (no model update involved).
    const int pending = static_cast<int>(m_pendingBuffer.size());
    if (pending != m_prevPending) {
        m_prevPending = pending;
        emit pendingCountChanged(pending);
    }
}

void SensorModel::flushUpdates()
{
    if (m_pendingBuffer.empty())
        return;

    // --- Insert the whole batch in one operation -------------------------
    // This produces a single dataChanged/rowsInserted notification to the
    // view, regardless of how many individual readings accumulated.

    const int insertCount = static_cast<int>(m_pendingBuffer.size());
    const int firstRow    = static_cast<int>(m_readings.size());

    beginInsertRows({}, firstRow, firstRow + insertCount - 1);
    for (double v : m_pendingBuffer)
        m_readings.push_back(v);
    endInsertRows();

    m_pendingBuffer.clear();
    emit pendingCountChanged(0);
    m_prevPending = 0;

    // --- Trim to k_maxReadings ------------------------------------------
    const int excess = static_cast<int>(m_readings.size()) - k_maxReadings;
    if (excess > 0) {
        beginRemoveRows({}, 0, excess - 1);
        m_readings.erase(m_readings.begin(),
                         m_readings.begin() + excess);
        endRemoveRows();
    }

    // --- Emit a single coarse dataChanged for the whole visible range ---
    // If the ListView is bound to index-based positions this ensures that
    // any position-relative delegates are updated in one pass.
    if (!m_readings.empty()) {
        const QModelIndex first = index(0);
        const QModelIndex last  = index(static_cast<int>(m_readings.size()) - 1);
        emit dataChanged(first, last, { ValueRole });
    }

    ++m_updateCount;
    emit updateCountChanged(m_updateCount);
}
