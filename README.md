# Quench 💧

A free, open-source macOS menu-bar app that races your daily water intake against the water your AI usage "drinks" in data centers. 100% private — everything stays on your device.

**Status: M3 complete; M4 next.** The menu-bar race and local water log are backed by an
EcoLogits-faithful estimation engine with open coefficients. Private Claude Code and Codex log
ingestion now includes durable cursors, deduplication, rotation handling, and visible source health.

## Build & run (macOS 14+)

```sh
swift build          # or open Package.swift in Xcode and run the QuenchApp scheme
swift run QuenchApp
```

Run the engine tests (these also run on Linux):

```sh
swift test
```

### Build troubleshooting

If the repository was moved or copied and Swift reports that a precompiled header uses an old
`ModuleCache` path, discard only the generated package artifacts and rebuild:

```sh
swift package clean
swift run QuenchApp
```

If the next error says the macOS SDK is not supported by the installed Swift compiler or that
`SwiftShims` is missing, the active Apple Command Line Tools and SDK revisions do not match. Update
Command Line Tools/Xcode for the durable fix. As a temporary workaround, select a compatible SDK
already installed on the Mac. For example, on a machine that has `MacOSX15.4.sdk`:

```sh
SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk swift run QuenchApp
```

The SDK override is a local development workaround, not a Quench runtime requirement.

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
