# Quench 💧

A free, open-source macOS menu-bar app that races your daily water intake against the water your AI usage "drinks" in data centers. 100% private — everything stays on your device.

**Status: M1 (skeleton).** Menu-bar app with a race bar, one-tap water logging to SQLite, and local-midnight day rollover. The AI side of the race is a hardcoded placeholder until M2 (water math engine).

## Build & run (macOS 14+)

```sh
swift build          # or open Package.swift in Xcode and run the QuenchApp scheme
swift run QuenchApp
```

Run the engine tests (these also run on Linux):

```sh
swift test
```

## Layout

- `QuenchApp/Engine/` — pure logic (no SwiftUI, no DB), fully unit-tested
- `QuenchApp/Models/` — GRDB records + SQLite storage
- `QuenchApp/UI/` — MenuBarExtra views
- `QuenchTests/` — engine tests

Privacy: no telemetry, no accounts, no server. See CLAUDE.md for the full spec.
