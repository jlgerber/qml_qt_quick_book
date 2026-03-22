# Developing Qt Quick / QML Applications with Python and C++

A practitioner's guide for experienced developers, covering QML fundamentals,
Qt Quick controls and layouts, and deep integration with both Python (PySide6)
and C++.

---

## Prerequisites

This book is built with [mdBook](https://github.com/rust-lang/mdBook). Install
it via Cargo (the Rust package manager):

```bash
cargo install mdbook
```

Or download a pre-built binary from the
[mdBook releases page](https://github.com/rust-lang/mdBook/releases).

Verify the installation:

```bash
mdbook --version
```

---

## Serving Locally

The fastest way to read and edit the book is the built-in development server.
It watches source files for changes and automatically rebuilds and live-reloads
the browser:

```bash
mdbook serve
```

Then open [http://localhost:3000](http://localhost:3000) in your browser.

**Options:**

```bash
# Open the browser automatically
mdbook serve --open

# Bind to a different address or port
mdbook serve --hostname 0.0.0.0 --port 8080

# Use native filesystem watching (faster on Linux/macOS; default is poll)
mdbook serve --watcher native
```

---

## Building

To produce a static HTML build without starting a server:

```bash
mdbook build
```

Output is written to `book/`. Open `book/index.html` in any browser to read
offline.

```bash
# Build and open the result immediately
mdbook build --open

# Write output to a custom directory
mdbook build --dest-dir /tmp/qt-book-output
```

### Watch Mode (Build Without Serving)

Rebuild on every file change without starting a web server — useful when you
have your own static file server:

```bash
mdbook watch
mdbook watch --open            # open browser on first build
mdbook watch --watcher native  # native FS events instead of polling
```

### Cleaning the Build Output

```bash
mdbook clean
```

This removes the `book/` directory (or whichever `build-dir` is configured in
`book.toml`).

---

## Alternative Output Formats

mdBook supports additional backends installed as separate tools. Each backend
is enabled by adding an `[output.<name>]` section to `book.toml` alongside the
existing `[output.html]` block.

### PDF

The recommended approach is **mdbook-pdf**, which uses a headless Chromium
instance to print the HTML output to PDF:

```bash
cargo install mdbook-pdf
```

Add to `book.toml`:

```toml
[output.pdf]
```

Then build normally:

```bash
mdbook build
```

The PDF is written to `book/output.pdf`.

> **Note:** mdbook-pdf requires a Chromium or Chrome binary on `PATH`.
> On headless systems, install `chromium-browser` or `google-chrome-stable`
> first. Set a custom path with the `chrome-args` option if needed:
>
> ```toml
> [output.pdf]
> chrome-args = ["--no-sandbox"]
> ```

---

### EPUB

**mdbook-epub** generates a standards-compliant EPUB 3 file:

```bash
cargo install mdbook-epub
```

Add to `book.toml`:

```toml
[output.epub]
```

Build:

```bash
mdbook build
```

The file is written to `book/epub/<title>.epub`. Open it with any EPUB reader
(Calibre, Apple Books, Kobo, etc.).

**Optional EPUB settings:**

```toml
[output.epub]
cover-image = "assets/cover.png"   # path relative to src/
additional-css = ["assets/epub.css"]
```

---

### Markdown (Preprocessed Output)

**mdbook-markdown** emits all chapters as a single concatenated Markdown file
with preprocessors applied (variables expanded, includes resolved). Useful as
input to Pandoc or other toolchains:

```bash
cargo install mdbook-markdown
```

Add to `book.toml`:

```toml
[output.markdown]
```

Output is written to `book/markdown/`.

---

### Pandoc (Any Format via Pandoc)

For formats not covered by a dedicated mdBook backend — DOCX, LaTeX, ODT, man
pages — use **mdbook-pandoc**, which pipes the preprocessed book through
[Pandoc](https://pandoc.org/):

```bash
cargo install mdbook-pandoc
# Also requires pandoc itself: https://pandoc.org/installing.html
```

Add one or more output profiles to `book.toml`:

```toml
[output.pandoc.profile.docx]
output-file = "qt-quick-book.docx"

[output.pandoc.profile.latex]
output-file = "qt-quick-book.tex"

[output.pandoc.profile.pdf-latex]
output-file = "qt-quick-book-latex.pdf"
to = "pdf"
pdf-engine = "xelatex"
```

Build:

```bash
mdbook build
```

Each profile produces its file inside `book/pandoc/`.

---

## Building Multiple Formats at Once

When multiple `[output.*]` sections are present in `book.toml`, a single
`mdbook build` runs all of them:

```toml
[output.html]
default-theme = "navy"
preferred-dark-theme = "navy"

[output.pdf]

[output.epub]
```

```bash
mdbook build
# Produces:
#   book/index.html       (HTML site)
#   book/output.pdf       (PDF)
#   book/epub/<title>.epub (EPUB)
```

> **Tip:** `mdbook serve` only runs the HTML backend. Run `mdbook build` when
> you need the non-HTML outputs.

---

## Repository Layout

```text
.
├── book.toml          # mdBook configuration
├── README.md          # this file
└── src/
    ├── SUMMARY.md     # table of contents — drives sidebar navigation
    ├── introduction.md
    ├── part1/
    │   ├── ch01_qml_ecosystem.md
    │   ├── ch02_qml_language.md
    │   └── ch03_qtquick_primitives.md
    ├── part2/
    │   ├── ch04_controls.md
    │   ├── ch05_layouts.md
    │   ├── ch06_models_views.md
    │   ├── ch07_navigation.md
    │   └── ch08_animation.md
    ├── part3/
    │   ├── ch09_pyside6_architecture.md
    │   ├── ch10_python_to_qml.md
    │   ├── ch11_python_models.md
    │   ├── ch12_python_backend.md
    │   └── ch13_packaging.md
    ├── part4/
    │   ├── ch14_cpp_project.md
    │   ├── ch15_cpp_to_qml.md
    │   ├── ch16_cpp_models.md
    │   ├── ch17_scene_graph.md
    │   └── ch18_interop_performance.md
    └── part5/
        ├── ch19_i18n_a11y.md
        ├── ch20_testing.md
        └── ch21_architecture.md
```

The `book/` output directory is generated on build and should not be committed
to version control. Add it to `.gitignore`:

```gitignore
book/
```
