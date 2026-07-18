# Quench governance

Quench is an open-source, mission-driven project. Its governance should make the privacy promise,
scientific method, and release process durable beyond any one contributor.

## Current model

Quench is maintainer-led while the contributor community is small. The project maintainer decides
releases and resolves proposals after public discussion, but changes remain reviewable through
issues and pull requests. No contributor may weaken the privacy contract, introduce hidden
telemetry, or present estimates as measurements without an explicit public design decision.

## How decisions are made

- Small fixes and documentation changes use normal pull-request review.
- Calculation, data-collection, privacy, governance, and licensing changes require an issue that
  records the motivation, alternatives, affected data, migration plan, and verification evidence.
- Coefficient changes must update `METHODOLOGY.md`, the versioned JSON, and deterministic tests.
- Security reports follow `SECURITY.md` and may remain private until users have a fix.
- If consensus is not reached, the maintainer documents the decision and rationale publicly.

## Roles and access

- Maintainers may merge, release, and manage repository settings.
- Release credentials use least privilege, stay outside Git, and are available only to maintainers
  responsible for releases.
- At least two trusted administrators should be appointed before accepting community funds or
  depending on fiscal sponsorship.
- Contributors retain copyright to their work and license contributions under the repository's MIT
  License by submitting them.

## Funds and conflicts

Quench does not currently collect money. Before it does, the project will publish its fiscal host,
fees, administrators, budget, expense approval process, and conflict-of-interest disclosures.
Quench will not imply a charity partnership or route donations on a charity's behalf without a
written agreement. Product estimates and project funding must never be influenced by undisclosed
provider sponsorship.

## Succession

If the lead maintainer is inactive for 90 days and cannot be reached, the remaining trusted
maintainers may appoint an interim maintainer through a public issue. If no maintainer remains, a
group of at least three established contributors may request stewardship, preserving the MIT
license, history, privacy contract, and open methodology.

