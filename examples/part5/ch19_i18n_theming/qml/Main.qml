// Main.qml — Chapter 19: Internationalization & Runtime Theming
// --------------------------------------------------------------
// Demonstrates:
//   • qsTr() for translatable strings
//   • qsTr("%n item(s)", "", count) for plural-aware strings
//   • LanguageManager singleton to switch locale at runtime
//   • Theme singleton for dark/light colour tokens

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import com.example.i18n

ApplicationWindow {
    id: root

    visible: true
    width:   480
    height:  640
    title:   qsTr("Settings")

    color: Theme.background

    // ------------------------------------------------------------------ //
    // Helper: find the index of the currently active language in the list
    // ------------------------------------------------------------------ //
    function currentLanguageIndex(): int {
        for (let i = 0; i < LanguageManager.availableLanguages.length; i++) {
            if (LanguageManager.availableLanguages[i].code === LanguageManager.currentLanguage)
                return i;
        }
        return 0;
    }

    // ------------------------------------------------------------------ //
    // Content
    // ------------------------------------------------------------------ //
    ColumnLayout {
        anchors {
            fill:    parent
            margins: Theme.spaceL
        }
        spacing: Theme.spaceM

        // ── Page heading ──────────────────────────────────────────────
        Label {
            text:  qsTr("Settings")
            font {
                pixelSize: Theme.fontSizeHeadline
                bold:      true
            }
            color: Theme.onBackground
        }

        Rectangle {
            Layout.fillWidth: true
            height:           1
            color:            Theme.divider
        }

        // ── Language selector ─────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            spacing:          Theme.spaceS

            Label {
                text:  qsTr("Language")
                font.pixelSize: Theme.fontSizeSubtitle
                color: Theme.onBackground
            }

            ComboBox {
                id: languageCombo
                Layout.fillWidth: true

                // Build a plain string list from the list-of-dicts property
                model: LanguageManager.availableLanguages.map(l => l.name)

                currentIndex: root.currentLanguageIndex()

                // Re-sync index whenever the active language changes externally
                Connections {
                    target: LanguageManager
                    function onCurrentLanguageChanged() {
                        languageCombo.currentIndex = root.currentLanguageIndex();
                    }
                }

                onActivated: (index) => {
                    const code = LanguageManager.availableLanguages[index].code;
                    LanguageManager.setLanguage(code);
                }

                contentItem: Text {
                    leftPadding:    Theme.spaceS
                    text:           languageCombo.displayText
                    color:          Theme.onSurface
                    font.pixelSize: Theme.fontSizeBody
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    color:        Theme.surfaceVariant
                    radius:       Theme.radiusM
                    border.color: Theme.divider
                    border.width: 1
                }
            }
        }

        // ── Dark / light mode toggle ──────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing:          Theme.spaceM

            Label {
                text:           qsTr("Dark mode")
                font.pixelSize: Theme.fontSizeBody
                color:          Theme.onBackground
                Layout.fillWidth: true
            }

            Switch {
                id: darkModeSwitch
                checked: Theme.current === "dark"
                onToggled: Theme.current = checked ? "dark" : "light"

                // Tint the indicator using the theme's primary colour
                indicator: Rectangle {
                    implicitWidth:  44
                    implicitHeight: 24
                    x:              darkModeSwitch.leftPadding
                    y:              (darkModeSwitch.height - height) / 2
                    radius:         Theme.radiusFull
                    color:          darkModeSwitch.checked ? Theme.primary : Theme.surfaceVariant
                    border.color:   Theme.divider

                    Rectangle {
                        x:      darkModeSwitch.checked ? parent.width - width - 2 : 2
                        y:      2
                        width:  20
                        height: 20
                        radius: Theme.radiusFull
                        color:  Theme.onPrimary

                        Behavior on x { NumberAnimation { duration: 150 } }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height:           1
            color:            Theme.divider
        }

        // ── Translated content samples ────────────────────────────────
        Label {
            text:           qsTr("Welcome to the application")
            font.pixelSize: Theme.fontSizeBody
            color:          Theme.onBackground
            wrapMode:       Text.Wrap
            Layout.fillWidth: true
        }

        Label {
            text:           qsTr("Please select your preferred language above.")
            font.pixelSize: Theme.fontSizeBody
            color:          Theme.onSurface
            wrapMode:       Text.Wrap
            Layout.fillWidth: true
        }

        Label {
            text:           qsTr("Changes take effect immediately.")
            font.pixelSize: Theme.fontSizeBody
            color:          Theme.onSurface
            wrapMode:       Text.Wrap
            Layout.fillWidth: true
        }

        Rectangle {
            Layout.fillWidth: true
            height:           1
            color:            Theme.divider
        }

        // ── Plural demo ───────────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            spacing:          Theme.spaceS

            Label {
                text:           qsTr("Item counter demo")
                font {
                    pixelSize: Theme.fontSizeSubtitle
                    bold:      true
                }
                color: Theme.onBackground
            }

            RowLayout {
                spacing: Theme.spaceM

                RoundButton {
                    text:    "−"
                    enabled: itemCount.value > 0
                    onClicked: itemCount.value = Math.max(0, itemCount.value - 1)

                    background: Rectangle {
                        color:  Theme.primary
                        radius: Theme.radiusFull
                    }
                    contentItem: Text {
                        text:                  parent.text
                        color:                 Theme.onPrimary
                        font.pixelSize:        Theme.fontSizeTitle
                        horizontalAlignment:   Text.AlignHCenter
                        verticalAlignment:     Text.AlignVCenter
                    }
                }

                // Hidden SpinBox used purely as an integer state holder
                SpinBox {
                    id:      itemCount
                    visible: false
                    from:    0
                    to:      99
                    value:   1
                }

                Label {
                    //: %n is replaced by the item count at runtime
                    text:           qsTr("%n item(s)", "", itemCount.value)
                    font.pixelSize: Theme.fontSizeBody
                    color:          Theme.onBackground
                    Layout.fillWidth: true
                }

                RoundButton {
                    text: "+"
                    onClicked: itemCount.value = Math.min(99, itemCount.value + 1)

                    background: Rectangle {
                        color:  Theme.primary
                        radius: Theme.radiusFull
                    }
                    contentItem: Text {
                        text:                  parent.text
                        color:                 Theme.onPrimary
                        font.pixelSize:        Theme.fontSizeTitle
                        horizontalAlignment:   Text.AlignHCenter
                        verticalAlignment:     Text.AlignVCenter
                    }
                }
            }
        }

        // ── Spacer ────────────────────────────────────────────────────
        Item { Layout.fillHeight: true }

        // ── Footer ────────────────────────────────────────────────────
        Label {
            text:           qsTr("Qt Book — Chapter 19")
            font.pixelSize: Theme.fontSizeCaption
            color:          Theme.onSurface
            opacity:        0.6
            Layout.alignment: Qt.AlignHCenter
        }
    }
}
