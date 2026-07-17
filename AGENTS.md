# Quench — contributor and agent guide

Quench is a free, open-source macOS menu-bar app that makes the water footprint of personal AI
usage visible and turns it into a playful hydration race: **you vs. your AI**. The product must be
useful without guilt, scientifically honest without false precision, and private by construction.

The research source of truth is [`Thirsty-AI-Project-Research-Report.docx`](Thirsty-AI-Project-Research-Report.docx).
Read it before making product-level decisions. [`METHODOLOGY.md`](METHODOLOGY.md) is the calculation
contract and [`coefficients.json`](QuenchApp/Resources/coefficients.json) is the auditable data contract.

## Product principles

1. **Privacy by design.** No accounts or telemetry by default, no conversation content, and no
   hidden data transfer. Network features are welcome when they clearly improve the product, use
   minimal metadata, are disclosed, and have a safe local fallback.
2. **Ranges, not false certainty.** Water use is estimated. Show provenance, accuracy tier, scope,
   region, and low/mid/high values wherever users could mistake an estimate for a measurement.
3. **Playful, never punitive.** Encourage hydration and awareness; do not shame AI use.
4. **Open methodology.** Every coefficient and assumption must be versioned, cited, reviewable,
   and replaceable without hiding behavior in UI code.
5. **Quiet by default.** The menu-bar state is the primary signal. Respect Focus modes and cap
   hydration nudges at two per day unless the user explicitly changes that setting.
6. **Accessible and lightweight.** Native SwiftUI, fast launch, low idle overhead, VoiceOver-ready,
   keyboard accessible, and usable without color alone.

## Full product scope

### Core loop

- Live menu-bar droplet and dropdown race bar for daily human intake vs. AI water estimate.
- One-click/keyboard water logging, local-midnight rollover, daily winner, streaks, and freeze tokens.
- Conservative (Scope 1), Standard (Scopes 1+2), and Full footprint modes with region controls.
- Weekly/monthly/yearly "AI Water Wrapped" cards designed for sharing without exposing private data.
- Optional donation pledges and charity links only after the core product is trustworthy.

### Usage collection tiers

- **Tier 1 — API usage:** OpenAI/Anthropic/OpenRouter admin or usage endpoints; exact tokens where
  available. Credentials belong in Keychain, never SQLite, logs, fixtures, or source control.
- **Tier 2 — browser extension:** ChatGPT/Claude counts and token estimates via Chrome/Safari;
  transmit counts only, never prompts or responses.
- **Tier 3 — local logs:** Claude Code, Codex, Gemini CLI, and similar JSONL sources; fully offline,
  byte-offset/cursor based, idempotent, and resilient to truncation/rotation.
- **Tier 4 — activity proxy:** opt-in macOS app-focus estimation, clearly labeled rough.

Each normalized usage event records source, model, token/message/minute counts, timestamp, accuracy
tier, and a stable external identifier for deduplication. Source failures must be isolated: one
broken or changed log format must not stop other sources or the app.

### Architecture direction

- `QuenchApp/Engine/`: pure Foundation logic and parsers; no SwiftUI or database dependencies.
- `QuenchApp/Models/`: GRDB storage, migrations, source cursors, and Keychain-facing abstractions.
- `QuenchApp/UI/`: SwiftUI menu-bar experience and settings.
- `QuenchTests/`: deterministic tests, including realistic redacted fixtures for every parser.
- Future browser extensions live in top-level, clearly separated packages.

Keep normalized data-source interfaces provider-neutral. Prefer incremental ingestion and database
uniqueness constraints over in-memory deduplication. Never perform network work on the main thread.

## Water math — superseded Section 6

The report's original flat `water_ml_per_wh` factors are superseded by the fuller EcoLogits-faithful
model implemented at M2:

- Facility-level token energy includes PUE, a per-request `fixed_wh`, and calibration to *How Hungry
  is AI?* (arXiv:2505.09598). Anchor: 100 input + 300 output GPT-4o tokens = 0.34 Wh.
- Water uses `on-site = E × WUE_onsite` and `off-site = E × WUE_offsite`, with per-provider on-site
  values and per-region grid water intensity.
- Conservative = Scope 1; Standard = Scope 1+2; Full = Scope 1+2 plus an explicit lifecycle share.
- Unknown models use the EcoLogits active-parameter GPU fallback (`B = 64`).

Do not collapse this back to a single factor. Changes require methodology notes, cited coefficient
updates, and tests against the real JSON.

## Online and EcoLogits policy

Quench is **privacy-preserving hybrid**, not offline-only. Online features may improve model catalogs,
coefficients, regional factors, usage accuracy, updates, and opt-in services. Every online path must
minimize data, document purpose and retention, use secure transport, fail closed, and preserve useful
local behavior when unavailable. Never send prompts, responses, local file paths, account identity,
or provider credentials to Quench or third-party analytics.

The API at `https://api.ecologits.ai/v1beta` can discover providers/models and electricity-mix zones
and return range estimates from provider, model, output-token count, optional latency, and region.
Use it for catalog refreshes, coefficient validation, research tooling, or an explicitly disclosed
enhanced-estimation mode. Cache only non-personal catalog data by default. A runtime estimator must:

- clearly disclose the exact metadata sent and offer a local-only setting;
- send no prompt/response content and no credentials belonging to another provider;
- pin the API version, validate schemas, use bounded timeouts, and fall back locally;
- avoid per-request calls when batching or on-device estimation provides the same user value.

## Delivery roadmap

1. **M1 — complete:** menu-bar skeleton, race bar, SQLite water logging, local day rollover.
2. **M2 — complete:** EcoLogits-faithful water engine, open coefficients, methodology, tests.
3. **M3 — complete:** Tier 3 Claude Code + Codex JSONL ingestion, cursors, rotation handling,
   deduplication, source health, and tests.
4. **M4 — current:** source settings/onboarding, accuracy labels, region/mode settings, diagnostic view.
5. **M5:** Tier 1 provider usage connectors with Keychain storage and strict permission boundaries.
6. **M6:** Chrome/Safari companion extension and private local bridge.
7. **M7:** streaks, restrained notifications, history, Wrapped cards, accessibility/localization.
8. **M8:** signed/notarized distribution, Homebrew cask, launch materials, fiscal sponsorship.

Finish and test the current milestone before pulling later-phase features forward.

## Open-source Git workflow

- The canonical branch is `main`. Use short `codex/<topic>` or contributor feature branches.
- Keep commits focused and written in imperative style; do not commit build products or secrets.
- Update tests, documentation, methodology, and coefficients together when behavior shifts.
- Preserve contributor changes in a dirty worktree; never discard unrelated work.
- Run `swift test` before every push. On macOS also build/run the app and check menu-bar behavior.
- Treat public APIs and JSONL formats as unstable: fixtures must be redacted and parsers defensive.
- Security/privacy regressions block release. Follow [`SECURITY.md`](SECURITY.md) for disclosures.

## Definition of done

A change is done only when behavior is implemented, relevant tests pass, user-facing docs are
current, privacy/accuracy implications are addressed, and the public repository contains no secret
or personal content. Record milestone handoff details in `NOTES.md` without turning it into a second
specification.
