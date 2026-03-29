# Chapter 8 — Animated Expandable Cards

## What it demonstrates

- **Qt Quick States** (`collapsed` / `expanded`) with `PropertyChanges` for
  `height`, `opacity`, and `rotation`.
- **Transitions** with:
  - `NumberAnimation` on `height` — smooth card expansion using
    `Easing.OutCubic`.
  - `NumberAnimation` on `opacity` — body text fades in after the card opens,
    and fades out before it closes.
  - `RotationAnimation` — the chevron `⌄` icon rotates 180° on expand and
    reverses on collapse, each with the correct `direction` to avoid
    back-spinning.
- **`Behavior on color`** (`ColorAnimation`) on the card background so the
  tint change is always smooth regardless of what triggers it.
- An inline `component ExpandableCard` definition that makes the pattern
  self-contained and easy to reuse three times in the same file.

## How to run

```bash
cd examples/part2/ch08_animated_card
qml Main.qml
```

Click any card to toggle between collapsed (72 px) and expanded (220 px).
All three cards are independent — you can have multiple open at once.
