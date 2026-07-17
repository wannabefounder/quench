# Quench privacy principles

Quench is designed to measure AI usage without learning what the user asked or what the AI answered.

## Data kept on the Mac

Quench stores hydration entries and normalized usage metadata such as timestamp, source, model,
token counts, and accuracy tier. It does not need prompt or response content. Local AI-tool logs are
read incrementally and only the normalized metadata is written to Quench's database.

## Network features

Quench may use secure network connections for public coefficient/model-catalog updates, software
updates, provider usage endpoints selected by the user, or enhanced environmental estimates. Each
feature must disclose its purpose and the categories of metadata sent. Quench will not send prompts,
responses, local file paths, or provider credentials to analytics or environmental-estimation
services. Useful local behavior remains available when a network service is unavailable.

## Credentials

Future API credentials will be stored in macOS Keychain, never in Quench's SQLite database,
diagnostic logs, or telemetry.

## Diagnostics and analytics

Quench has no hidden analytics or advertising SDK. Any future diagnostic sharing must be explicit,
redacted, and opt-in.

This document describes the project's engineering privacy contract. A release-specific privacy
notice will be published before public distribution and updated whenever network behavior changes.
