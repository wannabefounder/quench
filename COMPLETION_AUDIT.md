# Quench research-report completion audit

Audited July 18, 2026 against `Thirsty-AI-Project-Research-Report.docx`, all ten rendered report
pages, the current repository, the packaged app in `/Applications/Quench.app`, and the product
owner's recorded deviations. “Complete” means current evidence directly covers the requirement;
it does not mean a future public release or partnership exists.

## Product and science

| Report requirement | Status | Authoritative evidence |
|---|---|---|
| Daily “You vs. Your AI” race | Complete | `MenuContentView.swift`, `RaceBarView.swift`, packaged UI verification |
| One-click and keyboard water logging | Complete | `Database.swift`, `MenuContentView.swift`; editable sip/cup/glass/bottle-sip actions replace a fixed serving assumption |
| Local midnight winner, streak, one freeze | Complete | `RaceEngine.swift`, `RaceEngineTests.swift`, History UI |
| Weekly Thirst Index | Complete | `HistoryInsights.swift`, tests, History UI |
| Three clearly labeled water scopes and visible range | Complete | `WaterMath.swift`, `coefficients.json`, dashboard/history/floating accessibility/Wrapped UI, 22 water-math tests |
| Region-sensitive EcoLogits-style method | Complete, report formula superseded | Full method and rationale in `METHODOLOGY.md` and `AGENTS.md` |
| Versioned open coefficients | Complete | Bundled `coefficients.json`; runtime uses reviewed offline copy |
| Privacy-safe model freshness | Complete | Optional pinned EcoLogits catalog-only refresh; owner-only cache, schema/size/timeout validation, bundled coefficients win |
| Vendor transparency scorecard | Complete | Versioned four-check first-party evidence dataset, in-app source links, public `TRANSPARENCY.md`, deterministic validation tests |
| Plain daily hydration numbers and goal | Complete | Always-visible `You current / goal`, AI total, editable 1–5 L goal |
| Restrained, research-informed nudges | Complete | `HydrationPacing.swift`, `HydrationNudgePolicy.swift`, tests; maximum two notifications/day |
| Weekly/monthly/yearly Wrapped | Complete | `WrappedInsights.swift`, square/Story local PNG export, tests |
| Relatable cups/bottles/showers | Complete | `WrappedInsights.relatableComparison`, deterministic tests |
| Per-liter clean-water pledge | Complete with safe deviation | Private calculator and independent links; no payment or partnership claim |
| Four animated character themes | Complete | `QuenchTheme.swift`, `BuddyView.swift`, theme gallery, Reduce Motion handling |
| Always-visible status | Complete with platform adaptation | Native drop icon plus adaptive 340×124–640×360 floating hydration instrument; timer-driven status icon was removed after a reproduced macOS 26 launch hang |

## Collection architecture

| Tier | Status | Evidence and boundaries |
|---|---|---|
| 1 — provider endpoints | Complete where official endpoints exist | OpenAI and Anthropic organization Admin APIs; OpenRouter generation-by-ID metadata; Keychain credentials, pagination and normalization tests |
| Gemini quota API named by report | Correctly not invented | No verified official consumer history endpoint; Gemini CLI exact local token summaries are supported instead |
| 2 — browser companion | Complete for Chromium | Packaged MV3 ChatGPT/Claude companion, Settings-guided Chrome/Brave/Edge connection, native bridge, count-only canonical receipts, fixtures and live event watcher |
| Safari companion | Superseded by owner | Explicitly removed from scope July 18, 2026 |
| 3 — local logs | Complete | Claude Code, Codex, Gemini CLI; cursors, rotation/truncation recovery, DB uniqueness and parser tests |
| 4 — activity proxy | Complete, opt-in | NSWorkspace foreground activation only, rough label, no Accessibility/window/content access |
| Network interception | Intentionally prohibited | Privacy contract disallows trusted-certificate/MITM collection |

## Privacy, quality, and distribution

| Requirement | Status | Evidence |
|---|---|---|
| No accounts, Quench telemetry, or conversation storage | Complete | `PRIVACY.md`, parser/bridge allowlists, local SQLite schema |
| Per-source controls and visible accuracy | Complete | Onboarding, Estimation, Providers, Diagnostics, race-inclusion toggles |
| Source isolation and deduplication | Complete | `LocalLogIngestor`, provider sync, stable external IDs and database constraints |
| Native packaged macOS app | Complete | `scripts/package-app.sh`, `scripts/verify-release-readiness.sh`; bundle, privacy surface, signature, archive and checksum gates |
| Launch at login | Implemented; final restart check external | `SMAppService.mainApp`, packaged-only availability |
| CI | Complete and authoritative | [Run 29647079683](https://github.com/wannabefounder/quench/actions/runs/29647079683): 85 Swift tests, browser fixtures, package/archive validation, and release-readiness gate passed |
| Developer ID notarization | Automation complete; credentials external | `release.yml`, `RELEASING.md`; cannot run without owner Apple membership/secrets |
| Homebrew | Template complete; publication external | `Packaging/quench.rb.template`; permanent URL/SHA require first notarized release |
| Open-source community basics | Complete | MIT, contribution guide, code of conduct, security policy, governance, issue templates |

## Owner decisions and conditional roadmap

- English-only replaces the report's Hindi/Telugu suggestion.
- Safari is out of scope; Chromium is the supported browser companion.
- A public leaderboard is not part of the local-first release. It would require a server, abuse
  controls, consent, retention rules, and aggregation thresholds, so it cannot be added by silently
  expanding the privacy boundary.
- Pro, B2B team dashboards, and Windows/Linux are explicitly conditional in the report (“optional”
  and “if demand appears”), not unfinished requirements of the macOS open-source release.
- Remotely downloaded DOM selectors are rejected for the current release. Browser support updates
  ship as reviewed extension releases rather than silently changing page-reading behavior.
- EcoLogits runtime estimation remains local by default. A future live API mode must be separately
  opt-in because provider, model, token count, and region would be disclosed to that service.

## External gates that code cannot complete

1. Revoke the exposed GitHub token.
2. Transfer the repository to an organization and appoint a second administrator if pursuing Open
   Source Collective; review and accept the current fiscal-sponsorship agreement.
3. Enroll in the Apple Developer Program and add release secrets.
4. Run the tag workflow, notarize/staple, verify checksum on a clean Mac, and publish the first release.
5. Verify Reduce Motion using the Mac-wide accessibility setting and test an actual login restart.
6. Apply to a current grant only after an official live call and eligibility terms are verified.
7. Conduct Product Hunt, Show HN, press, or charity outreach as human representational actions.

Until those owner/external actions occur, Quench is engineering-ready but not truthfully a publicly
notarized, fiscally sponsored, or charity-partnered product.

## Packaged runtime verification

The debug-signed `/Applications/Quench.app` was rebuilt and restarted after the final UI changes.
The following checks passed through the real accessibility interface:

- main dashboard appears and remains responsive;
- the native menu entry is present; its packaged SwiftUI label is configured with `drop.fill`;
- closing the dashboard leaves the animated pixel water drop status visible;
- the compact and expanded hydration-instrument layouts render cleanly with `You / goal`, AI
  estimate/range, race state, and four calibrated quick-add actions exposed accessibly;
- clicking the pixel water drop recreates the dashboard after the original SwiftUI window was destroyed;
- Aqua Lab, Forest Flow, Cosmic Sip, and Solar Splash each select their named buddy;
- Settings opens, closes, and opens again on the newest build.

The local Command Line Tools installation cannot import XCTest, so the macOS GitHub runner is the
test authority. Local compilation, browser fixtures, bundle signing validation, plist validation,
and the runtime checks above passed independently.
