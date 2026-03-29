#pragma once

#include <QColor>
#include <QList>
#include <QQuickItem>
#include <QtQml/qqmlregistration.h>

// WaveformItem — a custom QQuickItem that renders a line-strip waveform
// directly in the Qt Quick scene graph.
//
// The item owns three user-visible properties:
//   samples   — list of float values in [0, 1] representing the waveform
//   waveColor — colour of the rendered line
//   lineWidth — stroke width in device-independent pixels
//
// Rendering is performed entirely in updatePaintNode(), which runs on the
// render thread.  The m_dirty flag coordinates between the GUI thread
// (property setters) and the render thread (updatePaintNode).
class WaveformItem : public QQuickItem
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QList<float> samples
               READ  samples
               WRITE setSamples
               NOTIFY samplesChanged)

    Q_PROPERTY(QColor waveColor
               READ  waveColor
               WRITE setWaveColor
               NOTIFY waveColorChanged)

    Q_PROPERTY(float lineWidth
               READ  lineWidth
               WRITE setLineWidth
               NOTIFY lineWidthChanged)

public:
    explicit WaveformItem(QQuickItem *parent = nullptr);

    QList<float> samples()   const;
    QColor       waveColor() const;
    float        lineWidth() const;

    void setSamples(const QList<float> &samples);
    void setWaveColor(const QColor &color);
    void setLineWidth(float width);

signals:
    void samplesChanged();
    void waveColorChanged();
    void lineWidthChanged();

protected:
    // Called by the scene-graph on the render thread to build/update the node tree.
    QSGNode *updatePaintNode(QSGNode *oldNode,
                             UpdatePaintNodeData *data) override;

    // Called on the GUI thread whenever the item's geometry changes.
    void geometryChange(const QRectF &newGeometry,
                        const QRectF &oldGeometry) override;

private:
    QList<float> m_samples;
    QColor       m_waveColor { "#00bcd4" };
    float        m_lineWidth { 2.0f };
    bool         m_dirty     { true };
};
