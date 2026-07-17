# Quench 💧

A free, open-source macOS menu-bar app that races your daily water intake against the water your AI usage "drinks" in data centers. 100% private — everything stays on your device.

**Status: M2 complete; M3 in progress.** The menu-bar race and local water log are backed by an
EcoLogits-faithful estimation engine with open coefficients and 20 calculation tests. The current
milestone adds private, exact local-log ingestion for Claude Code and Codex.

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

Privacy: no telemetry or conversation content. Network features may refresh public scientific data
or improve estimates, with minimal disclosed metadata and a safe local fallback. Read the
[methodology](METHODOLOGY.md), [privacy principles](PRIVACY.md), [project guide](AGENTS.md), and
[contribution guide](CONTRIBUTING.md).

## Why Quench

Quench does not claim that a water estimate is a measurement. It combines token energy estimates,
provider cooling efficiency, and regional electricity water intensity, then shows three clearly
labeled scopes. The coefficients are versioned so the community can audit and improve them.

## License

Quench is available under the [MIT License](LICENSE).
