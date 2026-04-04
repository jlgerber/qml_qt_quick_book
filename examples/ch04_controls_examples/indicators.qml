// indicators.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    visible: true
    width: 320
    height: 280
    title: "Indicators Example"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 20

        Text {
            text: "Progress Bar"
            font.bold: true
        }

        ProgressBar {
            Layout.fillWidth: true
            from: 0
            to: 100
            value: progressTimer.elapsed % 101
        }

        Text {
            text: "Busy Indicator"
            font.bold: true
        }

        BusyIndicator {
            running: true
            width: 50
            height: 50
        }

        Text {
            text: "Page Indicator"
            font.bold: true
        }

        PageIndicator {
            count: 5
            currentIndex: Math.floor(progressTimer.elapsed / 500) % 5
        }
    }

    Timer {
        id: progressTimer
        running: true
        repeat: true
        interval: 50
        property int elapsed: 0
        onTriggered: elapsed += interval
    }
}