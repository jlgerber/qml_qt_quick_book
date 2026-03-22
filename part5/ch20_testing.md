# Chapter 20: Testing Qt Quick Applications

## `qmltest` and `TestCase`: Unit Testing QML Components

`QtTest`'s QML API provides a declarative testing framework where tests are written in QML and run by the `qmltestrunner` tool. Tests live alongside the components they test and can directly manipulate QML items, simulate user input, and assert on property values.

### Basic Test Structure

```qml
// tst_counter.qml
import QtTest
import com.example.backend

TestCase {
    name: "CounterTests"

    Counter {
        id: counter
    }

    function test_initialValue() {
        compare(counter.value, 0)
    }

    function test_increment() {
        counter.increment()
        compare(counter.value, 1)
        counter.increment()
        compare(counter.value, 2)
    }

    function test_reset() {
        counter.value = 10
        counter.reset()
        compare(counter.value, 0)
    }

    function test_valueChanged_signal() {
        let spy = Qt.createQmlObject(
            "import QtTest; SignalSpy { target: counter; signalName: 'valueChanged' }",
            testCase
        )
        counter.increment()
        compare(spy.count, 1)
    }
}
```

All functions whose names start with `test_` are test functions. `TestCase` runs them alphabetically. The framework provides:

| Function | Assertion |
|---|---|
| `compare(actual, expected)` | Deep equality |
| `fuzzyCompare(a, b, delta)` | Floating point equality within delta |
| `verify(expression)` | Truthy value |
| `fail(message)` | Unconditional failure |
| `skip(message)` | Skip the test |
| `expectFail(tag, message)` | Expect this test to fail |
| `tryCompare(object, property, value, timeout)` | Wait for async property change |
| `tryVerify(expression, timeout)` | Wait for condition to become true |

### Testing Visual Components

To test a QML component's visual structure and geometry, instantiate it using the `TestCase` item itself as a parent or in a dedicated window:

```qml
TestCase {
    name: "ButtonTests"
    width: 300; height: 200
    visible: true     // Required for geometry to be computed

    function createButton(props) {
        return createTemporaryQmlObject(
            `import QtQuick.Controls
             Button { ${Object.entries(props).map(([k,v]) => `${k}: "${v}"`).join(';')} }`,
            parent
        )
    }

    function test_buttonText() {
        let btn = createButton({ text: "Save" })
        compare(btn.text, "Save")
        verify(btn.implicitWidth > 0)
    }

    function test_buttonClick() {
        let clickCount = 0
        let btn = createButton({ text: "OK" })
        btn.clicked.connect(() => clickCount++)

        mouseClick(btn)
        compare(clickCount, 1)
    }
}
```

`createTemporaryQmlObject()` creates an object and automatically destroys it after the test function returns — preventing test state from leaking between tests.

### `SignalSpy`

`SignalSpy` monitors signal emissions and records how many times a signal fired and what arguments it received:

```qml
SignalSpy {
    id: spy
    target: myObject
    signalName: "dataReady"
}

function test_signalEmitted() {
    spy.clear()
    myObject.fetchData()
    tryCompare(spy, "count", 1, 5000)  // wait up to 5 seconds
    compare(spy.signalArguments[0][0], expectedData)
}
```

`tryCompare` is essential for testing asynchronous operations: it polls the property until it matches or the timeout expires.

### Simulating User Input

```qml
function test_keyboardInput() {
    let field = createTemporaryQmlObject(
        "import QtQuick.Controls; TextField { }", parent)
    field.forceActiveFocus()

    keyClick(Qt.Key_H)
    keyClick(Qt.Key_I)
    compare(field.text, "hi")

    keySequence(StandardKey.SelectAll)
    keyClick(Qt.Key_Delete)
    compare(field.text, "")
}

function test_mouseInteraction() {
    // mousePress, mouseRelease, mouseClick, mouseDoubleClick
    mouseClick(item, 10, 10, Qt.LeftButton)
    mouseDrag(item, 0, 0, 100, 0)
    mouseWheel(item, 0, 0, 0, -120)  // scroll down
}
```

### Running Tests

```bash
# Run with qmltestrunner
qmltestrunner -import path/to/qml/modules -input tests/

# Run specific test file
qmltestrunner -input tests/tst_counter.qml

# With CMake
add_test(NAME QmlTests
    COMMAND qmltestrunner -import ${CMAKE_SOURCE_DIR}/qml -input ${CMAKE_CURRENT_SOURCE_DIR}
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
)
```

---

## `QTest` for C++ Backend Logic

Qt's `QTest` framework is the standard for testing C++ code in Qt projects. It integrates with `ctest` and generates output compatible with CI systems.

### Test Class Structure

```cpp
// tst_contactmodel.cpp
#include <QTest>
#include "contactmodel.h"

class TestContactModel : public QObject
{
    Q_OBJECT

private slots:
    // Test lifecycle
    void initTestCase();     // Called once before all tests
    void cleanupTestCase();  // Called once after all tests
    void init();             // Called before each test
    void cleanup();          // Called after each test

    // Test functions
    void test_initiallyEmpty();
    void test_append();
    void test_remove();
    void test_dataChanged_signal();
    void test_filterProxy();
};

void TestContactModel::init() {
    // Called before each test — set up fresh state
}

void TestContactModel::test_initiallyEmpty() {
    ContactModel model;
    QCOMPARE(model.rowCount(), 0);
}

void TestContactModel::test_append() {
    ContactModel model;
    model.appendContact("Alice", "alice@example.com");
    QCOMPARE(model.rowCount(), 1);

    const QModelIndex idx = model.index(0);
    QCOMPARE(model.data(idx, ContactModel::NameRole).toString(), "Alice");
    QCOMPARE(model.data(idx, ContactModel::EmailRole).toString(), "alice@example.com");
}

void TestContactModel::test_remove() {
    ContactModel model;
    model.appendContact("Alice", "alice@example.com");
    model.appendContact("Bob", "bob@example.com");

    model.removeContact(0);

    QCOMPARE(model.rowCount(), 1);
    QCOMPARE(model.data(model.index(0), ContactModel::NameRole).toString(), "Bob");
}

void TestContactModel::test_dataChanged_signal() {
    ContactModel model;
    model.appendContact("Alice", "alice@example.com");

    QSignalSpy spy(&model, &ContactModel::dataChanged);
    model.updateEmail(0, "new@example.com");

    QCOMPARE(spy.count(), 1);
    // Verify correct roles in the signal
    const QList<int> roles = spy[0][2].value<QList<int>>();
    QVERIFY(roles.contains(ContactModel::EmailRole));
    QVERIFY(!roles.contains(ContactModel::NameRole));
}

QTEST_MAIN(TestContactModel)
#include "tst_contactmodel.moc"
```

### `QSignalSpy`

`QSignalSpy` records signal emissions. It is the QTest equivalent of QML's `SignalSpy`:

```cpp
QSignalSpy spy(&model, &QAbstractItemModel::rowsInserted);
model.appendContact("Test", "test@example.com");

QCOMPARE(spy.count(), 1);
// Arguments: parent, first, last
QCOMPARE(spy[0][1].toInt(), 0);   // first row = 0
QCOMPARE(spy[0][2].toInt(), 0);   // last row = 0
```

### Data-Driven Tests with `_data()` Functions

Test functions paired with a `_data()` function run once per row of the data table:

```cpp
void TestContactModel::test_filterProxy_data() {
    QTest::addColumn<QString>("filterString");
    QTest::addColumn<int>("expectedCount");

    QTest::newRow("empty filter") << "" << 3;
    QTest::newRow("partial match") << "ali" << 1;
    QTest::newRow("no match") << "xyz" << 0;
    QTest::newRow("case insensitive") << "BOB" << 1;
}

void TestContactModel::test_filterProxy() {
    QFETCH(QString, filterString);
    QFETCH(int, expectedCount);

    ContactModel source;
    source.appendContact("Alice", "alice@example.com");
    source.appendContact("Bob", "bob@example.com");
    source.appendContact("Charlie", "charlie@example.com");

    QSortFilterProxyModel proxy;
    proxy.setSourceModel(&source);
    proxy.setFilterRole(ContactModel::NameRole);
    proxy.setFilterCaseSensitivity(Qt::CaseInsensitive);
    proxy.setFilterFixedString(filterString);

    QCOMPARE(proxy.rowCount(), expectedCount);
}
```

### Testing Asynchronous C++ Code

For code that uses `QFuture`, `QTimer`, or signals to deliver results asynchronously:

```cpp
void TestSearch::test_asyncSearch() {
    SearchModel model;
    QSignalSpy spy(&model, &SearchModel::searchComplete);

    model.search("qt quick");

    // Wait for the signal, up to 5 seconds
    QVERIFY(spy.wait(5000));
    QCOMPARE(spy.count(), 1);
    QVERIFY(model.rowCount() > 0);
}
```

`QSignalSpy::wait(ms)` runs the event loop until the signal fires or the timeout expires.

### CMake Test Setup

```cmake
# In tests/CMakeLists.txt
find_package(Qt6 REQUIRED COMPONENTS Test)

function(add_qt_test name)
    qt_add_executable(${name} ${name}.cpp)
    target_link_libraries(${name} PRIVATE Qt6::Test myapp_backend)
    add_test(NAME ${name} COMMAND ${name})
endfunction()

add_qt_test(tst_contactmodel)
add_qt_test(tst_searchservice)
add_qt_test(tst_filterproxy)
```

---

## End-to-End UI Testing Strategies

Full end-to-end testing of Qt Quick UIs — simulating user interactions through the complete application stack — is the most difficult testing layer.

### Approach 1: Squish (Commercial)

Froglogic's Squish is the industry-standard test automation tool for Qt applications. It supports:
- Object identification by name, type, or property
- Recording and playback of interactions
- Script-based tests in Python, JavaScript, Tcl, Ruby, or Perl
- Image recognition for custom-drawn items

```python
# Squish test example (Python API)
startApplication("myapp")
clickButton(waitForObject(":mainWindow.saveButton_Button"))
type(waitForObject(":dialog.filenameField_TextField"), "output.pdf")
clickButton(waitForObject(":dialog.okButton_Button"))
waitForObjectExists(":statusBar.saveSuccess_Label")
```

### Approach 2: `QAbstractItemModelTester`

For model testing specifically, `QAbstractItemModelTester` (from `Qt6::Test`) automatically validates that a model implementation follows the contract — correct begin/end bracket pairing, valid indices, consistent row counts:

```cpp
void TestContactModel::test_modelIntegrity() {
    ContactModel model;
    auto *tester = new QAbstractItemModelTester(
        &model,
        QAbstractItemModelTester::FailureReportingMode::Fatal,
        this
    );

    // Perform model mutations — tester automatically validates each change
    model.appendContact("Alice", "alice@example.com");
    model.appendContact("Bob", "bob@example.com");
    model.removeContact(0);
}
```

This catches common model implementation bugs (missing `beginInsertRows`, wrong row counts after mutation) that would otherwise appear as subtle view glitches.

### Approach 3: Headless Testing with `QOffscreenSurface`

For testing visual behavior without a display:

```bash
QT_QPA_PLATFORM=offscreen ./qmltestrunner -input tests/
```

The offscreen platform renders to memory buffers. Geometry is computed, animations run, and items respond to input — but nothing appears on screen. This is suitable for CI environments without a display.

### Approach 4: Screenshot-Based Regression Testing

For visual regression detection, render items to images and compare:

```cpp
void TestVisuals::test_buttonAppearance() {
    QQuickView view;
    view.setSource(QUrl("qrc:/qml/components/PrimaryButton.qml"));
    view.show();
    QTest::qWaitForWindowExposed(&view);

    // Grab the scene
    QImage rendered = view.grabWindow();
    QImage reference(":/test_references/primary_button_normal.png");

    QVERIFY(imagesMatch(rendered, reference, /* tolerance= */ 2));
}
```

Store reference images in version control. Run on CI with a fixed display DPI to avoid platform-dependent differences.

---

## Summary

Testing a Qt Quick application spans three layers. QML's `TestCase` framework tests component behavior, user input simulation, and signal-driven async operations directly in QML. `QTest` handles C++ backend unit testing with typed assertions, `QSignalSpy`, data-driven test tables, and `QAbstractItemModelTester` for model contract validation. End-to-end testing relies on either commercial tools (Squish), headless rendering (offscreen platform), or screenshot regression tests. The highest-leverage tests are those for C++ models and service logic — they run fast, require no display, and cover the most error-prone code. QML component tests complement these for UI-specific behavior and accessibility.
