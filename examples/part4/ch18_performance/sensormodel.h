#pragma once

#include <QAbstractListModel>
#include <QTimer>
#include <vector>
#include <QtQml/qqmlregistration.h>

// SensorModel — demonstrates *batched* model updates.
//
// A high-frequency source timer fires every 1 ms, pushing readings to a
// pendingBuffer.  A lower-frequency flush timer fires every 16 ms (~60 fps).
// flushUpdates() inserts the accumulated batch into the model in a single
// beginInsertRows / endInsertRows pair, then trims the list to 100 entries.
// This means the view receives at most one layout notification per frame
// regardless of how fast the sensor produces data.
//
// Key properties exposed to QML:
//   updateCount  — how many flush() calls have completed (diagnostic)
//   pendingCount — how many readings are waiting in the buffer (diagnostic)
class SensorModel : public QAbstractListModel
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(int updateCount  READ updateCount  NOTIFY updateCountChanged)
    Q_PROPERTY(int pendingCount READ pendingCount NOTIFY pendingCountChanged)

public:
    static constexpr int k_maxReadings   = 100;
    static constexpr int k_sourceIntervalMs = 1;   // 1 kHz synthetic sensor
    static constexpr int k_flushIntervalMs  = 16;  // ~60 fps flush cadence

    enum SensorRole {
        ValueRole = Qt::UserRole + 1
    };

    explicit SensorModel(QObject *parent = nullptr);

    // QAbstractListModel interface
    int      rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    int updateCount()  const;
    int pendingCount() const;

    Q_INVOKABLE void startUpdates();
    Q_INVOKABLE void stopUpdates();

signals:
    void updateCountChanged(int updateCount);
    void pendingCountChanged(int pendingCount);

private slots:
    void onNewReading();   // 1 ms source timer
    void flushUpdates();   // 16 ms flush timer

private:
    std::vector<double> m_readings;       // committed, displayed data
    std::vector<double> m_pendingBuffer;  // accumulated since last flush

    QTimer m_sourceTimer;
    QTimer m_flushTimer;

    int  m_updateCount  = 0;
    int  m_prevPending  = 0;   // track changes for pendingCountChanged
    double m_time       = 0.0; // pseudo-time for synthetic waveform
};
