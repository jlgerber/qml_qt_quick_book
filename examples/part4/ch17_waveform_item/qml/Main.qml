import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import com.example.scenegraph

// Main.qml — ch17 Custom QQuickItem / Scene Graph demo.
//
// Demonstrates:
//   * Using a custom QQuickItem (WaveformItem) from QML
//   * Animating it by updating the 'samples' property from a Timer
//   * Controlling waveColor and lineWidth via QML controls
Window {
    id: root
    width: 640
    height: 400
    visible: true
    title: qsTr("Waveform Item — ch17")

    // Phase accumulator for the animated sine wave.
    property real phase: 0.0

    // Number of points in the waveform.
    property int  pointCount: 256

    // Build a sine-wave sample list at the current phase offset.
    function makeSamples(ph) {
        var arr = []
        for (var i = 0; i < pointCount; ++i) {
            var t   = i / (pointCount - 1)          // 0..1
            var rad = t * Math.PI * 6 + ph           // 3 full cycles + phase
            arr.push(0.5 + 0.45 * Math.sin(rad))    // centred, 90 % amplitude
        }
        return arr
    }

    // Timer drives the animation at ~20 fps (50 ms interval).
    Timer {
        id: animTimer
        interval: 50
        repeat: true
        running: true
        onTriggered: {
            root.phase += 0.15   // advance phase each tick
            waveform.samples = root.makeSamples(root.phase)
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // ---- Waveform display --------------------------------------------
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 200
            color: "#1a1a2e"
            radius: 8

            WaveformItem {
                id: waveform
                anchors.fill: parent
                anchors.margins: 8

                // Seed initial samples so the item is non-empty before the
                // first Timer tick.
                samples:   root.makeSamples(0)
                waveColor: colorPicker.currentColor
                lineWidth: lineWidthSlider.value
            }
        }

        // ---- Controls ---------------------------------------------------
        GridLayout {
            columns: 2
            rowSpacing: 8
            columnSpacing: 16

            // Wave colour
            Label { text: qsTr("Wave colour:") }
            RowLayout {
                spacing: 8
                Repeater {
                    model: ["#00bcd4", "#e91e63", "#8bc34a", "#ff9800", "white"]
                    Rectangle {
                        width: 28; height: 28
                        radius: 14
                        color: modelData
                        border.color: colorPicker.currentColor === modelData ? "#fff" : "transparent"
                        border.width: 2

                        TapHandler { onTapped: colorPicker.currentColor = modelData }
                    }
                }
                // Invisible helper to track the selected colour.
                QtObject {
                    id: colorPicker
                    property color currentColor: "#00bcd4"
                }
            }

            // Line width
            Label { text: qsTr("Line width: %1 px").arg(lineWidthSlider.value.toFixed(1)) }
            Slider {
                id: lineWidthSlider
                from: 0.5; to: 8.0; value: 2.0
                stepSize: 0.5
                Layout.fillWidth: true
            }

            // Point count
            Label { text: qsTr("Points: %1").arg(pointCountSlider.value) }
            Slider {
                id: pointCountSlider
                from: 32; to: 512; value: 256
                stepSize: 32
                Layout.fillWidth: true
                onValueChanged: {
                    root.pointCount = value
                    waveform.samples = root.makeSamples(root.phase)
                }
            }

            // Play / pause
            Label { text: qsTr("Animation:") }
            Button {
                text: animTimer.running ? qsTr("Pause") : qsTr("Play")
                onClicked: animTimer.running = !animTimer.running
            }
        }
    }
}
