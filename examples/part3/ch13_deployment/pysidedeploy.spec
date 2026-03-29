; pysidedeploy.spec – Chapter 13: Deployment
; ---------------------------------------------------------------------------
; INI-format configuration file for pyside6-deploy.
; Generate a fresh copy at any time with:
;     pyside6-deploy --init
; Then customise the values below for your project.
; ---------------------------------------------------------------------------

[app]
; Entry-point Python script.
input_file = main.py

; Name of the generated executable (without platform extension).
exec_directory = deployment

; Application name shown in the OS and in the generated binary metadata.
name = DeployApp

; If True, pyside6-deploy calls Nuitka automatically.
; Set to False to only generate the spec and run Nuitka yourself.
; (default: True)
; deploy = True

; ---------------------------------------------------------------------------
[python]
; Path to the Python interpreter used for the build.
; Leave empty to use the interpreter that runs pyside6-deploy.
python_path =

; Packages to exclude from the bundle (reduces binary size).
; Example: "numpy,scipy" if you don't actually use them.
excluded_packages =

; ---------------------------------------------------------------------------
[qt]
; Comma-separated list of Qt modules to include.
; pyside6-deploy auto-detects these; list them explicitly to override.
modules = Core,Gui,Qml,Quick,QuickControls2,QuickLayouts,QuickTemplates2

; Qt Quick Controls style to bundle (Material, Fusion, Basic, …).
; The default style is Basic; ship only what you need.
; qml_import_name is used to locate QML singletons.
qml_files = qml/Main.qml,qml/qmldir

; Extra directories whose .qml files must be included.
; qml_source_dir = qml

; Qt plugins to bundle.  Keeping this list tight cuts ~30 MB on Linux.
;   imageformats – PNG, JPEG, WebP support
;   platforms    – xcb (Linux), windows (Windows), cocoa (macOS)
;   iconengines  – SVG icon support
;   platforminputcontexts – on-screen keyboard integration
qt_plugins = imageformats,platforms,iconengines,platforminputcontexts

; ---------------------------------------------------------------------------
[nuitka]
; Extra Nuitka command-line arguments appended verbatim.
extra_args = --standalone --follow-imports --enable-plugin=pyside6

; Enable Nuitka's LTO (link-time optimisation) for a smaller binary.
; lto = true

; Nuitka job count (0 = auto-detect CPU count).
; jobs = 0

; ---------------------------------------------------------------------------
; Notes
; ---------------------------------------------------------------------------
; After editing this file, run:
;     pyside6-deploy
; from the project root (the directory containing main.py).
;
; Output lands in the deployment/ directory specified above.
;
; To deploy on Windows you also need the Visual C++ Redistributable.
; To deploy on macOS you may want to codesign the .app bundle:
;     codesign --deep --force --sign "-" deployment/DeployApp.app
