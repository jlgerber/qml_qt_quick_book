// Theme.qml — Design-token singleton for dark/light mode
// -------------------------------------------------------
// Usage (after qmldir registers it as a singleton):
//
//   import com.example.i18n
//   Rectangle { color: Theme.background }
//
// Switching modes:
//   Theme.current = "light"

pragma Singleton

import QtQuick

QtObject {
    id: root

    // ------------------------------------------------------------------ //
    // Mode toggle — write this property to switch the whole UI
    // ------------------------------------------------------------------ //
    property string current: "dark"   // "dark" | "light"

    readonly property bool isDark: current === "dark"

    // ------------------------------------------------------------------ //
    // Colour tokens
    // ------------------------------------------------------------------ //

    // Brand / accent
    readonly property color primary:      isDark ? "#BB86FC" : "#6200EE"
    readonly property color primaryVariant: isDark ? "#3700B3" : "#3700B3"
    readonly property color secondary:    isDark ? "#03DAC6" : "#018786"

    // Surfaces
    readonly property color background:   isDark ? "#121212" : "#FFFFFF"
    readonly property color surface:      isDark ? "#1E1E1E" : "#F5F5F5"
    readonly property color surfaceVariant: isDark ? "#2C2C2C" : "#E8E8E8"

    // Text / icon colours (on top of the surfaces above)
    readonly property color onBackground: isDark ? "#E1E1E1" : "#121212"
    readonly property color onSurface:    isDark ? "#CCCCCC" : "#333333"
    readonly property color onPrimary:    isDark ? "#000000" : "#FFFFFF"

    // Semantic
    readonly property color error:        isDark ? "#CF6679" : "#B00020"
    readonly property color success:      isDark ? "#81C784" : "#388E3C"
    readonly property color divider:      isDark ? "#2E2E2E" : "#E0E0E0"

    // ------------------------------------------------------------------ //
    // Spacing scale (multiples of a base unit)
    // ------------------------------------------------------------------ //
    readonly property int spaceXS:  4
    readonly property int spaceS:   8
    readonly property int spaceM:  16
    readonly property int spaceL:  24
    readonly property int spaceXL: 32

    // ------------------------------------------------------------------ //
    // Shape tokens
    // ------------------------------------------------------------------ //
    readonly property int radiusS:  4
    readonly property int radiusM:  8
    readonly property int radiusL: 16
    readonly property int radiusFull: 9999   // pill / circle

    // ------------------------------------------------------------------ //
    // Typography scale (pixel sizes)
    // ------------------------------------------------------------------ //
    readonly property int fontSizeCaption:   11
    readonly property int fontSizeBody:      14
    readonly property int fontSizeSubtitle:  16
    readonly property int fontSizeTitle:     20
    readonly property int fontSizeHeadline:  24
}
