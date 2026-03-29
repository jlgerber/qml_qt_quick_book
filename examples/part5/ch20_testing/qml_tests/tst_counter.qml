// tst_counter.qml — QML unit tests for a self-contained Counter type
// -------------------------------------------------------------------
// Run with:
//   qmltestrunner -input tst_counter.qml
//
// The Counter component is defined inline as a Component so no external
// backend or installed module is required.

import QtQuick
import QtTest

TestCase {
    id:   root
    name: "CounterTests"

    // ------------------------------------------------------------------ //
    // Self-contained Counter component
    // ------------------------------------------------------------------ //
    // Exposes:
    //   property int value  (read-only via alias)
    //   signal valueChanged(int newValue)
    //   function increment()
    //   function decrement()   — clamps at 0
    //   function reset()
    // ------------------------------------------------------------------ //
    Component {
        id: counterComponent

        QtObject {
            id: counter

            // Internal mutable state
            property int _value: 0

            // Public read alias
            readonly property alias value: counter._value

            // Emitted whenever _value changes
            signal valueChanged(int newValue)

            // Watch the internal property and forward as a named signal
            // so tests can attach a SignalSpy to `valueChanged`.
            onValueChanged: counter.valueChanged(counter._value)

            function increment() {
                counter._value += 1;
            }

            function decrement() {
                if (counter._value > 0)
                    counter._value -= 1;
            }

            function reset() {
                counter._value = 0;
            }
        }
    }

    // ------------------------------------------------------------------ //
    // Helpers
    // ------------------------------------------------------------------ //

    // Create a fresh counter instance for each test
    property var counter: null

    function init() {
        // init() is called before every test_ function by QML TestCase
        counter = counterComponent.createObject(root);
    }

    function cleanup() {
        if (counter) {
            counter.destroy();
            counter = null;
        }
    }

    // ------------------------------------------------------------------ //
    // Tests
    // ------------------------------------------------------------------ //

    function test_initialValue() {
        compare(counter.value, 0, "Counter should start at 0");
    }

    function test_increment() {
        counter.increment();
        compare(counter.value, 1, "After one increment value should be 1");

        counter.increment();
        counter.increment();
        compare(counter.value, 3, "After three increments value should be 3");
    }

    function test_decrement() {
        // Start at a known positive value
        counter.increment();
        counter.increment();
        counter.increment();   // value == 3

        counter.decrement();
        compare(counter.value, 2, "After one decrement from 3 value should be 2");

        counter.decrement();
        counter.decrement();
        compare(counter.value, 0, "After decrementing to zero value should be 0");
    }

    function test_reset() {
        counter.increment();
        counter.increment();
        counter.increment();   // value == 3

        counter.reset();
        compare(counter.value, 0, "reset() should set value back to 0");
    }

    function test_valueChanged_signal() {
        let spy = Qt.createQmlObject(
            'import QtTest; SignalSpy {}',
            root,
            "spy"
        );
        spy.target      = counter;
        spy.signalName  = "valueChanged";

        compare(spy.count, 0, "No signals emitted yet");

        counter.increment();
        compare(spy.count, 1, "One signal after increment");

        counter.decrement();
        compare(spy.count, 2, "Two signals after decrement");

        counter.reset();
        compare(spy.count, 3, "Three signals after reset");

        spy.destroy();
    }

    function test_minimum_clamp() {
        // Value must never go below zero
        compare(counter.value, 0, "Starts at zero");

        counter.decrement();
        compare(counter.value, 0, "Decrement at zero stays at zero");

        counter.decrement();
        counter.decrement();
        compare(counter.value, 0, "Multiple decrements at zero stay at zero");

        // Going positive and back to zero should still clamp
        counter.increment();
        counter.decrement();
        compare(counter.value, 0, "Back to zero after increment+decrement");

        counter.decrement();
        compare(counter.value, 0, "Clamped at zero after further decrement");
    }

    function test_incrementDecrementSymmetry() {
        // n increments followed by n decrements should return to 0
        const n = 5;
        for (let i = 0; i < n; i++) counter.increment();
        compare(counter.value, n, "Value after " + n + " increments");

        for (let i = 0; i < n; i++) counter.decrement();
        compare(counter.value, 0, "Value after " + n + " decrements from " + n);
    }
}
