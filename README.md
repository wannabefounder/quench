# Quench 💧

A free, open-source macOS menu-bar app that races your daily water intake against the water your AI usage "drinks" in data centers. Privacy-first: local by default, with explicit provider connections.

**Status: M4 complete; M5 in progress.** The menu-bar race and local water log are backed by an
EcoLogits-faithful estimation engine with open coefficients. Private Claude Code and Codex log
ingestion includes durable cursors, deduplication, rotation handling, and visible source health.
First-run onboarding, per-source privacy controls, diagnostics, and persistent scope/region settings
make every estimate's assumptions and collection state visible.

Optional OpenAI and Anthropic organization connectors now have Keychain-only Admin credential
storage, documented metadata-only verification, pagination-aware clients, and tested response
normalization. Connected providers sync automatically at most every 15 minutes; manual diagnostics
refresh can force a sync, and changing provider buckets are updated without double-counting.
OpenRouter can be added with a Keychain-only key and exact generation receipts can be imported by
ID. Its documented API does not provide bulk account history, and Quench never calls OpenRouter's
separate stored-content endpoint. Settings independently control which retained sources count in
the race, making API/local overlap visible and reversible without deleting history.

M6 has started with a development-preview Chromium companion in [`BrowserExtension`](BrowserExtension).
It estimates tokens inside ChatGPT/Claude tabs and passes only validated count receipts through a
local native-messaging bridge. It has no telemetry or network backend, and bridge-side canonical
rewriting prevents unexpected page fields from reaching disk. ChatGPT and Claude adapters have
versioned CI fixtures, and new receipts are ingested while Quench is running without polling or a
manual refresh. Safari is intentionally out of scope.

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
