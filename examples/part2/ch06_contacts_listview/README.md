# Chapter 6 — Contacts ListView

## What it demonstrates

- `ListView` with **section headers** — `section.property`, `section.criteria`,
  and a custom `section.delegate` that floats above items to create a sticky
  alphabet-letter header effect.
- **Live search / filter** using a JavaScript `filter()` call that replaces the
  `model` binding with a filtered JavaScript array.
- `ScrollBar.vertical` overlay on a `ListView`.
- `ContactDelegate.qml` as a standalone reusable delegate file using
  `required property` fields — no implicit model role access.
- Avatar placeholder circles (colored `Rectangle` with initials `Text`).

## File layout

```
ch06_contacts_listview/
├── Main.qml              # ApplicationWindow, ListModel, ListView, search bar
└── ContactDelegate.qml   # Reusable delegate: avatar + name/email column
```

## How to run

```bash
cd examples/part2/ch06_contacts_listview
qml Main.qml
```

Type in the search box to filter contacts in real time.
