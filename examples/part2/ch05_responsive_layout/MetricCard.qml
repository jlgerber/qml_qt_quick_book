// MetricCard.qml — single metric tile used in the card grid.
// Displays a title, a large value, a trend badge, and a subtitle.

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

Rectangle {
    id: card

    required property string cardTitle
    required property string subtitle
    required property string value
    required property string trend

    readonly property bool positive: trend.startsWith("+")

    radius:        10
    color:         "#ffffff"
    implicitHeight: formGrid.implicitHeight + 24
    implicitWidth:  200

    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled:          true
        shadowColor:            Qt.rgba(0, 0, 0, 0.08)
        shadowVerticalOffset:   2
        shadowHorizontalOffset: 0
        shadowBlur:             0.7
    }

    GridLayout {
        id: formGrid
        anchors {
            left:    parent.left
            right:   parent.right
            top:     parent.top
            margins: 16
        }
        columns:       2
        columnSpacing: 8
        rowSpacing:    4

        // Row 0 — title spanning both columns
        Text {
            text:              card.cardTitle
            font { pixelSize: 13; weight: Font.Medium }
            color:             "#6b7280"
            Layout.columnSpan: 2
        }

        // Row 1 — big value + trend badge
        Text {
            text:             card.value
            font { pixelSize: 26; weight: Font.Bold }
            color:            "#111827"
            Layout.fillWidth: true
        }

        Rectangle {
            radius: 4
            color:  card.positive ? Qt.rgba(0.06, 0.73, 0.44, 0.12)
                                  : Qt.rgba(0.94, 0.27, 0.27, 0.12)
            implicitWidth:  trendLabel.implicitWidth  + 10
            implicitHeight: trendLabel.implicitHeight + 6

            Text {
                id: trendLabel
                anchors.centerIn: parent
                text:  card.trend
                font { pixelSize: 12; weight: Font.Medium }
                color: card.positive ? "#10b981" : "#ef4444"
            }
        }

        // Row 2 — subtitle
        Text {
            text:              card.subtitle
            font.pixelSize:    12
            color:             "#9ca3af"
            Layout.columnSpan: 2
        }
    }
}
