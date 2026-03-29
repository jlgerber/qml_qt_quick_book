#include "counter.h"

Counter::Counter(QObject *parent)
    : QObject(parent)
{
    // m_value initialised to 0 in the header; boundary flags already correct.
}

int Counter::value() const
{
    return m_value;
}

bool Counter::atMinimum() const
{
    return m_atMinimum;
}

bool Counter::atMaximum() const
{
    return m_atMaximum;
}

void Counter::setValue(int newValue)
{
    const int clamped = qBound(k_min, newValue, k_max);
    if (clamped == m_value)
        return;

    m_value = clamped;
    emit valueChanged(m_value);
    updateBoundaryFlags();
}

void Counter::increment()
{
    if (m_value < k_max)
        setValue(m_value + 1);
}

void Counter::decrement()
{
    if (m_value > k_min)
        setValue(m_value - 1);
}

void Counter::reset()
{
    setValue(k_min);
}

// ------------------------------------------------------------------
// private helpers
// ------------------------------------------------------------------

void Counter::updateBoundaryFlags()
{
    const bool nowMin = (m_value == k_min);
    const bool nowMax = (m_value == k_max);

    if (nowMin != m_atMinimum) {
        m_atMinimum = nowMin;
        emit atMinimumChanged(m_atMinimum);
    }

    if (nowMax != m_atMaximum) {
        m_atMaximum = nowMax;
        emit atMaximumChanged(m_atMaximum);
    }
}
