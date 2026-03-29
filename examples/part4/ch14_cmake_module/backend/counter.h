#pragma once

#include <QObject>
#include <QtQml/qqmlregistration.h>

// Counter exposes an integer value bounded between 0 and 99.
// QML_ELEMENT causes qt_add_qml_module to auto-register this type
// under the "com.example.backend" URI so QML can instantiate it directly.
class Counter : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(int value READ value WRITE setValue NOTIFY valueChanged)
    Q_PROPERTY(bool atMinimum READ atMinimum NOTIFY atMinimumChanged)
    Q_PROPERTY(bool atMaximum READ atMaximum NOTIFY atMaximumChanged)

public:
    explicit Counter(QObject *parent = nullptr);

    int  value()     const;
    bool atMinimum() const;
    bool atMaximum() const;

    void setValue(int newValue);

public slots:
    void increment();
    void decrement();
    void reset();

signals:
    void valueChanged(int value);
    void atMinimumChanged(bool atMinimum);
    void atMaximumChanged(bool atMaximum);

private:
    static constexpr int k_min = 0;
    static constexpr int k_max = 99;

    int  m_value     = 0;
    bool m_atMinimum = true;
    bool m_atMaximum = false;

    void updateBoundaryFlags();
};
