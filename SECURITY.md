# Security policy

## Supported versions

Until the first stable release, security fixes are applied to the latest commit on `main`.

## Reporting a vulnerability

Please do not open a public issue for a security or privacy vulnerability. Use the repository's
private **Report a vulnerability** / Security Advisory flow and include impact, reproduction steps,
and any suggested mitigation. Do not include real API keys, prompts, responses, or personal logs.

Maintainers should acknowledge a report within seven days, keep the reporter informed, and publish
a coordinated fix and advisory when appropriate.

## Sensitive areas

Credential storage, local-log parsing, browser-to-app messaging, database migrations, coefficient
updates, and any networking are security-sensitive and require focused review.
