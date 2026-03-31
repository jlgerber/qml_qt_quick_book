// Chapter 13 – Deployment
// Minimal window that demonstrates a complete pyside6-deploy workflow.
// Shows Qt and PySide6 version strings sourced from the Python AppInfo backend.

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import com.example.deploy

ApplicationWindow {
    id: root
    title: "Deploy Demo"
    width: 480
    height: 280
    visible: true

    AppInfo {
        id: appInfo
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 16

        Label {
            Layout.alignment: Qt.AlignHCenter
            text: "Deployment Demo"
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
    }
}
