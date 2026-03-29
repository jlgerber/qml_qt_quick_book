#pragma once

#include <QObject>
#include <QProperty>
#include <QString>
#include <QtQml/qqmlregistration.h>

// TemperatureConverter keeps Celsius and Fahrenheit in sync via
// Qt Bindable Properties (Q_OBJECT_BINDABLE_PROPERTY).  Kelvin is
// a read-only computed value derived from Celsius.
//
// QML_ELEMENT registers this type in the "com.example.types" module
// so QML can instantiate it as:
//   TemperatureConverter { id: conv }
class TemperatureConverter : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    // Celsius — the primary storage; all conversions are derived from it.
    Q_PROPERTY(double celsius
               READ celsius WRITE setCelsius
               NOTIFY celsiusChanged
               BINDABLE bindableCelsius)

    // Fahrenheit — kept in sync with celsius via a bidirectional binding.
    Q_PROPERTY(double fahrenheit
               READ fahrenheit WRITE setFahrenheit
               NOTIFY fahrenheitChanged
               BINDABLE bindableFahrenheit)

    // Kelvin — read-only; always computed from celsius.
    Q_PROPERTY(double kelvin
               READ kelvin
               NOTIFY kelvinChanged)

public:
    explicit TemperatureConverter(QObject *parent = nullptr);

    // --- celsius ---
    double celsius() const;
    void   setCelsius(double value);
    QBindable<double> bindableCelsius();

    // --- fahrenheit ---
    double fahrenheit() const;
    void   setFahrenheit(double value);
    QBindable<double> bindableFahrenheit();

    // --- kelvin (read-only) ---
    double kelvin() const;

    // Q_INVOKABLE: callable from QML as conv.formatCelsius()
    Q_INVOKABLE QString formatCelsius() const;

signals:
    void celsiusChanged();
    void fahrenheitChanged();
    void kelvinChanged();

private:
    // Primary storage — everything is derived from m_celsius.
    Q_OBJECT_BINDABLE_PROPERTY_WITH_ARGS(TemperatureConverter, double,
                                          m_celsius, 0.0,
                                          &TemperatureConverter::celsiusChanged)

    // m_fahrenheit is kept in sync via a computed binding set in the ctor.
    Q_OBJECT_BINDABLE_PROPERTY_WITH_ARGS(TemperatureConverter, double,
                                          m_fahrenheit, 32.0,
                                          &TemperatureConverter::fahrenheitChanged)

    // Computed property — no direct storage needed; backed by a binding.
    Q_OBJECT_COMPUTED_PROPERTY(TemperatureConverter, double,
                                m_kelvin,
                                &TemperatureConverter::kelvin)
};
