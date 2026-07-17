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

Provider Admin API credentials are stored in macOS Keychain with device-only, unlocked-device
accessibility. They never enter Quench's SQLite database, UserDefaults, diagnostic logs, or
telemetry, and Quench never reloads a saved key into a visible text field.

When a provider is connected, Quench requests organization token totals grouped by model from that
provider. The request includes a time range and pagination cursor when needed. OpenRouter imports
only generation metadata for an ID entered by the user; Quench does not request stored generation
content. These operations do not include
prompts, responses, local paths, hydration data, or identifiers sent to a Quench-operated server.

Every normalized source has a separate local “count in today's race” control. This lets users avoid
API/local double-counting without deleting retained usage metadata.

The optional browser companion reads rendered message text transiently inside ChatGPT or Claude only
to estimate token counts. Conversation text never leaves the tab. The extension sends an opaque
local receipt ID, timestamp, site name, optional model name, and input/output integers through
Chrome native messaging. The bridge validates and re-encodes those exact fields before storing an
owner-only local JSONL receipt; unknown fields are discarded. There is no localhost server, trusted
certificate, Quench cloud relay, remotely downloaded selector code, or extension analytics.

## Diagnostics and analytics

Quench has no hidden analytics or advertising SDK. Any future diagnostic sharing must be explicit,
redacted, and opt-in.

This document describes the project's engineering privacy contract. A release-specific privacy
notice will be published before public distribution and updated whenever network behavior changes.
