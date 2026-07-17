# NOTES (agent scratchpad, ≤40 lines)

Current milestone: M3 DONE — Claude Code + Codex JSONL ingestion has durable cursors, truncation
generations, DB dedupe, parser tests, visible source health, and the real bundled coefficients.
M4 DONE: onboarding, persistent scope/region, accuracy context, source toggles, and diagnostics.
M5 DONE: OpenAI + Anthropic Admin usage auto-syncs with Keychain credentials, bounded
pagination, 15-minute throttle, stable bucket upserts, isolated failures, and diagnostics status.
OpenRouter generation metadata imports are supported by ID (no bulk history/content calls); all
local/API sources have independent race-inclusion controls.
M6 DONE: Chromium MV3 + strict native bridge + event-driven browser receipt ingestion;
count-only messages, canonical rewrite, owner-only inbox. Safari is out of scope by user decision.
M7: history/freeze/Thirst Index/nudges plus local weekly-monthly-yearly Wrapped sharing shipped.

## Files
- QuenchApp/Resources/coefficients.json — bundled EcoLogits-style data: per-model energy, param fallback,
  per-provider WUE/PUE, per-region grid water, 3 modes. Calibrated to arXiv:2505.09598.
- METHODOLOGY.md — water-math write-up (sources cited). CLAUDE.md — records Section 6 override.
- QuenchApp/Engine/WaterMath.swift — PURE: UsageSample, WaterMode, Coefficients(Decodable),
  energyWh, waterMl, waterRange, totalWaterMl, model/provider mapping, EcoLogits param formula.
- QuenchApp/Engine/RaceEngine.swift — race state + aiWaterMl() wrapper.
- QuenchApp/Models/Database.swift — added todayUsageSamples() (usage_events -> [UsageSample]).
- QuenchApp/QuenchApp.swift — RaceStore loads coefficients + computes aiMl via WaterMath.
- QuenchTests/WaterMathTests.swift — 20 tests vs real JSON. RaceEngineTests.swift — 6 tests.
- UsageLogParser.swift + UsageLogParserTests.swift — metadata-only Claude/Codex parsers.
- LocalLogIngestor.swift + DB v2 — byte cursors, rotation generations, unique external IDs.
- Menu source rows — privacy-safe Tracking/Watching/Not found/Needs attention states.
- SourceHealth.swift + tests — pure state rules including Disabled; no paths cross into UI.
- OnboardingView + Settings diagnostics — counts, last activity, methodology version, refresh.
- ProviderUsage.swift + tests — Tier 1 response normalization and pagination cursors.
- Services/ — Keychain credentials, bounded OpenAI/Anthropic sync, OpenRouter receipt imports.
- ProviderSyncService + DB v3 — scheduled/forced import, upsert, throttling, sanitized health.
- BrowserExtension + QuenchBrowserBridge — Tier 2 count-only native messaging preview.

## TODO / open
- Bundled coefficients resource is wired into the Swift package; fallback remains for corrupt installs.
- M1 manual check on Mac still pending (launch/icon/log/restart).
- M2 Mac check: debug pane showing computed mL for a sample event (engine verified on Linux).
- This Mac's default CLT SDK alias (26.2) mismatches its Swift compiler build. App builds with the
  installed MacOSX15.4 SDK; README documents cache cleanup and the temporary SDKROOT workaround.
- gpt-4o-mini output coef set below gpt-4o by size-prior (benchmark's mini figure looked anomalous).
