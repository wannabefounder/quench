# NOTES (agent scratchpad, ≤40 lines)

Current milestone: M1 DONE (Linux-verifiable parts green; needs one human check on a Mac).
Next: M2 — coefficients.json + WaterMath + RaceEngine expansion + ≥12 unit tests.

Build env: sandbox is Linux/aarch64. Swift 5.10.1 toolchain at
/sessions/inspiring-peaceful-bell/toolchain/swift-5.10.1-RELEASE-ubuntu22.04-aarch64/usr/bin
Build cmd: swift build --scratch-path /sessions/inspiring-peaceful-bell/build (mnt fs can't host .build)
Package.swift conditionally includes GRDB + QuenchApp target only when evaluated on macOS,
so Linux builds/tests QuenchEngine only. Full app build happens on the user's Mac.

## Files
- Package.swift — conditional manifest (engine everywhere, app+GRDB on macOS)
- QuenchApp/QuenchApp.swift — @main MenuBarExtra + RaceStore (60s rollover timer)
- QuenchApp/Engine/RaceEngine.swift — pure: dayKey, race state (10% tie band), bar fractions
- QuenchApp/Models/Records.swift — WaterEntry/UsageEvent/DailySummary GRDB records
- QuenchApp/Models/Database.swift — DB at ~/Library/Application Support/Quench/, v1 migration, logWater, todayUserMl
- QuenchApp/UI/Strings.swift — all user-visible strings
- QuenchApp/UI/RaceBarView.swift — blue fill + orange AI marker
- QuenchApp/UI/MenuContentView.swift — totals, bar, +250 ml button, quit
- QuenchTests/RaceEngineTests.swift — 6 tests (day key, rollover, DST, states, fractions)

## TODO
- M1 manual check on Mac: launch, icon, log updates bar, survives restart (user to confirm)
- M1 AI side hardcoded at 800 ml — replaced in M2
