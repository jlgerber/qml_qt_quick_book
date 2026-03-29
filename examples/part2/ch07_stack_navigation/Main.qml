// Main.qml — ch07_stack_navigation
// Demonstrates StackView-based navigation wired through a lightweight
// NavigationController singleton (inline QtObject).
//
// Pattern:
//   1. NavigationController exposes navigateTo(screen, props) and back() signals.
//   2. A Connections block in Main.qml translates those signals into
//      stack.push() / stack.pop() calls — keeping screens decoupled from the
//      StackView itself.
//   3. Screens import NavigationController by id reference (root.navCtrl).
//
// Run with:
//   qml Main.qml

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id:      root
    title:   "Chapter 7 – Stack Navigation"
    width:   480
    height:  700
    visible: true

    background: Rectangle { color: "#f8f7ff" }

    // ── Navigation controller singleton ───────────────────────────────────
    // Screens call navCtrl.navigateTo(...) or navCtrl.back(); Main.qml
    // listens via Connections and drives the StackView.
    QtObject {
        id: navCtrl

        // Emitted by screens that want to push a new screen
        signal navigateTo(string screenName, var properties)

        // Emitted by screens that want to pop back
        signal back()
    }

    // ── Expose controller to child screens via a property ─────────────────
    // Screens receive this as a required property so they never reference
    // root directly — keeping the coupling minimal.
    property alias navigationController: navCtrl

    // ── Wire signals → StackView actions ─────────────────────────────────
    Connections {
        target: navCtrl

        function onNavigateTo(screenName, properties) {
            // Resolve the Component by name
            const components = {
                "Home":   homeComponent,
                "Detail": detailComponent
            }
            const comp = components[screenName]
            if (!comp) {
                console.warn("NavigationController: unknown screen:", screenName)
                return
            }

            // Merge navigation controller into pushed properties so child
            // screens can call back() etc.
            const merged = Object.assign({ navigationController: navCtrl }, properties || {})
            stack.push(comp, merged)
        }

        function onBack() {
            if (stack.depth > 1)
                stack.pop()
        }
    }

    // ── Screen components (defined inline; could also be in separate files) ─
    Component { id: homeComponent;   HomeScreen   { navigationController: navCtrl } }
    Component { id: detailComponent; DetailScreen { navigationController: navCtrl } }

    // ── StackView ─────────────────────────────────────────────────────────
    StackView {
        id:           stack
        anchors.fill: parent

        // Initial screen
        initialItem: homeComponent

        // Slide transition (push = slide in from right, pop = slide out right)
        pushEnter: Transition {
            XAnimator { from: stack.width; to: 0; duration: 280; easing.type: Easing.OutCubic }
        }
        pushExit: Transition {
            XAnimator { from: 0; to: -stack.width * 0.3; duration: 280; easing.type: Easing.OutCubic }
        }
        popEnter: Transition {
            XAnimator { from: -stack.width * 0.3; to: 0; duration: 280; easing.type: Easing.OutCubic }
        }
        popExit: Transition {
            XAnimator { from: 0; to: stack.width; duration: 280; easing.type: Easing.OutCubic }
        }
    }
}
