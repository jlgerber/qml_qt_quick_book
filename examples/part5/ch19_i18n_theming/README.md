# Chapter 19 — Internationalization and Runtime Theming

Demonstrates two independent but complementary runtime-switching techniques
that every production Qt Quick application needs:

1. **Internationalization (i18n)** — loading a `QTranslator` on startup based
   on `QLocale.system()`, and reinstalling a different translator at runtime
   without restarting the application.

2. **Runtime theming** — a `pragma Singleton` QML object that holds all
   design-tokens (colours, spacing, radius, font sizes) as computed properties
   that react immediately when a single `current` string property is changed.

---

## What each file does

| File | Purpose |
|------|---------|
| `main.py` | PySide6 entry point. Installs the system translator on start. Registers the `LanguageManager` QmlElement/QmlSingleton. |
| `qml/Main.qml` | ApplicationWindow. Wires the language ComboBox, dark-mode Switch, translated labels, and plural counter demo. |
| `qml/Theme.qml` | `pragma Singleton`. All colour/spacing/shape tokens as ternary expressions on `Theme.current`. |
| `qml/qmldir` | Declares the `com.example.i18n` module and registers `Theme` as a singleton. |
| `translations/app_de.ts` | German TS source file with finished translations for all `qsTr()` strings. |

---

## Key concepts illustrated

### LanguageManager singleton

```python
@QmlElement
@QmlSingleton
class LanguageManager(QObject):
    @Slot(str)
    def setLanguage(self, code: str) -> None:
        app.removeTranslator(old_translator)
        app.installTranslator(new_translator)
        self._engine.retranslate()   # re-evaluates all qsTr() in QML
```

`engine.retranslate()` is the key call — it forces every bound `qsTr()`
expression to re-evaluate without reloading any QML files.

### Theme singleton

```qml
pragma Singleton
QtObject {
    property string current: "dark"
    readonly property color primary: isDark ? "#BB86FC" : "#6200EE"
}
```

All colours are ternary expressions on `isDark`, so changing `Theme.current`
propagates instantly to every bound property in the UI.

### Plural-aware strings

```qml
qsTr("%n item(s)", "", itemCount.value)
```

The German `.ts` file provides separate singular and plural forms:

```xml
<numerusform>%n Element</numerusform>
<numerusform>%n Elemente</numerusform>
```

---

## How to run

### Prerequisites

- Python 3.11+
- PySide6 6.6+ (`pip install PySide6`)

### Run with the system locale

```bash
cd examples/part5/ch19_i18n_theming
python main.py
```

### Force a specific language

```bash
python main.py --lang de
```

> **Note:** German requires a compiled `.qm` file. Compile it first:
>
> ```bash
> lrelease translations/app_de.ts -qm translations/app_de.qm
> ```
>
> `lrelease` ships with Qt and is usually at
> `$(python -c "import PySide6; print(PySide6.__path__[0])")/lrelease`.

### Switch language at runtime

The ComboBox in the UI lets you switch between English, German, and French
while the application is running. French has no `.qm` file, so it falls back
gracefully to English strings.

---

## Extending the example

- **Add a new language:** copy `translations/app_de.ts`, rename it
  `app_fr.ts`, translate the strings, compile with `lrelease`, and add an
  entry to `LanguageManager._available_languages`.
- **Add a new colour token:** add a `readonly property color` line in
  `Theme.qml` — every QML file that imports the module gets the new token
  automatically.
- **Add a high-contrast theme:** extend `Theme.current` to accept a third
  value (`"high-contrast"`) and add a third branch to each ternary.
