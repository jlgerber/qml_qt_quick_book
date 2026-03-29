// MyStyle/TextField.qml
// Custom TextField for MyStyle.
// The field itself has a transparent background; the only visible chrome is
// a bottom border that animates from 1 px (unfocused) to 2 px (focused) and
// changes color.

import QtQuick
import QtQuick.Templates as T

T.TextField {
    id: control

    // ── sizing ────────────────────────────────────────────────────────────
    implicitWidth:  implicitBackgroundWidth + leftInset + rightInset
                    || Math.ceil(Math.max(contentWidth, placeholder.implicitWidth))
                       + leftPadding + rightPadding
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             contentHeight + topPadding + bottomPadding)

    topPadding:    8
    bottomPadding: 8
    leftPadding:   4
    rightPadding:  4

    // ── visuals ───────────────────────────────────────────────────────────
    color:            control.enabled ? "#1a1a2e" : "#9e9e9e"
    selectionColor:   "#7b2ff7"
    selectedTextColor: "#ffffff"
    placeholderTextColor: "#9e9eb8"
    font.pixelSize:   15

    // Placeholder drawn via a separate Text item so we can animate its opacity
    Text {
        id: placeholder
        x:      control.leftPadding
        y:      control.topPadding
        width:  control.width  - control.leftPadding  - control.rightPadding
        height: control.height - control.topPadding   - control.bottomPadding

        text:             control.placeholderText
        font:             control.font
        color:            control.placeholderTextColor
        verticalAlignment: control.verticalAlignment
        elide:            Text.ElideRight
        renderType:       control.renderType
        visible:          !control.length && !control.preeditText
                          && (!control.activeFocus || control.horizontalAlignment !== Qt.AlignHCenter)
        opacity:          control.activeFocus ? 0.6 : 1.0

        Behavior on opacity {
            NumberAnimation { duration: 180 }
        }
    }

    background: Item {
        implicitWidth:  200
        implicitHeight:  48

        // Full-width tinted fill – subtle, shows the field bounds
        Rectangle {
            anchors {
                fill:          parent
                bottomMargin:  2     // leave room for the border
            }
            color: control.activeFocus ? Qt.rgba(0.49, 0.23, 0.93, 0.06)
                                       : Qt.rgba(0, 0, 0, 0.03)

            Behavior on color {
                ColorAnimation { duration: 180 }
            }
        }

        // Animated bottom border
        Rectangle {
            id: bottomBorder

            anchors {
                left:   parent.left
                right:  parent.right
                bottom: parent.bottom
            }

            height: control.activeFocus ? 2 : 1

            color: {
                if (!control.enabled)       return "#bdbdbd"
                if (control.activeFocus)    return "#6c3aec"
                if (control.hovered)        return "#9e9eb8"
                return "#d0d0e0"
            }

            Behavior on height {
                NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
            }

            Behavior on color {
                ColorAnimation { duration: 180 }
            }
        }
    }
}
