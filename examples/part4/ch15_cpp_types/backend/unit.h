#pragma once

#include <QObject>
#include <QtQml/qqmlregistration.h>

// ---------------------------------------------------------------------------
// TempUnit namespace — exposes an enum to QML via Q_ENUM_NS / QML_ELEMENT.
//
// Usage in QML:
//   import com.example.types
//   TempUnit.Celsius   // → 0
//   TempUnit.Fahrenheit // → 1
//   TempUnit.Kelvin    // → 2
// ---------------------------------------------------------------------------
namespace TempUnit {
    Q_NAMESPACE
    QML_ELEMENT

    enum Unit {
        Celsius    = 0,
        Fahrenheit = 1,
        Kelvin     = 2
    };
    Q_ENUM_NS(Unit)
}

// ---------------------------------------------------------------------------
// TemperatureReading — a Q_GADGET value type usable as a QML value type.
//
// Declared with QML_VALUE_TYPE so QML can use it as a plain value
// (no QObject overhead, copyable).  Properties are exposed via MEMBER.
//
// Usage in QML (after registering the module):
//   var reading = temperatureReading   // default-constructed
//   reading.value = 36.6
//   reading.unit  = TempUnit.Celsius
// ---------------------------------------------------------------------------
struct TemperatureReading
{
    Q_GADGET
    QML_VALUE_TYPE(temperatureReading)

    Q_PROPERTY(double value  MEMBER value)
    Q_PROPERTY(int    unit   MEMBER unit)
    Q_PROPERTY(QString label MEMBER label)

public:
    double  value = 0.0;
    int     unit  = TempUnit::Celsius;  // stores TempUnit::Unit as int
    QString label;

    // Q_INVOKABLE members on gadgets are callable from QML too.
    Q_INVOKABLE QString toString() const
    {
        const QString unitStr = (unit == TempUnit::Fahrenheit) ? QStringLiteral("°F")
                              : (unit == TempUnit::Kelvin)     ? QStringLiteral("K")
                                                               : QStringLiteral("°C");
        return QStringLiteral("%1 %2").arg(value, 0, 'f', 1).arg(unitStr);
    }
};
