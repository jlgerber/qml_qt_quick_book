// MyStyle/Button.qml
// Custom Button control for MyStyle.
// Inherits from QtQuick.Templates so it participates in the Controls
// theming system without pulling in any default style visuals.

import QtQuick
import QtQuick.Templates as T
import QtQuick.Controls.impl   // IconLabel

T.Button {
    id: control

    // ── sizing ────────────────────────────────────────────────────────────
    implicitWidth:  Math.max(implicitBackgroundWidth  + leftInset + rightInset,
                             implicitContentWidth     + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight    + topPadding + bottomPadding)

    padding:      12
    leftPadding:  20
    rightPadding: 20
    spacing:       6

    // ── content ───────────────────────────────────────────────────────────
    contentItem: IconLabel {
        spacing:    control.spacing
        mirrored:   control.mirrored
        display:    control.display

        icon:  control.icon
        text:  control.text
        font:  control.font
        color: control.enabled ? (control.down ? "#ffffff" : "#1a1a2e")
                               : "#9e9e9e"

        Behavior on color {
            ColorAnimation { duration: 120 }
        }
    }

    // ── background ────────────────────────────────────────────────────────
    background: Rectangle {
        id: bg

        implicitWidth:  100
        implicitHeight:  40
        radius:          8

        // Resolve the target base color from control state
        readonly property color baseColor: {
            if (!control.enabled)    return "#e0e0e0"
            if (control.down)        return "#3a0ca3"
            if (control.hovered)     return "#7b2ff7"
            return "#6c3aec"
        }

        color: baseColor

        Behavior on color {
            ColorAnimation { duration: 150 }
        }

        // Subtle gradient overlay painted on top of the flat color
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, control.down ? 0.0 : 0.12) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        // Focus ring
        Rectangle {
            anchors {
                fill:    parent
                margins: -3
            }
            radius:  bg.radius + 3
            color:   "transparent"
            border {
                width: 2
                color: "#7b2ff7"
            }
            visible: control.visualFocus
        }

        // Elevation shadow (simple drop-shadow via layer effect)
        layer.enabled: control.enabled && !control.flat
        layer.effect: MultiEffect {
            shadowEnabled:    true
            shadowColor:      Qt.rgba(0.42, 0.23, 0.93, 0.35)
            shadowVerticalOffset:   2
            shadowHorizontalOffset: 0
            shadowBlur:       0.6
        }
    }
}
