#include "waveformitem.h"

#include <QSGFlatColorMaterial>
#include <QSGGeometry>
#include <QSGGeometryNode>

// ---------------------------------------------------------------------------
// Constructor
// ---------------------------------------------------------------------------

WaveformItem::WaveformItem(QQuickItem *parent)
    : QQuickItem(parent)
{
    // Without this flag the item is invisible — Qt Quick will never call
    // updatePaintNode() unless the item declares it has content to render.
    setFlag(ItemHasContents, true);
}

// ---------------------------------------------------------------------------
// Property accessors
// ---------------------------------------------------------------------------

QList<float> WaveformItem::samples() const   { return m_samples; }
QColor       WaveformItem::waveColor() const { return m_waveColor; }
float        WaveformItem::lineWidth() const { return m_lineWidth; }

void WaveformItem::setSamples(const QList<float> &samples)
{
    m_samples = samples;
    m_dirty   = true;
    emit samplesChanged();
    update();   // schedule a call to updatePaintNode on the render thread
}

void WaveformItem::setWaveColor(const QColor &color)
{
    if (m_waveColor == color)
        return;
    m_waveColor = color;
    m_dirty     = true;
    emit waveColorChanged();
    update();
}

void WaveformItem::setLineWidth(float width)
{
    if (qFuzzyCompare(m_lineWidth, width))
        return;
    m_lineWidth = width;
    m_dirty     = true;
    emit lineWidthChanged();
    update();
}

// ---------------------------------------------------------------------------
// geometryChange — called on the GUI thread
// ---------------------------------------------------------------------------

void WaveformItem::geometryChange(const QRectF &newGeometry,
                                   const QRectF &oldGeometry)
{
    QQuickItem::geometryChange(newGeometry, oldGeometry);

    if (newGeometry.size() != oldGeometry.size()) {
        m_dirty = true;
        update();
    }
}

// ---------------------------------------------------------------------------
// updatePaintNode — called on the RENDER thread
//
// This is where all scene-graph work happens.  Do NOT access QQuickItem
// properties directly (they live on the GUI thread).  Read everything you
// need from member variables that were set by the GUI-thread setters before
// update() was called.
// ---------------------------------------------------------------------------

QSGNode *WaveformItem::updatePaintNode(QSGNode *oldNode,
                                        UpdatePaintNodeData * /*data*/)
{
    const int n = m_samples.size();

    // Nothing to draw — remove any existing node.
    if (n < 2 || width() <= 0 || height() <= 0) {
        delete oldNode;
        return nullptr;
    }

    // Reuse the existing node if we have one, otherwise create it.
    auto *node = static_cast<QSGGeometryNode *>(oldNode);

    if (!node) {
        node = new QSGGeometryNode;

        // Geometry: n vertices, each is a (x, y) Point2D.
        auto *geometry = new QSGGeometry(
            QSGGeometry::defaultAttributes_Point2D(), n);
        geometry->setDrawingMode(QSGGeometry::DrawLineStrip);
        geometry->setLineWidth(m_lineWidth);

        node->setGeometry(geometry);
        node->setFlag(QSGNode::OwnsGeometry);

        auto *material = new QSGFlatColorMaterial;
        material->setColor(m_waveColor);
        node->setMaterial(material);
        node->setFlag(QSGNode::OwnsMaterial);

    } else if (m_dirty) {
        // Resize geometry if the sample count changed.
        QSGGeometry *geometry = node->geometry();
        if (geometry->vertexCount() != n)
            geometry->allocate(n);

        geometry->setLineWidth(m_lineWidth);

        auto *material = static_cast<QSGFlatColorMaterial *>(node->material());
        material->setColor(m_waveColor);
    }

    if (m_dirty) {
        QSGGeometry *geometry = node->geometry();
        QSGGeometry::Point2D *vertices = geometry->vertexDataAsPoint2D();

        const float w = static_cast<float>(width());
        const float h = static_cast<float>(height());

        for (int i = 0; i < n; ++i) {
            const float x = (static_cast<float>(i) / static_cast<float>(n - 1)) * w;
            // samples are expected in [0, 1]; map to item height (inverted y axis).
            const float y = (1.0f - qBound(0.0f, m_samples[i], 1.0f)) * h;
            vertices[i].set(x, y);
        }

        node->markDirty(QSGNode::DirtyGeometry | QSGNode::DirtyMaterial);
        m_dirty = false;
    }

    return node;
}
