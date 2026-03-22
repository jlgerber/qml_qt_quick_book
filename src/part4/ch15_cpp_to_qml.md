# Chapter 15: Exposing C++ Types to QML

## `Q_PROPERTY`, Notify Signals, and Binding-Compatible Design

### The `Q_PROPERTY` Macro

`Q_PROPERTY` declares a named property on a `QObject` subclass, making it accessible from QML as a binding expression target, from JavaScript, and from Qt's reflection APIs:

```cpp
Q_PROPERTY(type name
           READ getter
           [WRITE setter]
           [RESET resetFn]
           [NOTIFY notifySignal]
           [REVISION(majorVersion, minorVersion)]
           [DESIGNABLE bool]
           [STORED bool]
           [CONSTANT]
           [FINAL]
           [REQUIRED])
```

Key clauses:

**`NOTIFY`**: The signal emitted when the property value changes. QML binding expressions subscribe to this signal — without it, QML reads the property once and never updates when it changes. This is the most common oversight when writing C++ types for QML consumption.

**`CONSTANT`**: Omits the notifier; declares the value will never change. The QML engine reads it once. Do not use `CONSTANT` on properties that actually change — the binding engine will not re-evaluate.

**`FINAL`**: Declares the property will not be overridden in subclasses. The QML compiler can optimize access to `FINAL` properties.

**`REQUIRED`**: (Qt 6.1+) Marks a property that must be set when the type is instantiated. Useful for mandatory configuration:

```cpp
Q_PROPERTY(QString userId READ userId WRITE setUserId NOTIFY userIdChanged REQUIRED)
```

### Writing Binding-Compatible Properties

A property is "binding-compatible" when:
1. It has a `NOTIFY` signal
2. The signal is emitted *only* when the value actually changes (not on every set)
3. The emit happens *after* the internal state is updated

```cpp
// UserProfile.h
class UserProfile : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QString displayName READ displayName
               WRITE setDisplayName NOTIFY displayNameChanged FINAL)
    Q_PROPERTY(QUrl avatarUrl READ avatarUrl
               WRITE setAvatarUrl NOTIFY avatarUrlChanged FINAL)
    Q_PROPERTY(bool premium READ isPremium
               NOTIFY premiumChanged FINAL)

public:
    explicit UserProfile(QObject *parent = nullptr);

    QString displayName() const { return m_displayName; }
    void setDisplayName(const QString &name);

    QUrl avatarUrl() const { return m_avatarUrl; }
    void setAvatarUrl(const QUrl &url);

    bool isPremium() const { return m_premium; }

signals:
    void displayNameChanged();
    void avatarUrlChanged();
    void premiumChanged();

private:
    QString m_displayName;
    QUrl m_avatarUrl;
    bool m_premium = false;
};
```

```cpp
// UserProfile.cpp
void UserProfile::setDisplayName(const QString &name)
{
    if (m_displayName == name)  // guard: emit only on actual change
        return;
    m_displayName = name;       // update state first
    emit displayNameChanged();  // then notify
}
```

The equality guard is critical. Without it, setting the same value triggers binding re-evaluation, which may cascade through the entire QML binding graph. For expensive-to-compare types, profile before adding the guard, but for strings and numerics, always guard.

### Object Properties

Properties that hold `QObject*` pointers work in QML, but ownership must be explicit:

```cpp
Q_PROPERTY(UserProfile *profile READ profile
           WRITE setProfile NOTIFY profileChanged)
```

When QML reads an object property, it gets a reference to the C++ object. The C++ object must outlive the QML reference. Common patterns:

- **Parent the sub-object** to the containing object: lifetime tied to container
- **Use `QQmlEngine::setObjectOwnership`**: explicitly set C++ ownership to prevent QML GC

```cpp
void setProfile(UserProfile *profile) {
    if (m_profile == profile)
        return;
    if (m_profile)
        m_profile->setParent(nullptr);  // release old profile
    m_profile = profile;
    if (m_profile)
        m_profile->setParent(this);     // take ownership
    emit profileChanged();
}
```

---

## Gadgets vs. `QObject`: Value Types in QML with `Q_GADGET`

`Q_GADGET` enables Qt's meta-object features on a class that does *not* inherit `QObject`. Gadgets are value types — they are copied, not referenced, and have no identity, signals, or parent-child relationships.

### When to Use Gadgets

Use `Q_GADGET` for:
- Small data transfer objects (DTOs) returned from C++ to QML
- Configuration structures
- Any type that is logically a value (two instances with the same data are equivalent)

Use `Q_OBJECT` for:
- Objects with identity (two instances are distinct even with the same data)
- Objects that emit signals
- Objects with parent-child ownership

### Declaring a Gadget

```cpp
// color_info.h
#include <QColor>
#include <QtQml/qqml.h>

class ColorInfo
{
    Q_GADGET
    QML_VALUE_TYPE(colorInfo)   // registers as a QML value type

    Q_PROPERTY(int red READ red CONSTANT)
    Q_PROPERTY(int green READ green CONSTANT)
    Q_PROPERTY(int blue READ blue CONSTANT)
    Q_PROPERTY(float luminance READ luminance CONSTANT)

public:
    ColorInfo() = default;
    explicit ColorInfo(const QColor &color);

    int red() const { return m_color.red(); }
    int green() const { return m_color.green(); }
    int blue() const { return m_color.blue(); }
    float luminance() const;

    Q_INVOKABLE QString toHexString() const;

private:
    QColor m_color;
};

Q_DECLARE_METATYPE(ColorInfo)
```

`QML_VALUE_TYPE(colorInfo)` registers the gadget as a QML type with the given lowercase name. QML can read gadget properties and call `Q_INVOKABLE` methods, but cannot create gadget instances directly in QML (use a factory function).

### Returning Gadgets from C++

```cpp
class ColorAnalyzer : public QObject
{
    Q_OBJECT
    QML_ELEMENT

public:
    Q_INVOKABLE ColorInfo analyze(const QColor &color) const;
};
```

In QML:

```qml
ColorAnalyzer {
    id: analyzer
}

Text {
    property colorInfo info: analyzer.analyze(selectedColor)
    text: "R: " + info.red + " G: " + info.green + " Luminance: " + info.luminance.toFixed(2)
}
```

### Lists of Gadgets

Return a `QList<MyGadget>` from a C++ function to provide a list of value objects:

```cpp
Q_INVOKABLE QList<ColorInfo> analyzeImage(const QUrl &imageUrl) const;
```

In QML, this becomes a JavaScript array of `colorInfo` objects, iterable with `for...of` and usable in model roles.

---

## Invokable Methods, Enums, and Flags

### `Q_INVOKABLE`

`Q_INVOKABLE` marks a method as callable from QML (and from `QMetaObject::invokeMethod`):

```cpp
class FileManager : public QObject
{
    Q_OBJECT
    QML_ELEMENT

public:
    Q_INVOKABLE bool fileExists(const QString &path) const;
    Q_INVOKABLE QString readTextFile(const QString &path) const;
    Q_INVOKABLE bool writeTextFile(const QString &path, const QString &content);

    // Async variant: takes a callback
    Q_INVOKABLE void readFileAsync(const QString &path, const QJSValue &callback);
};
```

`Q_INVOKABLE` methods can take and return any type registered with the meta-object system. For complex return types, use `Q_DECLARE_METATYPE` and `qRegisterMetaType`.

**Returning objects vs. values**: Returning a raw `QObject*` from an invokable transfers a reference to QML. By default, QML takes ownership (QML engine may GC it). To retain C++ ownership:

```cpp
Q_INVOKABLE QObject *createItem() {
    auto *item = new MyItem(this);  // parent = this, C++ owns it
    QQmlEngine::setObjectOwnership(item, QQmlEngine::CppOwnership);
    return item;
}
```

### `Q_INVOKABLE` with `QJSValue` Callbacks

For asynchronous operations, accept a JavaScript function as a callback:

```cpp
void FileManager::readFileAsync(const QString &path, const QJSValue &callback)
{
    auto *watcher = new QFutureWatcher<QString>(this);
    connect(watcher, &QFutureWatcher<QString>::finished, this,
            [this, watcher, callback]() mutable {
                QString result = watcher->result();
                watcher->deleteLater();
                // Call the JS callback on the main thread
                QJSValue cb = callback;
                cb.call({result});
            });

    watcher->setFuture(QtConcurrent::run([path]() {
        QFile f(path);
        f.open(QIODevice::ReadOnly);
        return QString::fromUtf8(f.readAll());
    }));
}
```

In QML:

```qml
fileManager.readFileAsync(path, (content) => {
    textEdit.text = content
})
```

### `Q_ENUM` and `Q_ENUM_NS`

Enums declared with `Q_ENUM` are accessible from QML with full name qualification:

```cpp
class NetworkStatus : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    enum Status {
        Offline,
        Connecting,
        Online,
        Error
    };
    Q_ENUM(Status)

    Q_PROPERTY(Status current READ current NOTIFY currentChanged)
    // ...
};
```

In QML:

```qml
import com.example.backend

Rectangle {
    color: NetworkStatus.current === NetworkStatus.Online
           ? "green" : "red"
}
```

For namespace-scoped enums (not inside a `QObject`), use `Q_ENUM_NS` within a `Q_NAMESPACE` struct:

```cpp
namespace AppConstants {
    Q_NAMESPACE
    QML_ELEMENT

    enum class Theme { Light, Dark, System };
    Q_ENUM_NS(Theme)
}
```

### `Q_FLAG` and `Q_FLAG_NS`

Bitfield flag enums:

```cpp
class Permission : public QObject
{
    Q_OBJECT
    QML_ELEMENT

public:
    enum Access {
        None    = 0x0,
        Read    = 0x1,
        Write   = 0x2,
        Execute = 0x4,
        Admin   = 0xFF
    };
    Q_DECLARE_FLAGS(AccessFlags, Access)
    Q_FLAG(Access)

    Q_INVOKABLE bool hasAccess(AccessFlags flags, Access required) const {
        return flags & required;
    }
};
```

In QML:

```qml
permission.hasAccess(userFlags, Permission.Write | Permission.Read)
```

---

## Property Bindings and Change Guards: Practical Patterns

### Batch Updates with `blockSignals`

When updating multiple related properties at once, use `blockSignals` to suppress intermediate notifications and emit a single comprehensive signal afterward:

```cpp
void DocumentModel::loadDocument(const Document &doc)
{
    blockSignals(true);
    setTitle(doc.title);
    setAuthor(doc.author);
    setWordCount(doc.wordCount);
    blockSignals(false);

    emit documentLoaded();  // single signal covering all changes
}
```

QML bindings on `title`, `author`, and `wordCount` will re-evaluate once, after all values are set, rather than three times during the update.

### `QBindable` and C++20 Bindable Properties

Qt 6.0 introduced `QBindable<T>` — a C++ property binding system that mirrors QML bindings but operates within C++:

```cpp
class TemperatureConverter : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(double celsius READ celsius WRITE setCelsius NOTIFY celsiusChanged BINDABLE bindableCelsius)
    Q_PROPERTY(double fahrenheit READ fahrenheit WRITE setFahrenheit NOTIFY fahrenheitChanged BINDABLE bindableFahrenheit)

public:
    TemperatureConverter() {
        // C++ binding: fahrenheit is always (celsius * 9/5) + 32
        m_fahrenheit.setBinding([this]() {
            return m_celsius.value() * 9.0 / 5.0 + 32.0;
        });
    }

    double celsius() const { return m_celsius; }
    void setCelsius(double v) { m_celsius = v; }
    QBindable<double> bindableCelsius() { return &m_celsius; }

    double fahrenheit() const { return m_fahrenheit; }
    void setFahrenheit(double v) {
        // Setting fahrenheit breaks the binding and recomputes celsius
        m_fahrenheit = v;
        m_celsius = (v - 32.0) * 5.0 / 9.0;
    }
    QBindable<double> bindableFahrenheit() { return &m_fahrenheit; }

signals:
    void celsiusChanged();
    void fahrenheitChanged();

private:
    Q_OBJECT_BINDABLE_PROPERTY(TemperatureConverter, double, m_celsius,
                                &TemperatureConverter::celsiusChanged)
    Q_OBJECT_BINDABLE_PROPERTY(TemperatureConverter, double, m_fahrenheit,
                                &TemperatureConverter::fahrenheitChanged)
};
```

`Q_OBJECT_BINDABLE_PROPERTY` is a slot-in replacement for a plain member that participates in Qt's C++ binding graph. Changes propagate automatically in C++ without manual `emit` calls.

---

## Summary

Effective C++-to-QML type exposure requires disciplined use of `Q_PROPERTY` with proper `NOTIFY` signals and change guards. Choosing between `QObject` (reference type, signals, ownership) and `Q_GADGET` (value type, no signals, copied) determines the API contract. `Q_INVOKABLE` methods, `Q_ENUM` / `Q_FLAG`, and `Q_OBJECT_BINDABLE_PROPERTY` complete the toolkit for rich, type-safe C++/QML interfaces. With `QML_ELEMENT` macros and `qt_add_qml_module` in CMake, the boilerplate of type registration is eliminated, leaving clean C++ header declarations that directly map to QML types.
