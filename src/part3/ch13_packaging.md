# Chapter 13: Packaging and Deployment

## `pyside6-deploy`: Nuitka-Based Packaging and Platform Targets

Distributing a PySide6 application to end users who do not have Python or PySide6 installed requires packaging the interpreter, the PySide6 libraries, Qt libraries, and all application code into a self-contained bundle. `pyside6-deploy` automates this using Nuitka — a Python-to-C++ transpiler that compiles Python code and bundles all dependencies.

### How `pyside6-deploy` Works

`pyside6-deploy` orchestrates the following pipeline:

1. **Dependency analysis**: Scans the application entry point for imports and builds a dependency graph.
2. **Nuitka compilation**: Transpiles Python source to C++, compiles it, and links it with the Python runtime.
3. **Qt dependency collection**: Identifies which Qt modules and plugins are used and copies only those (not the full Qt installation).
4. **QML cache compilation**: Pre-compiles QML files to bytecode (`.qmlc`) for faster startup.
5. **Resource embedding**: Bundles images, fonts, and QML files into the executable or alongside it.
6. **Platform bundle creation**: Produces a platform-appropriate output (see below).

### Basic Usage

```bash
# Install pyside6-deploy (included with PySide6)
pyside6-deploy main.py

# With explicit configuration
pyside6-deploy --config pysidedeploy.spec main.py
```

The output is a `deployment/` directory containing the standalone executable and any required shared libraries.

### Configuration File

`pyside6-deploy` generates a `pysidedeploy.spec` (INI format) on first run:

```ini
[app]
title = MyApplication
project_dir = .
input_file = main.py
project_file =
exec_directory = deployment

[python]
python_path = /usr/bin/python3
packages = PySide6,numpy,sqlalchemy

[qt]
qml_files = qml/Main.qml,qml/components
qt_plugins = imageformats,iconengines,platforms

[nuitka]
extra_args = --follow-import-to=backend --include-package=backend
```

Key options:

| Option | Purpose |
|---|---|
| `packages` | Python packages to include (analyzed recursively) |
| `qml_files` | QML files to embed as resources |
| `qt_plugins` | Qt plugins to include (image formats, platforms, SQL drivers) |
| `extra_args` | Additional Nuitka arguments |

### Platform Targets

**Linux**: Produces a directory with an ELF executable and `.so` libraries. For distribution, wrap in an AppImage (see below).

**Windows**: Produces a directory with a `.exe` and DLLs. For distribution, wrap with NSIS or WiX installer, or use Windows Package Manager (winget).

**macOS**: Produces a `.app` bundle. For distribution, sign and notarize, then wrap in a `.dmg`.

**Android** (experimental): Cross-compilation via Qt for Android. `pyside6-deploy` generates a Gradle project.

**WebAssembly** (experimental): Targets the browser via Qt for WebAssembly. Produces `.wasm` + `.html` + `.js`.

---

## Resource Bundling with `pyside6-rcc`

Qt's resource system compiles arbitrary files (QML, images, fonts, config files) into a binary format that can be embedded directly into the application executable or loaded from a compiled `.rcc` file.

### The Resource Collection File

Define resources in a `.qrc` XML file:

```xml
<!-- resources.qrc -->
<RCC>
    <qresource prefix="/qml">
        <file>qml/Main.qml</file>
        <file>qml/components/SearchBar.qml</file>
        <file>qml/screens/HomeScreen.qml</file>
    </qresource>
    <qresource prefix="/images">
        <file alias="logo.png">resources/images/logo.png</file>
        <file alias="logo@2x.png">resources/images/logo@2x.png</file>
    </qresource>
    <qresource prefix="/fonts">
        <file>resources/fonts/Inter-Regular.ttf</file>
        <file>resources/fonts/Inter-Bold.ttf</file>
    </qresource>
</RCC>
```

### Compiling Resources

```bash
pyside6-rcc resources.qrc -o resources_rc.py
```

The output is a Python module containing a function that registers the resources with Qt's virtual filesystem.

### Using Resources

```python
# main.py — import the compiled resources module before loading QML
import resources_rc  # noqa: F401

engine = QQmlApplicationEngine()
# Now load QML from the virtual filesystem
engine.load("qrc:/qml/Main.qml")
```

In QML, resource paths use the `qrc:` scheme:

```qml
Image { source: "qrc:/images/logo.png" }
Text { font.family: "Inter" }  // After registering the font
```

### Font Registration

Fonts embedded in resources need explicit registration with Qt's font database:

```python
from PySide6.QtGui import QFontDatabase

QFontDatabase.addApplicationFont(":/fonts/Inter-Regular.ttf")
QFontDatabase.addApplicationFont(":/fonts/Inter-Bold.ttf")
```

After registration, use the font by family name in QML as normal.

### Automatic Resource Embedding in `pyside6-deploy`

When using `pyside6-deploy`, specify QML files in the `qml_files` configuration option. The tool automatically compiles them into resources and removes the separate file dependencies from the output package.

---

## Cross-Platform Distribution

### Linux: AppImage

AppImage packages the application into a single self-contained file that runs on any Linux distribution without installation:

```bash
# Install appimagetool
wget https://github.com/AppImage/AppImageKit/releases/latest/download/appimagetool-x86_64.AppImage
chmod +x appimagetool-x86_64.AppImage

# Create AppDir structure
mkdir -p MyApp.AppDir/usr/bin
mkdir -p MyApp.AppDir/usr/lib

# Copy pyside6-deploy output
cp -r deployment/* MyApp.AppDir/usr/bin/

# Create AppRun script
cat > MyApp.AppDir/AppRun << 'EOF'
#!/bin/bash
HERE=$(dirname $(readlink -f "$0"))
exec "$HERE/usr/bin/MyApp" "$@"
EOF
chmod +x MyApp.AppDir/AppRun

# Create .desktop file
cat > MyApp.AppDir/MyApp.desktop << 'EOF'
[Desktop Entry]
Name=MyApp
Exec=MyApp
Icon=myapp
Type=Application
Categories=Utility;
EOF

# Copy icon
cp resources/images/logo.png MyApp.AppDir/myapp.png

# Build AppImage
./appimagetool-x86_64.AppImage MyApp.AppDir MyApp-1.0-x86_64.AppImage
```

### macOS: `.app` Bundle and Notarization

`pyside6-deploy` produces a `.app` bundle on macOS. For distribution outside the Mac App Store:

1. **Code signing** (required for notarization):

```bash
codesign --deep --force --verify --verbose \
    --sign "Developer ID Application: Your Name (TEAMID)" \
    --options runtime \
    MyApp.app
```

2. **Notarization**:

```bash
# Create a ZIP of the .app for upload
ditto -c -k --keepParent MyApp.app MyApp.zip

# Submit for notarization
xcrun notarytool submit MyApp.zip \
    --apple-id "your@email.com" \
    --password "@keychain:APP_PASSWORD" \
    --team-id "TEAMID" \
    --wait

# Staple the notarization ticket
xcrun stapler staple MyApp.app
```

3. **DMG creation**:

```bash
# create-dmg is a popular tool for styled DMG creation
create-dmg \
    --volname "MyApp Installer" \
    --background "resources/dmg_background.png" \
    --window-size 600 400 \
    --app-drop-link 450 185 \
    "MyApp-1.0.dmg" \
    "MyApp.app"
```

### Windows: Installer with NSIS

NSIS (Nullsoft Scriptable Install System) creates traditional Windows installers:

```nsis
; MyApp.nsi
!include "MUI2.nsh"

Name "MyApp"
OutFile "MyApp-1.0-Setup.exe"
InstallDir "$PROGRAMFILES64\MyApp"
RequestExecutionLevel admin

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

Section "Main"
    SetOutPath "$INSTDIR"
    File /r "deployment\*.*"
    CreateShortCut "$DESKTOP\MyApp.lnk" "$INSTDIR\MyApp.exe"
    WriteUninstaller "$INSTDIR\Uninstall.exe"
SectionEnd

Section "Uninstall"
    RMDir /r "$INSTDIR"
    Delete "$DESKTOP\MyApp.lnk"
SectionEnd
```

```bash
makensis MyApp.nsi
```

Alternatively, use WiX Toolset for MSI packages (better for enterprise deployment with Group Policy support).

### CI/CD Integration

A GitHub Actions workflow that builds for all platforms:

```yaml
# .github/workflows/release.yml
name: Build and Release

on:
  push:
    tags: ['v*']

jobs:
  build:
    strategy:
      matrix:
        include:
          - os: ubuntu-22.04
            target: linux
          - os: macos-14
            target: macos
          - os: windows-2022
            target: windows

    runs-on: ${{ matrix.os }}

    steps:
      - uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.12'

      - name: Install dependencies
        run: pip install PySide6 nuitka

      - name: Build
        run: pyside6-deploy --config pysidedeploy.spec main.py

      - name: Package (Linux)
        if: matrix.target == 'linux'
        run: |
          # Build AppImage
          ./scripts/build_appimage.sh

      - name: Package (macOS)
        if: matrix.target == 'macos'
        env:
          APPLE_ID: ${{ secrets.APPLE_ID }}
          APPLE_PASSWORD: ${{ secrets.APPLE_PASSWORD }}
          TEAM_ID: ${{ secrets.TEAM_ID }}
        run: |
          ./scripts/sign_and_notarize.sh

      - name: Package (Windows)
        if: matrix.target == 'windows'
        run: |
          makensis scripts/installer.nsi

      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: myapp-${{ matrix.target }}
          path: dist/
```

---

## Startup Performance

### QML Ahead-of-Time Compilation

`qmlsc` (the QML static compiler) compiles QML to C++ at build time, significantly reducing startup time and improving runtime performance. For PySide6 projects:

```bash
pyside6-deploy --qml-compile-mode=all main.py
```

This requires:
- All QML types are registered (not just used as `var`)
- `QML_IMPORT_NAME` and version are set correctly
- No `Qt.createQmlObject()` with dynamic strings

### Lazy Module Import

Python imports are synchronous and can be slow for large packages. Defer heavy imports:

```python
# main.py — fast startup: only import essentials
import sys
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine

def main():
    app = QGuiApplication(sys.argv)
    engine = QQmlApplicationEngine()
    engine.load("qrc:/qml/Main.qml")
    # Heavy imports happen in response to user actions:
    # from backend.heavy_module import HeavyThing
    sys.exit(app.exec())
```

---

## Summary

`pyside6-deploy` with Nuitka provides a one-command packaging pipeline that handles Python compilation, Qt dependency collection, and QML pre-compilation. Resource bundling with `pyside6-rcc` embeds all assets into the executable, eliminating loose file dependencies. Platform-specific distribution — AppImage on Linux, signed `.app` bundles on macOS, NSIS installers on Windows — follows standard conventions for each platform. Automating this in CI/CD with GitHub Actions produces reproducible release artifacts for all platforms from a single codebase.
