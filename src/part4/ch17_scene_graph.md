# Chapter 17: Extending the Scene Graph

## Custom `QQuickItem` Subclasses and the Render Thread

When Qt Quick's built-in visual types are insufficient — custom chart rendering, waveform displays, game sprites, data visualizations — the solution is a custom `QQuickItem` subclass that participates directly in the scene graph.

### The `QQuickItem` / Scene Graph Contract

The critical constraint: the UI thread and the render thread run concurrently after the *sync phase*. During sync, the main thread is blocked and scene graph data can be safely copied from `QQuickItem` properties into scene graph nodes. After sync, the render thread runs while the main thread processes events — at this point, touching scene graph nodes from the main thread is a data race.

Qt enforces this contract through `updatePaintNode()`:

```cpp
class WaveformItem : public QQuickItem
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QList<float> samples READ samples
               WRITE setSamples NOTIFY samplesChanged)

public:
    explicit WaveformItem(QQuickItem *parent = nullptr);

    QList<float> samples() const { return m_samples; }
    void setSamples(const QList<float> &s);

signals:
    void samplesChanged();

protected:
    // Called on the RENDER THREAD during the sync phase
    QSGNode *updatePaintNode(QSGNode *oldNode,
                              UpdatePaintNodeData *data) override;

    // Called on the MAIN THREAD — geometric changes
    void geometryChange(const QRectF &newGeometry,
                        const QRectF &oldGeometry) override;

private:
    QList<float> m_samples;   // main thread state
    bool m_dirty = false;
};
```

```cpp
void WaveformItem::setSamples(const QList<float> &s)
{
    if (m_samples == s)
        return;
    m_samples = s;
    m_dirty = true;
    emit samplesChanged();
    update();   // Schedule a redraw — triggers updatePaintNode call
}

void WaveformItem::geometryChange(const QRectF &newGeometry,
                                   const QRectF &oldGeometry)
{
    QQuickItem::geometryChange(newGeometry, oldGeometry);
    m_dirty = true;
    update();
}
```

### Enabling the Item

A `QQuickItem` that draws must have its `ItemHasContents` flag set:

```cpp
WaveformItem::WaveformItem(QQuickItem *parent)
    : QQuickItem(parent)
{
    setFlag(QQuickItem::ItemHasContents);
}
```

Without this flag, `updatePaintNode` is never called.

---

## `QSGNode` Trees: Geometry Nodes, Transform Nodes, and Clip Nodes

### `QSGGeometryNode`

The leaf node of the scene graph — it holds geometry (vertices) and a material (shader + uniforms).

```cpp
QSGNode *WaveformItem::updatePaintNode(QSGNode *oldNode,
                                        UpdatePaintNodeData *)
{
    auto *node = static_cast<QSGGeometryNode *>(oldNode);

    if (!node) {
        node = new QSGGeometryNode;

        // Geometry: line strip with (x, y) per vertex
        auto *geometry = new QSGGeometry(
            QSGGeometry::defaultAttributes_Point2D(),
            0   // vertex count, will resize below
        );
        geometry->setDrawingMode(QSGGeometry::DrawLineStrip);
        geometry->setLineWidth(2.0f);
        node->setGeometry(geometry);
        node->setFlag(QSGNode::OwnsGeometry);

        // Flat color material
        auto *material = new QSGFlatColorMaterial;
        material->setColor(QColor("#3daee9"));
        node->setMaterial(material);
        node->setFlag(QSGNode::OwnsMaterial);
    }

    if (!m_dirty)
        return node;

    m_dirty = false;

    // Rebuild geometry from samples
    auto *geometry = node->geometry();
    geometry->allocate(m_samples.size());

    auto *vertices = geometry->vertexDataAsPoint2D();
    const float w = width();
    const float h = height();
    const float midY = h / 2.0f;

    for (int i = 0; i < m_samples.size(); ++i) {
        float x = (w * i) / (m_samples.size() - 1);
        float y = midY - m_samples[i] * midY;
        vertices[i].set(x, y);
    }

    node->markDirty(QSGNode::DirtyGeometry);
    return node;
}
```

Key points:
- `oldNode` is the node from the previous frame. Reuse it to avoid allocation.
- `OwnsGeometry` / `OwnsMaterial` flags: the node deletes them when it is deleted.
- `markDirty(DirtyGeometry)` tells the renderer to re-upload the geometry to the GPU.
- All of this runs on the render thread — no QObject access, no signal emission.

### `QSGTransformNode`

Applies a matrix transform to its subtree. Useful for building hierarchical scene graphs:

```cpp
auto *root = new QSGTransformNode;

QMatrix4x4 m;
m.translate(offsetX, offsetY);
m.scale(scale);
root->setMatrix(m);

// Children positioned relative to the transform
root->appendChildNode(geometryNode1);
root->appendChildNode(geometryNode2);

return root;
```

### `QSGClipNode`

Clips its subtree to a rectangular or geometric region:

```cpp
auto *clipNode = new QSGClipNode;
clipNode->setIsRectangular(true);
clipNode->setClipRect(QRectF(0, 0, width(), height()));
clipNode->appendChildNode(contentNode);
```

Clipping is implemented with stencil buffer operations, so it has a GPU cost. Prefer Qt Quick's `clip: true` on items for rectangular clipping — the scene graph handles it the same way.

### `QSGOpacityNode`

Sets opacity for its subtree independently of individual item opacity:

```cpp
auto *opacityNode = new QSGOpacityNode;
opacityNode->setOpacity(0.5f);
opacityNode->appendChildNode(contentNode);
```

### Node Ownership and the Node Tree

The scene graph owns the root node returned by `updatePaintNode`. When an item's `updatePaintNode` is called again, `oldNode` is the previously returned node. You may modify and return it, or delete it and return a new one. You must never delete the old node yourself outside `updatePaintNode` — the scene graph manages its lifetime.

---

## Custom `QQuickPaintedItem` and When to Use It vs. Raw Scene Graph Nodes

`QQuickPaintedItem` is a simpler alternative to custom scene graph nodes. It provides a QPainter-based API, rendering the item to an offscreen surface that is then uploaded to a GPU texture:

```cpp
class PieChartItem : public QQuickPaintedItem
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QVariantList slices READ slices WRITE setSlices NOTIFY slicesChanged)

public:
    void paint(QPainter *painter) override {
        painter->setRenderHint(QPainter::Antialiasing);
        const QRectF rect = boundingRect().adjusted(4, 4, -4, -4);
        double startAngle = 0;

        for (const QVariant &v : m_slices) {
            const QVariantMap slice = v.toMap();
            const double sweep = slice["value"].toDouble() * 360.0;
            painter->setBrush(QColor(slice["color"].toString()));
            painter->setPen(Qt::NoPen);
            painter->drawPie(rect,
                             static_cast<int>(startAngle * 16),
                             static_cast<int>(sweep * 16));
            startAngle += sweep;
        }
    }

    // ... properties
};
```

### When to Use `QQuickPaintedItem`

**Use `QQuickPaintedItem`** when:
- Rendering logic is complex and already uses QPainter (porting from QWidget)
- The item updates infrequently (the texture-upload cost amortizes)
- Vector drawing primitives (arcs, beziers, text) are needed
- Development speed matters more than peak throughput

**Use raw scene graph nodes** when:
- The item updates every frame (charts, waveforms, games)
- Maximum throughput is required (geometry is built directly in GPU-ready format)
- Custom shaders are needed
- You need multi-pass rendering

The texture-upload path of `QQuickPaintedItem` involves CPU rendering + GPU upload each time `update()` is called. For a waveform that redraws at 60 Hz with 10,000 points, this is prohibitively expensive. Raw geometry nodes skip the CPU rasterization entirely.

---

## Integrating External Renderers via `QQuickRenderTarget`

Qt 6.0 introduced `QQuickRenderTarget` — a mechanism for directing Qt Quick's rendering to an externally created framebuffer object, texture, or render buffer. This enables:

- Rendering Qt Quick UI into a Vulkan/Metal/D3D texture for compositing with a 3D engine
- Displaying Qt Quick UI inside a game engine scene
- Multi-stage rendering pipelines

### Rendering Qt Quick into an External Texture

```cpp
// Create a texture on the external renderer's device
VkImage externalImage = /* ... created by your Vulkan code ... */;

// Direct Qt Quick to render into it
QQuickRenderTarget target = QQuickRenderTarget::fromVulkanImage(
    externalImage,
    VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
    QSize(1920, 1080)
);
quickWindow->setRenderTarget(target);
```

### Embedding External Rendering in a Qt Quick Scene

The `QQuickGraphicsDevice` and `QRhi` (Qt Rendering Hardware Interface) APIs allow Qt Quick and external renderers to share a GPU device:

```cpp
// Tell Qt Quick to use the same Vulkan device as your engine
QQuickGraphicsDevice device = QQuickGraphicsDevice::fromDeviceObjects(
    physicalDevice, logicalDevice, graphicsQueueFamilyIndex, graphicsQueueIndex
);
quickWindow->setGraphicsDevice(device);
```

With a shared device, resources (textures, buffers) can be passed between Qt Quick and the external renderer without cross-device copies.

### `QRhiWidget` (Qt 6.7+)

`QRhiWidget` is a newer, higher-level API that simplifies embedding custom RHI rendering into a Qt Quick scene. It replaces the older `QQuickFramebufferObject` pattern:

```cpp
class CustomRhiWidget : public QRhiWidget
{
    Q_OBJECT
    QML_ELEMENT

public:
    void initialize(QRhiCommandBuffer *cb) override {
        // Create pipelines, buffers, etc.
        m_pipeline = m_rhi->newGraphicsPipeline();
        // ... configure pipeline ...
        m_pipeline->create();
    }

    void render(QRhiCommandBuffer *cb) override {
        // Issue draw calls — runs on the render thread
        QRhiCommandBuffer::BeginRenderPassFlags flags;
        cb->beginRenderPass(m_renderTarget, flags);
        cb->setGraphicsPipeline(m_pipeline);
        cb->draw(3);
        cb->endRenderPass();
    }

private:
    QRhiGraphicsPipeline *m_pipeline = nullptr;
};
```

`QRhiWidget` appears as a regular item in QML; Qt Quick composites its output into the scene.

---

## Summary

The scene graph extension API gives C++ code direct GPU rendering access, integrated seamlessly into Qt Quick's retained scene graph. `QSGGeometryNode` with a `QSGMaterial` is the building block for custom rendered content; `QSGTransformNode`, `QSGClipNode`, and `QSGOpacityNode` compose them into hierarchies. The threading contract — UI properties on the main thread, scene graph manipulation in `updatePaintNode` on the render thread — is non-negotiable and must be respected. `QQuickPaintedItem` offers an easier QPainter-based path for infrequently-updated items. `QQuickRenderTarget` and `QRhiWidget` address integration with external GPU rendering pipelines, making Qt Quick a viable overlay or component in 3D-engine-driven applications.
