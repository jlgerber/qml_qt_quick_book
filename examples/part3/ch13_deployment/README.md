# Chapter 13 – Deployment

Configuration templates and a worked example showing how to package a
PySide6 Qt Quick application into a standalone native executable using
`pyside6-deploy` and Nuitka.

## What it demonstrates

| Concept | Where |
|---|---|
| `pyproject.toml` for a PySide6 app | `pyproject.toml` |
| `[tool.pyside6-project]` + Nuitka `extra-args` | `pyproject.toml` |
| INI-format `pysidedeploy.spec` | `pysidedeploy.spec` |
| `[app]`, `[python]`, `[qt]`, `[nuitka]` spec sections | `pysidedeploy.spec` |
| Selecting Qt plugins for minimal bundle size | `pysidedeploy.spec` – `qt_plugins` |
| Minimal bootstrap app (same pattern as ch09) | `main.py` |
| Inline documentation of the deploy pipeline | `main.py` docstring |

## Project layout

```
ch13_deployment/
├── main.py              # Entry point + inline deploy docs
├── pyproject.toml       # PEP 621 metadata + pyside6-project config
└── pysidedeploy.spec    # pyside6-deploy INI configuration
```

## How to run (development)

```bash
cd examples/part3/ch13_deployment
python main.py
```

## How to deploy (production)

```bash
# Install deploy tooling
pip install PySide6 nuitka

# Auto-deploy (reads pysidedeploy.spec / pyproject.toml)
pyside6-deploy

# The standalone binary is written to the deployment/ directory.
```

Alternatively, invoke Nuitka directly for full control:

```bash
python -m nuitka \
    --standalone \
    --follow-imports \
    --enable-plugin=pyside6 \
    --include-data-dir=qml=qml \
    main.py
```

## Requirements

- Python 3.10+
- PySide6 ≥ 6.5  (`pip install PySide6`)
- Nuitka ≥ 2.0  (`pip install nuitka`)  – only needed for deployment
- A C compiler reachable on `PATH` (GCC on Linux, Clang on macOS,
  MSVC/MinGW on Windows) – required by Nuitka
