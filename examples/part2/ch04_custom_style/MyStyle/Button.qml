// MyStyle/Button.qml
// Custom Button control for MyStyle.
// Inherits from QtQuick.Templates so it participates in the Controls
// theming system without pulling in any default style visuals.

import QtQuick
import QtQuick.Templates as T
import QtQuick.Controls.impl   // IconLabel
import QtQuick.Effects          // MultiEffect

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
    background: Item {
        implicitWidth:  100
        implicitHeight:  40

        // ── Visual button body (z:0, default) ─────────────────────────────
        // Sits on top of the MultiEffect below, hiding its duplicate body
        // rendering.  Only the shadow portion that extends outside bg's
        // bounds remains visible.
        Rectangle {
            id: bg
            anchors.fill: parent
            radius: 8

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

            // Subtle gradient overlay
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
        }

        // ── Drop shadow (z:-1, behind bg) ─────────────────────────────────
        // MultiEffect renders bg again (body + shadow).  z:-1 places it
        // behind bg so the duplicate body is hidden; only the shadow that
        // spills outside bg's bounds is visible.  The parent Item has no
        // clip:true so the shadow can bleed freely into surrounding space.
        MultiEffect {
            source:       bg
            anchors.fill: bg
            z:            -1

            shadowEnabled:          control.enabled && !control.flat
            shadowColor:            Qt.rgba(0.42, 0.23, 0.93, 0.65)
            shadowVerticalOffset:   4
            shadowHorizontalOffset: 2
            shadowBlur:             0.6
        }
    }
}
