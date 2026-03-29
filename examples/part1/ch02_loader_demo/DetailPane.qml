import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// DetailPane — loaded on demand by the first Loader in Main.qml.
// Demonstrates a component with a required property supplied via
// Loader.setSource() initial properties.
Rectangle {
    id: root

    // Caller must supply this; Loader will pass it as an initial property.
    required property string title

    implicitWidth: 400
    implicitHeight: 140
    color: "#1e272e"
    radius: 8
    border.color: "#3daee9"
    border.width: 2

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 8

        Label {
            text: root.title
            font.pixelSize: 18
            font.bold: true
            color: "#3daee9"
        }

        Label {
            Layout.fillWidth: true
            text: "This pane was loaded on demand.\n"
                + "It will be destroyed when the Loader is deactivated."
            color: "#dfe6e9"
            font.pixelSize: 13
            wrapMode: Text.WordWrap
        }

        Label {
            text: "Component.onCompleted fired at: " + Qt.formatTime(new Date(), "hh:mm:ss")
            color: "#b2bec3"
            font.pixelSize: 11
        }
    }

    Component.onCompleted: console.log("DetailPane created:", root.title)
    Component.onDestruction: console.log("DetailPane destroyed:", root.title)
}
