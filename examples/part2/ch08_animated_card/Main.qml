// Main.qml — ch08_animated_card
// Demonstrates expandable cards using:
//   • Qt Quick States (collapsed / expanded)
//   • Transitions with NumberAnimation (height, opacity) and
//     RotationAnimation (chevron icon)
//   • Behavior on color for background tint
//
// Run with:
//   qml Main.qml

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id:      root
    title:   "Chapter 8 – Animated Cards"
    width:   480
    height:  560
    visible: true

    background: Rectangle { color: "#f0f2f5" }

    // ── Reusable expandable card component ────────────────────────────────
    component ExpandableCard: Rectangle {
        id: card

        // Public API
        required property string cardTitle
        required property string summary
        required property string body
        required property string accentColor

        // Internal state
        property bool expanded: false

        // ── Sizing ────────────────────────────────────────────────────────
        // collapsed: 72 px   expanded: 220 px
        width:  parent ? parent.width : 440
        height: 72              // overridden by States below
        radius: 12
        clip:   true            // hide body text while animating height

        color: card.expanded
               ? Qt.rgba(Qt.color(card.accentColor).r,
                         Qt.color(card.accentColor).g,
                         Qt.color(card.accentColor).b, 0.08)
               : "#ffffff"

        Behavior on color {
            ColorAnimation { duration: 250 }
        }

        // Elevation shadow — Qt version compatibility note:
        //
        // No shadow is applied here because the card uses clip:true (needed to
        // hide the body text while the height animates), which would clip any
        // child shadow Rectangle.
        //
        // To add a true blurred shadow on Qt ≥ 6.5, wrap the card in a parent
        // Rectangle (no clip) that carries the shadow, and keep clip:true only
        // on the inner card.  On the wrapper, add:
        //
        //   layer.enabled: true
        //   layer.effect: MultiEffect {
        //       shadowEnabled:        true
        //       shadowColor:          Qt.rgba(0, 0, 0, 0.09)
        //       shadowVerticalOffset: 3
        //       shadowBlur:           0.7
        //   }
        //
        // On Qt 6.3–6.4, use the same wrapper approach with:
        //   import Qt5Compat.GraphicalEffects
        //   layer.enabled: true
        //   layer.effect: DropShadow { color: Qt.rgba(0,0,0,0.09); verticalOffset: 3; radius: 10; samples: 21 }

        // ── States ────────────────────────────────────────────────────────
        states: [
            State {
                name: "collapsed"
                when: !card.expanded
                PropertyChanges { target: card;       height:  72  }
                PropertyChanges { target: bodyColumn; opacity: 0   }
                PropertyChanges { target: chevron;    rotation: 0  }
            },
            State {
                name: "expanded"
                when: card.expanded
                PropertyChanges { target: card;       height:  220 }
                PropertyChanges { target: bodyColumn; opacity: 1   }
                PropertyChanges { target: chevron;    rotation: 180 }
            }
        ]

        // ── Transitions ───────────────────────────────────────────────────
        transitions: [
            Transition {
                from: "collapsed"; to: "expanded"

                NumberAnimation {
                    target:   card
                    property: "height"
                    duration: 320
                    easing.type: Easing.OutCubic
                }

                NumberAnimation {
                    target:   bodyColumn
                    property: "opacity"
                    duration: 200
                    // Delay opacity fade-in until card is mostly open
                    easing.type: Easing.InQuad
                }

                RotationAnimation {
                    target:    chevron
                    duration:  320
                    direction: RotationAnimation.Clockwise
                    easing.type: Easing.OutCubic
                }
            },

            Transition {
                from: "expanded"; to: "collapsed"

                NumberAnimation {
                    target:   bodyColumn
                    property: "opacity"
                    duration: 120
                    easing.type: Easing.OutQuad
                }

                NumberAnimation {
                    target:   card
                    property: "height"
                    duration: 280
                    easing.type: Easing.OutCubic
                }

                RotationAnimation {
                    target:    chevron
                    duration:  280
                    direction: RotationAnimation.Counterclockwise
                    easing.type: Easing.OutCubic
                }
            }
        ]

        // ── Card content ──────────────────────────────────────────────────
        ColumnLayout {
            anchors {
                left:    parent.left
                right:   parent.right
                top:     parent.top
                margins: 18
            }
            spacing: 0

            // ── Header row (always visible) ───────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                height:           36
                spacing:          10

                // Accent dot
                Rectangle {
                    width:  10
                    height: 10
                    radius: 5
                    color:  card.accentColor
                    Layout.alignment: Qt.AlignVCenter
                }

                // Title
                Text {
                    text:             card.cardTitle
                    font { pixelSize: 16; weight: Font.SemiBold }
                    color:            "#1a1a2e"
                    Layout.fillWidth: true
                    elide:            Text.ElideRight
                }

                // Summary (hidden when expanded)
                Text {
                    text:       card.summary
                    font.pixelSize: 13
                    color:      "#9ca3af"
                    visible:    !card.expanded
                    opacity:    card.expanded ? 0 : 1
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }

                // Chevron
                Text {
                    id:     chevron
                    text:   "⌄"
                    font { pixelSize: 20; weight: Font.Light }
                    color:  card.accentColor

                    transformOrigin: Item.Center

                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }

            // Thin divider (fades in with expansion)
            Rectangle {
                Layout.fillWidth: true
                height:           1
                color:            card.accentColor
                opacity:          card.expanded ? 0.25 : 0
                Layout.topMargin: 4
                Layout.bottomMargin: 12

                Behavior on opacity { NumberAnimation { duration: 200 } }
            }

            // ── Body (visible only when expanded) ─────────────────────────
            Column {
                id:               bodyColumn
                Layout.fillWidth: true
                spacing:          10
                opacity:          0   // controlled by State/Transition

                Text {
                    text:        card.summary
                    font { pixelSize: 13; weight: Font.Medium }
                    color:       card.accentColor
                    width:       parent.width
                }

                Text {
                    text:       card.body
                    font.pixelSize: 13
                    color:      "#374151"
                    wrapMode:   Text.WordWrap
                    lineHeight: 1.5
                    width:      parent.width
                }
            }
        }

        // ── Tap target ────────────────────────────────────────────────────
        MouseArea {
            anchors.fill: parent
            cursorShape:  Qt.PointingHandCursor
            onClicked:    card.expanded = !card.expanded
        }
    }

    // ── Page layout ───────────────────────────────────────────────────────
    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth

        ColumnLayout {
            width:   parent.width
            spacing: 14

            Item { height: 6 }

            // Page title
            Text {
                Layout.leftMargin: 20
                text: "Expandable Cards"
                font { pixelSize: 22; weight: Font.Bold }
                color: "#1a1a2e"
            }

            Text {
                Layout.leftMargin: 20
                text: "Tap any card to expand or collapse it."
                font.pixelSize: 14
                color:          "#6b7280"
                Layout.bottomMargin: 4
            }

            // ── Card 1: Design System ─────────────────────────────────────
            ExpandableCard {
                Layout.fillWidth:   true
                Layout.leftMargin:  16
                Layout.rightMargin: 16

                cardTitle:   "Design System"
                summary:     "Tokens, components & guidelines"
                accentColor: "#6c3aec"
                body: "A design system is a collection of reusable components, guided by "
                    + "clear standards, that can be assembled to build any number of "
                    + "applications. It bridges the gap between design and development by "
                    + "providing a shared language and a single source of truth."
            }

            // ── Card 2: Qt Quick Controls ─────────────────────────────────
            ExpandableCard {
                Layout.fillWidth:   true
                Layout.leftMargin:  16
                Layout.rightMargin: 16

                cardTitle:   "Qt Quick Controls"
                summary:     "Ready-made UI controls for QML"
                accentColor: "#0ea5e9"
                body: "Qt Quick Controls provides a set of controls that can be used to "
                    + "build complete interfaces in Qt Quick.  Controls use the delegate "
                    + "pattern to separate behaviour (templates) from appearance (styles), "
                    + "making it straightforward to ship a branded look and feel."
            }

            // ── Card 3: Animation System ──────────────────────────────────
            ExpandableCard {
                Layout.fillWidth:   true
                Layout.leftMargin:  16
                Layout.rightMargin: 16

                cardTitle:   "QML Animations"
                summary:     "States, Transitions & Behaviors"
                accentColor: "#10b981"
                body: "QML provides three complementary animation APIs: PropertyAnimation "
                    + "subclasses for tweening individual values, Behavior for automatically "
                    + "animating every change to a property, and State / Transition for "
                    + "orchestrating multi-property changes as discrete UI state changes."
            }

            Item { height: 16 }
        }
    }
}
