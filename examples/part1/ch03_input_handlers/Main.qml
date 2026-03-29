import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Ch03 — Input Handlers
// Demonstrates Qt Quick pointer-handler types:
//   • DragHandler  — free dragging with live x/y readout
//   • TapHandler   — tap counter + long-press color change
//   • HoverHandler — cursor change + highlight on hover
//   • PinchHandler — two-finger scale + rotation on an image
//   • DraggableBox — reusable component combining DragHandler + TapHandler
ApplicationWindow {
    id: root
    title: "Ch03 – Input Handlers"
    width: 820
    height: 700
    visible: true

    Flickable {
        anchors.fill: parent
        contentWidth: parent.width
        contentHeight: mainColumn.implicitHeight + 40
        clip: true

        ColumnLayout {
            id: mainColumn
            width: parent.width
            anchors.top: parent.top
            anchors.topMargin: 20
            anchors.left: parent.left
            anchors.leftMargin: 20
            anchors.right: parent.right
            anchors.rightMargin: 20
            spacing: 24

            // ── GroupBox sizing note ──────────────────────────────────────────
            // GroupBox.implicitHeight is derived from contentItem.implicitHeight.
            // The default contentItem is a plain Item whose implicitHeight is
            // always 0 — it does not grow to fit its children.  Without an
            // explicit override every GroupBox collapses to its title-bar height
            // and all sections overlap.
            // Fix: set implicitHeight = topPadding + bottomPadding + <canvas height>
            // directly on each GroupBox.  topPadding already includes the title
            // label, so this formula gives the correct total height.

            // ── 1. DragHandler ───────────────────────────────────────────────
            GroupBox {
                Layout.fillWidth: true
                title: "1 · DragHandler — free drag with position readout"
                implicitHeight: topPadding + bottomPadding + 160

                // Fixed-size canvas so the draggable item stays visible.
                Rectangle {
                    width: parent.width - 2
                    height: 160
                    color: "#1a252f"
                    radius: 6
                    clip: true

                    Rectangle {
                        id: dragTarget
                        width: 100
                        height: 60
                        x: 20
                        y: 50
                        color: dragH.active ? "#2980b9" : "#3498db"
                        radius: 8

                        Behavior on color { ColorAnimation { duration: 80 } }

                        DragHandler {
                            id: dragH
                        }

                        Label {
                            anchors.centerIn: parent
                            text: "Drag me"
                            color: "white"
                            font.bold: true
                        }
                    }

                    Label {
                        anchors.bottom: parent.bottom
                        anchors.right: parent.right
                        anchors.margins: 8
                        text: "x: " + dragTarget.x.toFixed(0)
                            + "  y: " + dragTarget.y.toFixed(0)
                            + "  active: " + dragH.active
                        color: "#95a5a6"
                        font.pixelSize: 12
                    }
                }
            }

            // ── 2. TapHandler ────────────────────────────────────────────────
            GroupBox {
                Layout.fillWidth: true
                title: "2 · TapHandler — tap count + long-press"
                implicitHeight: topPadding + bottomPadding + 130

                Rectangle {
                    width: parent.width - 2
                    height: 130
                    color: "#1a252f"
                    radius: 6

                    Rectangle {
                        id: tapTarget
                        anchors.centerIn: parent
                        width: 160
                        height: 70
                        radius: 8
                        color: tapH.pressed ? Qt.darker(baseColor, 1.4) : baseColor

                        property color baseColor: "#8e44ad"

                        Behavior on color { ColorAnimation { duration: 100 } }

                        TapHandler {
                            id: tapH
                            property int tapCount: 0

                            onTapped: {
                                tapH.tapCount++
                            }
                            onLongPressed: {
                                tapTarget.baseColor = Qt.rgba(
                                    Math.random() * 0.6 + 0.2,
                                    Math.random() * 0.6 + 0.2,
                                    Math.random() * 0.6 + 0.2, 1)
                            }
                        }

                        Column {
                            anchors.centerIn: parent
                            spacing: 4
                            Label {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "Tap / Long-press"
                                color: "white"
                                font.bold: true
                            }
                            Label {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "taps: " + tapH.tapCount
                                color: "#dfe6e9"
                                font.pixelSize: 13
                            }
                        }
                    }

                    Label {
                        anchors.bottom: parent.bottom
                        anchors.right: parent.right
                        anchors.margins: 8
                        text: "pressed: " + tapH.pressed
                            + "  taps: " + tapH.tapCount
                        color: "#95a5a6"
                        font.pixelSize: 12
                    }
                }
            }

            // ── 3. HoverHandler ──────────────────────────────────────────────
            GroupBox {
                Layout.fillWidth: true
                title: "3 · HoverHandler — cursor change + hover highlight"
                implicitHeight: topPadding + bottomPadding + 120

                Rectangle {
                    width: parent.width - 2
                    height: 120
                    color: "#1a252f"
                    radius: 6

                    Rectangle {
                        id: hoverTarget
                        anchors.centerIn: parent
                        width: 200
                        height: 70
                        radius: 8
                        color: hoverH.hovered ? "#16a085" : "#1abc9c"
                        border.color: hoverH.hovered ? "white" : "transparent"
                        border.width: 2

                        Behavior on color  { ColorAnimation { duration: 120 } }
                        Behavior on border.color { ColorAnimation { duration: 120 } }

                        HoverHandler {
                            id: hoverH
                            // Change cursor to a pointing hand when hovering.
                            cursorShape: Qt.PointingHandCursor
                        }

                        Label {
                            anchors.centerIn: parent
                            text: hoverH.hovered ? "Hovering!" : "Hover over me"
                            color: "white"
                            font.bold: true
                            font.pixelSize: 14
                        }
                    }

                    Label {
                        anchors.bottom: parent.bottom
                        anchors.right: parent.right
                        anchors.margins: 8
                        text: "hovered: " + hoverH.hovered
                            + "  point: ("
                            + hoverH.point.position.x.toFixed(0) + ", "
                            + hoverH.point.position.y.toFixed(0) + ")"
                        color: "#95a5a6"
                        font.pixelSize: 12
                    }
                }
            }

            // ── 4. PinchHandler ──────────────────────────────────────────────
            GroupBox {
                Layout.fillWidth: true
                title: "4 · PinchHandler — two-finger pinch-to-scale + rotate"
                implicitHeight: topPadding + bottomPadding + 200

                Rectangle {
                    width: parent.width - 2
                    height: 200
                    color: "#1a252f"
                    radius: 6
                    clip: true

                    Rectangle {
                        id: pinchTarget
                        anchors.centerIn: parent
                        width: 160
                        height: 100
                        color: "#d35400"
                        radius: 10

                        transform: [
                            Scale  { origin.x: pinchTarget.width / 2
                                     origin.y: pinchTarget.height / 2
                                     xScale: pinchTarget.currentScale
                                     yScale: pinchTarget.currentScale },
                            Rotation { origin.x: pinchTarget.width / 2
                                       origin.y: pinchTarget.height / 2
                                       angle: pinchTarget.currentAngle }
                        ]

                        property real currentScale: 1.0
                        property real currentAngle: 0.0

                        PinchHandler {
                            id: pinchH
                            minimumScale: 0.3
                            maximumScale: 4.0

                            onScaleChanged: (delta) => {
                                pinchTarget.currentScale =
                                    Math.max(0.3, Math.min(4.0,
                                        pinchTarget.currentScale * delta))
                            }
                            onRotationChanged: (delta) => {
                                pinchTarget.currentAngle += delta
                            }
                        }

                        Column {
                            anchors.centerIn: parent
                            spacing: 4
                            Label {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "Pinch me"
                                color: "white"
                                font.bold: true
                                font.pixelSize: 14
                            }
                            Label {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "scale: " + pinchTarget.currentScale.toFixed(2)
                                    + "  rot: " + pinchTarget.currentAngle.toFixed(1) + "°"
                                color: "#ffeaa7"
                                font.pixelSize: 11
                            }
                        }
                    }

                    Label {
                        anchors.bottom: parent.bottom
                        anchors.right: parent.right
                        anchors.margins: 8
                        text: "active: " + pinchH.active
                            + "  scale: " + pinchTarget.currentScale.toFixed(2)
                            + "  angle: " + pinchTarget.currentAngle.toFixed(1) + "°"
                        color: "#95a5a6"
                        font.pixelSize: 12
                    }
                }
            }

            // ── 5. DraggableBox reusable component ───────────────────────────
            GroupBox {
                Layout.fillWidth: true
                title: "5 · DraggableBox — reusable DragHandler + TapHandler component"
                implicitHeight: topPadding + bottomPadding + 160

                Rectangle {
                    width: parent.width - 2
                    height: 160
                    color: "#1a252f"
                    radius: 6
                    clip: true

                    // Three instances of the reusable component.
                    DraggableBox {
                        x: 20; y: 30
                        boxColor: "#e74c3c"
                        label: "Box A"
                    }
                    DraggableBox {
                        x: 180; y: 50
                        boxColor: "#27ae60"
                        label: "Box B"
                    }
                    DraggableBox {
                        x: 340; y: 40
                        boxColor: "#8e44ad"
                        label: "Box C"
                    }

                    Label {
                        anchors.bottom: parent.bottom
                        anchors.right: parent.right
                        anchors.margins: 8
                        text: "Drag boxes freely · Tap to count · Long-press to randomise colour"
                        color: "#95a5a6"
                        font.pixelSize: 12
                    }
                }
            }

            Item { height: 20 }
        }
    }
}
