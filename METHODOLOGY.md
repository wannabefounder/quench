# How Quench estimates AI water use

Every water number in Quench is an **estimate**, not a measured fact. Water use per AI query
is not directly observable, so we compute it the way the open-source
[EcoLogits](https://ecologits.ai) project does: estimate the energy a request consumed, then
convert that energy to water. We show a **range across three modes** rather than a single number,
because the honest answer spans an order of magnitude depending on scope and location.

All the numbers live in [`coefficients.json`](QuenchApp/Resources/coefficients.json) — a versioned,
human-readable file. The app bundles a reviewed copy so estimates work offline and can be audited
and improved through normal pull requests and releases. Quench does not silently replace reviewed
calculation data at runtime. Its optional catalog refresh can add active-parameter sizes only for
models absent from the bundled tables; schema validation and the bundled fallback remain mandatory.

## Step 1 — Energy (Wh)

For a request we know the model and, usually, the input/output token counts:

```
energy_Wh = fixed_wh + (input_tokens / 1000) * e_in + (output_tokens / 1000) * e_out
```

`fixed_wh`, `e_in` and `e_out` are per-model coefficients in `coefficients.json`. They are
**facility-level** (data-center Power Usage Effectiveness, PUE, is already folded in) and are
calibrated to the *"How Hungry is AI?"* benchmark of 30 models
([arXiv:2505.09598](https://arxiv.org/abs/2505.09598)), cross-checked against Sam Altman's 2025
figure (0.34 Wh/query), Google's Gemini 2025 report (0.24 Wh / 0.26 mL), UC Riverside
([arXiv:2304.03271](https://arxiv.org/abs/2304.03271)) and Epoch AI. As a sanity anchor, a short
GPT-4o query (100 input / 300 output tokens) computes to **0.34 Wh** — matching Altman's number.

Reasoning models (o3, DeepSeek-R1, anything tagged *reasoning*/*thinking*) carry far larger
`e_out` values because they emit long hidden reasoning traces — the benchmark measured them at
20–70× a standard query, and the coefficients reflect that.

**Fallbacks** when tokens aren't available:
- *Message count only* (browser extension): energy of one average message
  (`message_fallback`: 300 in / 350 out tokens) times the count.
- *Minutes active only* (app-focus proxy): `minutes * 0.8 messages/min * average-message energy`.

**Unknown models** fall back to the EcoLogits GPU energy model, which estimates energy from a
model's *active* parameter count `P` (billions; for mixture-of-experts, total ÷ active experts):

```
f_E(P, B) = alpha * e^(beta * B) * P + gamma      # Wh per output token, batch size B = 64
```

with `alpha = 1.17e-6`, `beta = -1.12e-2`, `gamma = 4.05e-5`, then multiplied by a
`system_overhead` factor to reach facility energy. This is why adding a new model can be as simple
as recording its active parameter count.

## Step 2 — Water (mL)

We use the EcoLogits / Li et al. (2025) two-scope water formula. With energy in kWh and factors
in litres per kWh (which equals millilitres per Wh):

```
server_energy_kWh = facility_energy_kWh / PUE
on-site  = server_energy_kWh * WUE_onsite    # cooling water at the data center (Scope 1)
off-site = facility_energy_kWh * WUE_offsite # water behind facility electricity (Scope 2)
```

`WUE_onsite` and PUE are **per-provider** (OpenAI/Azure, Anthropic, Google, DeepSeek, Meta, or a
default). `WUE_offsite` — the grid's water intensity — is **per-region**, and it is the single
biggest lever: it ranges from ~0.6 L/kWh (Nordic hydro) to ~6 L/kWh (China). The user's region
setting picks this factor.

## The three modes (the honest range)

| Mode | Scope | What it counts |
|---|---|---|
| **Conservative** | Scope 1 | On-site cooling only — roughly what companies voluntarily report (~10–15% of the real total). |
| **Standard** (default) | Scope 1 + 2 | Cooling **plus** the water behind the electricity — the fuller, defensible picture. |
| **Full footprint** | Scope 1 + 2 + 3 | Standard plus an embodied/lifecycle share (chip manufacturing, construction), added as `embodied_fraction`. |

```
conservative = on-site
standard     = on-site + off-site
full         = (on-site + off-site) * (1 + embodied_fraction)
```

Worked example — a GPT-4o request of 1000 input + 1000 output tokens (0.98 Wh), OpenAI provider,
global grid: conservative ≈ **0.25 mL**, standard ≈ **3.19 mL**, full ≈ **3.57 mL**. Same query on
the China grid rises to ≈ 6.1 mL (standard); on the Nordic grid it falls to ≈ 0.8 mL. The spread is
the point: we never present one number as truth.

This placement of PUE mirrors EcoLogits' published formula. EcoLogits writes the equation from
server energy as `E_server × [WUE_onsite + PUE × WUE_offsite]`; because Quench's calibrated energy
coefficients are already facility-level, the algebraically equivalent form above divides only the
on-site term by PUE.

## Optional EcoLogits catalog refresh

EcoLogits publishes a beta HTTP API at `https://api.ecologits.ai/v1beta`. When the user chooses
**Refresh public catalog**, Quench calls only `GET /providers` and `GET /models/{provider}`. It pins
the API version, validates response sizes and schemas, uses bounded timeouts, and stores the public
snapshot in an owner-only local file. No model the user used, token count, prompt, response, region,
credential, or identifier is sent.
As with any HTTPS request, the service can observe the connecting IP address and standard transport
metadata; Quench adds no account, installation, or analytics identifier.

The catalog's active-parameter ranges feed the same local EcoLogits fallback formula for models not
already reviewed in `coefficients.json`. Catalog values never override a bundled per-token
coefficient or reviewed parameter entry. Failed refreshes retain the previous valid cache, and an
empty cache falls back to the bundled estimates. Quench deliberately does not call
`POST /estimations`, because that would disclose usage metadata for little benefit over its fuller
on-device calculation.

## Why estimates, and how to challenge them

Vendors disclose little (OpenAI's figure is Scope-1 only; Anthropic publishes no per-query number),
grids vary by region and season, and cooling technology is improving fast. Critics will say the
numbers are wrong in both directions — so Quench ships ranges, cites every source here and in
`coefficients.json`, keeps the coefficients open and versioned, and updates them as new disclosures
land. The in-app [provider transparency scorecard](TRANSPARENCY.md) separately shows which evidence
major providers publish, without treating disclosure as proof of accuracy. If you think a coefficient
or evidence check is off, the versioned source is available to audit and change through a pull request.

## Sources
- EcoLogits methodology — https://ecologits.ai/latest/methodology/llm_inference/
- *How Hungry is AI?* (30-model benchmark) — https://arxiv.org/abs/2505.09598
- *Making AI Less "Thirsty"*, Ren et al., UC Riverside — https://arxiv.org/abs/2304.03271
- Sam Altman, 0.34 Wh / 0.000085 gal per query (2025)
- Google — environmental impact of AI inference (Gemini 0.24 Wh / 0.26 mL, 2025)
- Epoch AI — energy per ChatGPT query
