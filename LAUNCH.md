# Quench launch kit

## One-line description

Quench is a free, privacy-first Mac menu-bar app that races the water you drink against the
estimated water footprint of the AI you use.

## Short launch copy

AI has a water footprint, but the number is usually invisible. Quench turns it into a friendly
daily race: log your own water, let a continuously animated buddy track count-only AI usage, and
see who reaches the finish line first. Estimates are calculated locally from an open,
EcoLogits-faithful methodology with visible scopes and electricity regions. Quench has no account,
ads, hidden analytics, or conversation collection.

## What makes it different

- A simple human-vs-AI water race instead of a technical carbon dashboard.
- Four original animated buddies: Axel, Moss, Orbit, and Kiko.
- Local Claude Code and Codex ingestion plus optional count-only Chromium and provider sources.
- Conservative, Standard, and Full footprint scopes with honest uncertainty.
- Private streaks, weekly Thirst Index, gentle opt-in reminders, and Water Wrapped cards.
- Open-source Swift code, methodology, coefficients, privacy contract, and no Quench cloud account.

## Suggested release screenshots

1. Main race with Axel reacting to new AI water and both lanes clearly labeled.
2. The four theme cards together, showing that each theme has a distinct character and environment.
3. Scope and region settings with the local-processing privacy explanation.
4. History with streak freeze and weekly Thirst Index.
5. A square and Story-format Water Wrapped preview with aggregate-only sharing.

Capture light and dark appearance at 2× resolution. Do not show API keys, local paths, usernames,
real provider organizations, browser history, or notification previews containing personal data.

## Public claim guardrails

Say **estimated water footprint**, not measured water use. Do not claim provider-specific precision
when a request used a fallback. Explain that results depend on model, token counts, facility
efficiency, electricity region, and selected scope. Do not describe the browser companion as reading
“only tokens”; it transiently reads rendered message text inside the tab to estimate token counts,
then sends counts only to the local bridge.

## Launch channels

- GitHub release and repository README
- Hacker News `Show HN`, relevant open-source and sustainability communities
- Product Hunt only after the notarized download and clean-Mac test pass
- CodeCarbon/EcoLogits community outreach framed as an independent open-source implementation

## External owner actions

- Enroll in the Apple Developer Program and add the GitHub release secrets in `RELEASING.md`.
- Choose and apply to a fiscal sponsor; do not add donation collection before approval and a public
  funds-use policy exist. `FUNDING.md` contains the current readiness gaps and application copy.
- Create a Homebrew tap or submit the generated cask after the first notarized release supplies a
  permanent URL and SHA-256.
- Rotate the GitHub token that was exposed in the development conversation before public launch.

## Launch gate

Launch only after CI is green, the archive is notarized and stapled, the checksum matches on a clean
Mac, Settings opens after being closed twice, all four themes animate with Reduce Motion behavior
verified, launch-at-login can be enabled and disabled, and the privacy/methodology documents match
the shipped network behavior.
