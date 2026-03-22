# Chapter 6: Models, Views, and Delegates

## `ListView`, `GridView`, `TableView`, and `TreeView` Internals

Qt Quick's model-view framework is built around a separation between data (the model), the scrollable container (the view), and the visual representation of each item (the delegate). This pattern scales from a 10-item dropdown to a table with millions of rows because views only instantiate delegates for *visible* items — this is the critical architectural property that makes Qt Quick views efficient.

### `ListView`

`ListView` displays items in a linear sequence, either vertical (default) or horizontal. It virtualizes its content: only the delegates for visible items (plus a configurable buffer) exist in memory at any time.

```qml
ListView {
    id: view
    anchors.fill: parent
    model: contactModel
    spacing: 1

    delegate: ContactDelegate {
        width: view.width
    }

    ScrollBar.vertical: ScrollBar { }
}
```

Key properties:

| Property | Description |
|---|---|
| `model` | The data source |
| `delegate` | The template for each item |
| `spacing` | Gap between delegates |
| `orientation` | `ListView.Vertical` (default) or `ListView.Horizontal` |
| `cacheBuffer` | Pixels of off-screen delegates to keep alive |
| `clip` | Clip content to the view bounds (almost always `true`) |
| `currentIndex` | The currently highlighted item |
| `highlight` | An item rendered behind the current delegate |
| `highlightFollowsCurrentItem` | Animate the highlight to follow `currentIndex` |
| `snapMode` | `ListView.NoSnap`, `ListView.SnapToItem`, `ListView.SnapOneItem` |
| `headerItem` / `footerItem` | Static items above/below the list content |

**Sections**: `ListView` supports grouping items into sections with a header per group:

```qml
ListView {
    model: sortedContactModel
    section.property: "lastName"
    section.criteria: ViewSection.FirstCharacter
    section.delegate: SectionHeader {
        text: section
    }
}
```

### `GridView`

`GridView` is a virtualized grid. All cells have the same size (`cellWidth` × `cellHeight`), and items flow left-to-right, top-to-bottom:

```qml
GridView {
    anchors.fill: parent
    model: photoModel
    cellWidth: 120
    cellHeight: 120

    delegate: PhotoThumbnail {
        width: GridView.view.cellWidth - 4
        height: GridView.view.cellHeight - 4
    }
}
```

For variable-size grids (masonry/waterfall layouts), `GridView` is not sufficient — implement a custom positioner or use a `Flow`-based approach with a custom model that pre-computes sizes.

### `TableView`

`TableView` handles two-dimensional tabular data. It virtualizes both rows and columns, making it suitable for large datasets:

```qml
TableView {
    id: tableView
    anchors.fill: parent
    model: tableModel   // must implement QAbstractTableModel or be a 2D ListModel

    columnWidthProvider: (column) => column === 0 ? 200 : 100
    rowHeightProvider: () => 40

    delegate: Rectangle {
        color: row % 2 === 0 ? "#f0f0f0" : "white"

        Text {
            anchors.centerIn: parent
            text: display   // standard Qt role name
        }
    }
}
```

`TableView` in Qt 6 supports:
- `selectionModel` with `ItemSelectionModel` for multi-selection
- `syncView` for synchronized scrolling between a header view and the data view
- `HorizontalHeaderView` and `VerticalHeaderView` as companion components

```qml
HorizontalHeaderView {
    syncView: tableView
    Layout.fillWidth: true
}
```

### `TreeView`

`TreeView` (introduced in Qt 6.3) displays hierarchical data:

```qml
TreeView {
    anchors.fill: parent
    model: fileSystemModel

    delegate: TreeViewDelegate {
        // Built-in delegate handles expand/collapse indicators
        contentItem: Label {
            text: model.display
            leftPadding: depth * 20   // indent by depth
        }
    }
}
```

`TreeView` exposes `depth`, `isTreeNode`, `expanded`, and `hasChildren` from the `TreeView` attached type in delegates.

### Internal Architecture: Virtualization and Reuse

All Qt Quick views use a *delegate recycling pool*. When a delegate scrolls out of the visible area, it is not destroyed — instead it is placed in a reuse pool. When a new item scrolls into view, a delegate is taken from the pool and populated with the new item's data. This dramatically reduces the cost of scrolling in large lists.

The reuse pool behavior is controlled by:

```qml
ListView {
    reuseItems: true   // default in Qt 6 (opt-in in Qt 5)
}
```

When `reuseItems` is true, delegates must handle being "reset" with new data. Any state in the delegate that is not driven by the model must be cleared in the `TableView.onReused` (or `ListView.onReused`) handler:

```qml
delegate: ItemDelegate {
    property bool selected: false   // local state, not from model

    TableView.onReused: selected = false   // reset on reuse
}
```

---

## Delegate Lifecycle, Pooling, and Performance Pitfalls

### Delegate Lifecycle

A delegate goes through these states:

1. **Created**: Instantiated from the delegate component, possibly from the reuse pool
2. **Active**: Visible on screen, receiving binding updates and events
3. **In pool**: Off-screen, binding updates suspended, `TableView.onPooled` signal emitted
4. **Reused**: Taken from pool for a new item, `TableView.onReused` signal emitted
5. **Destroyed**: Pool evicted due to memory pressure or view teardown

### Performance Pitfalls

**1. Heavy delegate instantiation**

Every item entering the view triggers delegate creation (or reuse). An expensive `Component.onCompleted` — loading images, making network requests, building complex sub-hierarchies — causes jank during fast scrolling.

Mitigation: Keep delegates lightweight. Defer heavy work with `Loader` and `asynchronous: true`:

```qml
delegate: Item {
    Loader {
        asynchronous: true
        active: visible
        source: "HeavyContent.qml"
    }
}
```

**2. Binding storms in delegates**

Each delegate's bindings re-evaluate when the model notifies a data change. If a model emits `dataChanged` for the entire range on every update, all visible delegates re-evaluate all their bindings simultaneously.

Mitigation: Emit granular `dataChanged` signals with tight index ranges and specific role lists.

**3. Anchors in delegates**

Anchors in frequently-instantiated delegates add binding overhead that compounds with the number of visible items. Explicit width/height and `x`/`y` are faster.

**4. Deep component hierarchies in delegates**

Each level of nesting adds to instantiation cost. Flatten delegate trees where possible.

**5. `clip: true` on delegates**

Clipping requires a stencil operation per frame. Clip at the view level, not on individual delegates.

**6. Image loading in delegates**

Images load asynchronously but still block the main thread briefly during texture upload. Use `Image.asynchronous: true` and a placeholder:

```qml
Image {
    source: model.avatarUrl
    asynchronous: true
    fillMode: Image.PreserveAspectCrop

    Rectangle {
        anchors.fill: parent
        visible: parent.status !== Image.Ready
        color: "#e0e0e0"
    }
}
```

---

## `DelegateChooser`, Section Headers, and Complex Delegate Composition

### `DelegateChooser`

`DelegateChooser` (from `Qt.labs.qmlmodels`) selects between multiple delegate types based on a model role:

```qml
import Qt.labs.qmlmodels

ListView {
    model: messageModel

    delegate: DelegateChooser {
        role: "messageType"

        DelegateChoice {
            roleValue: "text"
            delegate: TextMessageDelegate { }
        }

        DelegateChoice {
            roleValue: "image"
            delegate: ImageMessageDelegate { }
        }

        DelegateChoice {
            roleValue: "system"
            delegate: SystemMessageDelegate { }
        }
    }
}
```

Each `DelegateChoice` provides a separate component. The chooser evaluates the `role` on each model item and instantiates the matching delegate. This is cleaner than a single delegate with `Loader` switching on role values.

### Section Headers

Section headers divide a list into labeled groups. The `section.delegate` is instantiated once per group transition and sits between the last item of one group and the first item of the next:

```qml
ListView {
    model: sortedEmailModel
    section.property: "date"
    section.delegate: Item {
        width: parent.width
        height: 32

        Rectangle {
            anchors.fill: parent
            color: "#e8e8e8"
        }

        Text {
            anchors.centerIn: parent
            text: section
            font.bold: true
        }
    }
}
```

Section headers are part of the list's content flow and scroll with the list. For a *sticky* (pinned) header that stays visible as the corresponding section scrolls, you need to implement it manually:

```qml
ListView {
    id: listView

    // Sticky section header overlay
    Item {
        anchors.top: parent.top
        width: parent.width
        height: sectionHeaderHeight
        z: 2

        Text {
            anchors.fill: parent
            text: listView.currentSection
        }
    }
}
```

`currentSection` updates as the user scrolls past section boundaries.

### Complex Delegate Composition

For chat applications, feed readers, or other complex list UIs, delegates often need:
- Variable height based on content
- Lazy-loaded sub-content
- Multiple interactive regions
- Animated state transitions

A well-structured complex delegate:

```qml
// MessageDelegate.qml
Item {
    id: root
    required property string authorName
    required property string bodyText
    required property string avatarUrl
    required property date timestamp
    required property bool isOwn

    width: ListView.view.width
    height: layout.implicitHeight + 24

    RowLayout {
        id: layout
        anchors {
            left: parent.left; right: parent.right
            top: parent.top
            margins: 12
        }
        spacing: 8
        layoutDirection: root.isOwn ? Qt.RightToLeft : Qt.LeftToRight

        // Avatar
        RoundedImage {
            Layout.preferredWidth: 36
            Layout.preferredHeight: 36
            Layout.alignment: Qt.AlignTop
            source: root.avatarUrl
        }

        // Bubble
        MessageBubble {
            Layout.maximumWidth: root.width * 0.7
            Layout.fillWidth: true
            text: root.bodyText
            isOwn: root.isOwn
        }
    }
}
```

Using `required property` declarations (introduced in Qt 5.15) enforces that the view supplies model data, catching misconfigurations at runtime. In Qt 6, `qmlsc` can catch them at compile time.

---

## Summary

Qt Quick's view components achieve scalability through delegate virtualization and recycling. The choice of view type — `ListView`, `GridView`, `TableView`, `TreeView` — depends on the dimensionality and structure of the data. Delegate performance is dominated by instantiation cost and binding depth; keeping delegates lean is the most impactful optimization. `DelegateChooser` cleanly handles heterogeneous lists, and section headers with `currentSection` implement grouped navigation. For complex delegates, the `required property` pattern makes model-delegate contracts explicit and type-safe.
