// Chapter 9 – Hello PySide6
// Main window: shows Qt and PySide6 version strings from Python backend.

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import com.example.hello

ApplicationWindow {
    id: root
    title: "Hello PySide6"
    width: 480
    height: 320
    visible: true

    // AppInfo is a @QmlElement – instantiate it like any QML type.
    AppInfo {
        id: appInfo
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 16

        Label {
            Layout.alignment: Qt.AlignHCenter
            text: "Hello from PySide6 + QML!"
            font.pixelSize: 24
            font.bold: true
        }

        Label {
            Layout.alignment: Qt.AlignHCenter
            text: "Qt version: " + appInfo.qtVersion
            font.pixelSize: 16
        }

        Label {
            Layout.alignment: Qt.AlignHCenter
            text: "PySide6 version: " + appInfo.pysideVersion
            font.pixelSize: 16
        }

        Button {
            Layout.alignment: Qt.AlignHCenter
            text: "Say Hello"
            onClicked: greet()
        }
    }

    // ---------------------------------------------------------------------------
    // Functions / slots
    // ---------------------------------------------------------------------------

    function greet() {
        console.log("Hello from QML! Qt", appInfo.qtVersion,
                    "/ PySide6", appInfo.pysideVersion)
    }
}
