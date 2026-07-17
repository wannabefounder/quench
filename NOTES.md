# NOTES (agent scratchpad, ≤40 lines)

Current milestone: M2 DONE (engine + tests green on Linux). Next: M3 — Tier 3 log parsing
(Claude Code + Codex JSONL watchers, dedupe, byte offsets).

Build env: sandbox is Linux/aarch64, Swift 5.10.1. Toolchain must be re-downloaded per session:
  https://download.swift.org/swift-5.10.1-release/ubuntu2204-aarch64/swift-5.10.1-RELEASE/swift-5.10.1-RELEASE-ubuntu22.04-aarch64.tar.gz
The mnt fs blocks build writes, so: copy repo to /sessions/<id>/qbuild, run swift build / swift test there.
Package.swift builds QuenchEngine (pure) everywhere; app+GRDB only on macOS. Full app build = user's Mac.

## Files
- coefficients.json — FULL EcoLogits-style data: per-model energy (facility Wh), param fallback,
  per-provider WUE/PUE, per-region grid water, 3 modes. Calibrated to arXiv:2505.09598.
- METHODOLOGY.md — water-math write-up (sources cited). CLAUDE.md — records Section 6 override.
- QuenchApp/Engine/WaterMath.swift — PURE: UsageSample, WaterMode, Coefficients(Decodable),
  energyWh, waterMl, waterRange, totalWaterMl, model/provider mapping, EcoLogits param formula.
- QuenchApp/Engine/RaceEngine.swift — race state + aiWaterMl() wrapper.
- QuenchApp/Models/Database.swift — added todayUsageSamples() (usage_events -> [UsageSample]).
- QuenchApp/QuenchApp.swift — RaceStore loads coefficients + computes aiMl via WaterMath.
- QuenchTests/WaterMathTests.swift — 20 tests vs real JSON. RaceEngineTests.swift — 6 tests.

## TODO / open
- coefficients.json must be added as a bundle resource in the Xcode app target (fallback exists if missing).
- M1 manual check on Mac still pending (launch/icon/log/restart).
- M2 Mac check: debug pane showing computed mL for a sample event (engine verified on Linux).
- gpt-4o-mini output coef set below gpt-4o by size-prior (benchmark's mini figure looked anomalous).
