import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import com.example.types

// Main.qml — ch15 C++ Types demo.
//
// Demonstrates:
//   * Instantiating a QML_ELEMENT C++ type (TemperatureConverter)
//   * Two-way binding between Sliders and bindable properties
//   * Q_INVOKABLE call (formatCelsius)
//   * Q_ENUM_NS usage via ComboBox model
//   * Q_GADGET / QML_VALUE_TYPE (TemperatureReading)
Window {
    id: root
    width: 480
    height: 440
    visible: true
    title: qsTr("C++ Types — ch15")

    TemperatureConverter {
        id: conv
    }

    // Keep slider thumb positions consistent with the model even when the
    // *other* slider was moved (two-way binding pattern).
    Binding {
        target: celsiusSlider
        property: "value"
        value: conv.celsius
        when: !celsiusSlider.pressed
    }
    Binding {
        target: fahrenheitSlider
        property: "value"
        value: conv.fahrenheit
        when: !fahrenheitSlider.pressed
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 16

        // ---- Celsius slider -----------------------------------------------
        Label { text: qsTr("Celsius") }
        RowLayout {
            Slider {
                id: celsiusSlider
                Layout.fillWidth: true
                from: -100; to: 200
                value: conv.celsius
                onMoved: conv.celsius = value
            }
            Label {
                text: conv.formatCelsius()
                Layout.preferredWidth: 80
            }
        }

        // ---- Fahrenheit slider --------------------------------------------
        Label { text: qsTr("Fahrenheit") }
        RowLayout {
            Slider {
                id: fahrenheitSlider
                Layout.fillWidth: true
                from: -148; to: 392
                value: conv.fahrenheit
                onMoved: conv.fahrenheit = value
            }
            Label {
                text: qsTr("%1 °F").arg(conv.fahrenheit.toFixed(1))
                Layout.preferredWidth: 80
            }
        }

        // ---- Kelvin (read-only) -------------------------------------------
        RowLayout {
            Label { text: qsTr("Kelvin:"); font.bold: true }
            Label { text: qsTr("%1 K").arg(conv.kelvin.toFixed(2)) }
        }

        // ---- Unit picker — demonstrates Q_ENUM_NS in ComboBox ------------
        RowLayout {
            Label { text: qsTr("Display unit:") }
            ComboBox {
                id: unitCombo
                // The enum values are accessible as plain integers:
                //   TempUnit.Celsius = 0, TempUnit.Fahrenheit = 1, TempUnit.Kelvin = 2
                model: ["Celsius", "Fahrenheit", "Kelvin"]
                currentIndex: TempUnit.Celsius
            }
        }

        // ---- Formatted output via Q_INVOKABLE ----------------------------
        Rectangle {
            Layout.fillWidth: true
            height: 48
            radius: 6
            color: "#f0f8ff"
            border.color: "#b0c4de"

            Label {
                anchors.centerIn: parent
                font.pixelSize: 18
                text: {
                    switch (unitCombo.currentIndex) {
                        case TempUnit.Fahrenheit:
                            return qsTr("%1 °F").arg(conv.fahrenheit.toFixed(1))
                        case TempUnit.Kelvin:
                            return qsTr("%1 K").arg(conv.kelvin.toFixed(2))
                        default:
                            return conv.formatCelsius()
                    }
                }
            }
        }

        // ---- Q_GADGET demo: TemperatureReading ----------------------------
        RowLayout {
            Label { text: qsTr("Gadget toString():") }
            Label {
                text: {
                    // Construct a TemperatureReading gadget value in JS.
                    var r = temperatureReading
                    r.value = conv.celsius
                    r.unit  = TempUnit.Celsius
                    r.label = "body"
                    return r.toString()
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}
