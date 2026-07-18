# NOTES (agent scratchpad, ≤40 lines)

Current milestone: M3 DONE — Claude Code + Codex + Gemini CLI ingestion has durable cursors, truncation
generations, DB dedupe, parser tests, visible source health, and the real bundled coefficients.
M4 DONE: onboarding, scope/region, source controls, diagnostics, and opt-in Tier 4 activity fallback.
M5 DONE: OpenAI + Anthropic Admin usage auto-syncs with Keychain credentials, bounded
pagination, 15-minute throttle, stable bucket upserts, isolated failures, and diagnostics status.
OpenRouter generation metadata imports are supported by ID (no bulk history/content calls); all
local/API sources have independent race-inclusion controls.
M6 DONE: Chromium MV3 + strict native bridge + event-driven browser receipt ingestion;
count-only messages, canonical rewrite, owner-only inbox. Safari is out of scope by user decision.
M7: history/freeze/nudges/Wrapped comparisons/private pledge plus four buddy themes shipped.
M8 underway: packaged app, original icon, opt-in SMAppService launch-at-login, and a verified
always-on-top pixel status fallback are implemented.

## Files
- QuenchApp/Resources/coefficients.json — bundled EcoLogits-style data: per-model energy, param fallback,
  per-provider WUE/PUE, per-region grid water, 3 modes. Calibrated to arXiv:2505.09598.
- METHODOLOGY.md — water-math write-up (sources cited). CLAUDE.md — records Section 6 override.
- QuenchApp/Engine/WaterMath.swift — PURE: UsageSample, WaterMode, Coefficients(Decodable),
  energyWh, waterMl, waterRange, totalWaterMl, model/provider mapping, EcoLogits param formula.
- RaceEngine.swift + Database.swift + QuenchApp.swift — race state, stored usage, and live water totals.
- QuenchTests/WaterMathTests.swift — 20 tests vs real JSON. RaceEngineTests.swift — 6 tests.
- UsageLogParser.swift + UsageLogParserTests.swift — metadata-only Claude/Codex/Gemini parsers.
- LocalLogIngestor.swift + DB v2 — byte cursors, rotation generations, unique external IDs.
- Menu source rows — privacy-safe Tracking/Watching/Not found/Needs attention states.
- SourceHealth.swift + tests — pure state rules including Disabled; no paths cross into UI.
- OnboardingView + Settings diagnostics — counts, last activity, methodology version, refresh.
- ProviderUsage.swift + tests — Tier 1 response normalization and pagination cursors.
- Services/ — Keychain credentials, bounded OpenAI/Anthropic sync, OpenRouter receipt imports.
- ProviderSyncService + DB v3 — scheduled/forced import, upsert, throttling, sanitized health.
- BrowserExtension + QuenchBrowserBridge — Tier 2 count-only native messaging preview.

## TODO / open
- Packaged coefficients and fallback are verified; app launch/icon/restart passed on this Mac.
- Settings close/reopen and mini-widget water logging are verified on the packaged app. Manual UI
  checks remain for all-theme Reduce Motion behavior and launch-at-login restart.
- This Mac's default CLT SDK alias (26.2) mismatches its Swift compiler build. App builds with the
  installed MacOSX15.4 SDK; README documents cache cleanup and the temporary SDKROOT workaround.
- gpt-4o-mini output coef set below gpt-4o by size-prior (benchmark's mini figure looked anomalous).
