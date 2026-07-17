# Quench — build notes

The full product spec lives in the project instructions. This file records **deviations** agreed
with the user, so future sessions don't undo them.

## Section 6 (Water math) — UPDATED at M2 (2026-07-18)

The original spec pinned a **collapsed** formula: one flat `water_ml_per_wh` factor (0.6/1.6/2.5)
and hand-picked per-token coefficients. Per the user's explicit request ("I want everything full
fledged like the research report — mirror EcoLogits"), Section 6 is **superseded** by a fuller,
EcoLogits-faithful model. See [`METHODOLOGY.md`](METHODOLOGY.md) for the full write-up.

What changed:
- Energy stays token-based but is **facility-level (PUE included)** and **calibrated to the
  "How Hungry is AI?" benchmark** (arXiv:2505.09598), plus a per-request `fixed_wh` term. Anchor:
  short GPT-4o query (100 in / 300 out) = 0.34 Wh.
- Water uses the **two-scope EcoLogits formula**: `on-site = E * WUE_onsite`,
  `off-site = E * WUE_offsite`, with **per-provider** `WUE_onsite`/PUE and **per-region**
  `WUE_offsite` (the grid factor — the biggest lever; global 3.0 -> China 6.0 -> Nordics 0.6 L/kWh).
- Three modes map to scopes: Conservative = Scope 1, Standard = Scope 1+2, Full = Scope 1+2+3
  (`+ embodied_fraction`).
- Unknown models fall back to the **EcoLogits GPU energy model** from active parameter count
  (`f_E = alpha*e^(beta*B)*P + gamma`, B=64), so new models need only a param count.

All coefficients remain in the versioned, community-auditable [`coefficients.json`](coefficients.json).
The engine (`QuenchApp/Engine/WaterMath.swift`) is pure and covered by `QuenchTests/WaterMathTests.swift`
(20 tests, all asserting against the real JSON).

Everything else in the original spec still stands.
