#include "temperature.h"

#include <cmath>

TemperatureConverter::TemperatureConverter(QObject *parent)
    : QObject(parent)
{
    // Keep fahrenheit in sync whenever celsius changes.
    // The lambda captures 'this' and returns the new fahrenheit value.
    m_fahrenheit.setBinding([this]() -> double {
        return m_celsius.value() * 9.0 / 5.0 + 32.0;
    });

    // kelvinChanged must fire whenever celsius changes so that QML
    // property bindings that read kelvin are re-evaluated.
    connect(this, &TemperatureConverter::celsiusChanged,
            this, &TemperatureConverter::kelvinChanged);
}

// --- celsius ----------------------------------------------------------------

double TemperatureConverter::celsius() const
{
    return m_celsius.value();
}

void TemperatureConverter::setCelsius(double value)
{
    if (qFuzzyCompare(m_celsius.value(), value))
        return;

    // Break any existing binding so the value can be set directly.
    m_celsius.setValue(value);
}

QBindable<double> TemperatureConverter::bindableCelsius()
{
    return QBindable<double>(&m_celsius);
}

// --- fahrenheit -------------------------------------------------------------

double TemperatureConverter::fahrenheit() const
{
    return m_fahrenheit.value();
}

void TemperatureConverter::setFahrenheit(double value)
{
    if (qFuzzyCompare(m_fahrenheit.value(), value))
        return;

    // Setting fahrenheit from the outside: derive the new celsius value
    // and break the fahrenheit binding so the user-supplied value is kept.
    m_fahrenheit.setValue(value);

    // Update celsius without triggering a recursive loop.
    const double newCelsius = (value - 32.0) * 5.0 / 9.0;
    if (!qFuzzyCompare(m_celsius.value(), newCelsius))
        m_celsius.setValue(newCelsius);

    // Restore the one-way binding from celsius -> fahrenheit so that
    // future celsius changes propagate again.
    m_fahrenheit.setBinding([this]() -> double {
        return m_celsius.value() * 9.0 / 5.0 + 32.0;
    });
}

QBindable<double> TemperatureConverter::bindableFahrenheit()
{
    return QBindable<double>(&m_fahrenheit);
}

// --- kelvin (computed) -------------------------------------------------------

double TemperatureConverter::kelvin() const
{
    return m_celsius.value() + 273.15;
}

// --- Q_INVOKABLE -------------------------------------------------------------

QString TemperatureConverter::formatCelsius() const
{
    return QStringLiteral("%1 °C").arg(m_celsius.value(), 0, 'f', 1);
}
