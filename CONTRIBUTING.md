# Contributing to Quench

Thank you for helping make AI's resource use easier to understand. Contributions to code,
methodology, accessibility, translations, research citations, and data-source support are welcome.

## Before opening a pull request

1. Open or choose an issue for substantial changes so product, privacy, and methodology tradeoffs
   are visible early.
2. Branch from `main` and keep the change focused.
3. Add or update deterministic tests. Redact all local-log fixtures: no prompts, responses, account
   identifiers, home-directory names, API keys, or machine identifiers.
4. Run `swift test`. For app/UI work, also build and manually check the menu-bar app on macOS 14+.
5. Update user-facing documentation and `METHODOLOGY.md` when assumptions or calculations change.

## Scientific changes

Coefficient changes must cite a primary source where possible, explain scope and units, preserve
the historical rationale in Git, and update tests against the bundled `coefficients.json`. Quench reports
estimates and ranges; do not imply direct measurement or collapse scope uncertainty into one number.

## Privacy and security

Never collect conversation content or add hidden telemetry. Provider credentials must use macOS
Keychain and must never enter SQLite, logs, fixtures, screenshots, or Git history. Report
vulnerabilities privately as described in [SECURITY.md](SECURITY.md).

By participating, you agree to follow the [Code of Conduct](CODE_OF_CONDUCT.md).
