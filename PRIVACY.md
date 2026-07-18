# Quench privacy principles

Quench is designed to measure AI usage without learning what the user asked or what the AI answered.

## Data kept on the Mac

Quench stores hydration entries and normalized usage metadata such as timestamp, source, model,
token counts, and accuracy tier. It does not need prompt or response content. Local AI-tool logs are
read incrementally and only the normalized metadata is written to Quench's database.

Gemini CLI session files can contain full conversations, tool activity, and reasoning summaries.
Quench accepts only Gemini message records with token summaries and extracts timestamp, model,
input-token count, and output-token count. No other Gemini session field is retained.

## Network features

Quench may use secure network connections for public coefficient/model-catalog updates, software
updates, provider usage endpoints selected by the user, or enhanced environmental estimates. Each
feature must disclose its purpose and the categories of metadata sent. Quench will not send prompts,
responses, local file paths, or provider credentials to analytics or environmental-estimation
services. Useful local behavior remains available when a network service is unavailable.

Quench's current EcoLogits-faithful water estimate runs locally. It does not call EcoLogits' live
estimation endpoint, because that would disclose provider, model, output-token count, and electricity
region to another service. A future public model-catalog refresh may retrieve catalog data without
sending AI usage; any usage-bearing live estimate must remain separately disclosed and opt-in.

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

The Tier 4 desktop-activity fallback is off by default. If enabled, Quench observes only foreground
application activation through macOS Workspace notifications for the ChatGPT and Claude desktop
apps. It stores generic model family, active minutes, timestamp, and rough accuracy tier. It does
not request Accessibility permission or read window titles, typing, URLs, documents, bundle
identifiers, prompts, or responses. Short focus flickers are ignored and sleep gaps are capped.

The optional browser companion reads rendered message text transiently inside ChatGPT or Claude only
to estimate token counts. Conversation text never leaves the tab. The extension sends an opaque
local receipt ID, timestamp, site name, optional model name, and input/output integers through
Chrome native messaging. The bridge validates and re-encodes those exact fields before storing an
owner-only local JSONL receipt; unknown fields are discarded. There is no localhost server, trusted
certificate, Quench cloud relay, remotely downloaded selector code, or extension analytics.
Connecting from Settings writes one owner-only native-host manifest inside the selected browser's
local Application Support folder. It contains only the extension ID and the absolute path to the
signed bridge bundled in Quench.app. Disconnect removes that manifest.

Hydration notifications are off by default and require explicit macOS permission. Quench stores only
the local day, reminder count, and last-reminder time needed to enforce its daily cap and cooldown.
Notification content contains a rounded hydration gap, never conversation or provider content.

The always-on-top mini status is a native non-activating panel with an animated pixel water drop. It
displays values already held by Quench and does not inspect other windows, take screenshots, record
the screen, or request Accessibility access. Its visibility preference and the user's editable
daily fluid goal are kept in UserDefaults on this Mac.

Hydration pacing is a general habit aid, not medical advice. Quench spreads the user's chosen goal
between 08:00 and 20:00 and considers a reminder only when the logged amount is at least 250 mL
behind that pace. The default 2 L fluid goal reflects the NHS's general 6–8 cup guide, but remains
editable because needs vary with food, activity, climate, pregnancy, illness, and individual health.

AI Water Wrapped images are rendered locally from aggregate daily totals. Choosing Share creates a
temporary PNG and hands it to the standard macOS share sheet; Quench does not upload or retain a
remote copy.

The optional clean-water pledge is a local calculator stored in UserDefaults. Quench does not
collect payments, verify donations, operate a donation server, or send pledge/usage data to a
charity. Charity links open only when clicked and are independent links, not claimed partnerships.

## Diagnostics and analytics

Quench has no hidden analytics or advertising SDK. Any future diagnostic sharing must be explicit,
redacted, and opt-in.

This document describes the project's engineering privacy contract. A release-specific privacy
notice will be published before public distribution and updated whenever network behavior changes.
