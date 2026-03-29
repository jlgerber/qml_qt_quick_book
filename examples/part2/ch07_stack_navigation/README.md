# Chapter 7 — StackView Navigation

## What it demonstrates

- **StackView** push/pop with custom slide-in / slide-out `Transition`s using
  `XAnimator` for GPU-accelerated translation.
- A **NavigationController** pattern: an inline `QtObject` that exposes
  `navigateTo(screenName, properties)` and `back()` signals.  Screens emit
  signals through the controller rather than holding a direct reference to the
  `StackView`, keeping them reusable and testable in isolation.
- A `Connections` block in `Main.qml` that translates controller signals into
  `stack.push()` / `stack.pop()` calls.
- `required property` injection: properties are passed into pushed screens via
  the second argument of `stack.push(component, properties)`.
- `HomeScreen.qml` — a 2-column `GridLayout` of tappable app cards.
- `DetailScreen.qml` — a back-nav bar, hero banner, and placeholder content
  list, all driven by `required property` values from the push call.

## File layout

```
ch07_stack_navigation/
├── Main.qml           # ApplicationWindow, StackView, NavigationController
├── HomeScreen.qml     # 4-card grid; tapping pushes DetailScreen
└── DetailScreen.qml   # Detail view; back button calls navCtrl.back()
```

## How to run

```bash
cd examples/part2/ch07_stack_navigation
qml Main.qml
```

Tap a card on the home screen to navigate to the detail screen, then use the
back button (or the `‹ Back` label) to return.
