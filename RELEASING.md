# Releasing Quench

Quench releases are reproducible from a Git tag. Local development packages are ad-hoc signed;
public downloads must be Developer ID signed, notarized by Apple, stapled, and checksum-published.

## One-time repository setup

Add these GitHub Actions secrets. Never put their values in the repository or issue tracker.

- `APPLE_DEVELOPER_ID_P12_BASE64` and `APPLE_DEVELOPER_ID_P12_PASSWORD`
- `APPLE_DEVELOPER_IDENTITY` (the complete Developer ID Application identity)
- `APPLE_NOTARY_APPLE_ID` and an app-specific `APPLE_NOTARY_PASSWORD`
- `APPLE_TEAM_ID`

Protect the `main` branch, require the CI check, enable secret scanning and push protection, and
restrict release-secret access to maintainers. The release workflow receives write access only to
create the GitHub release.

## Release procedure

1. Confirm CI is green and `git status` is clean.
2. Update the version-facing release notes and audit `PRIVACY.md` and `METHODOLOGY.md`.
3. Create and push an annotated `vMAJOR.MINOR.PATCH` tag.
4. Watch the Release workflow sign, notarize, staple, archive, checksum, and publish.
5. Download the release on a clean Mac, compare its SHA-256, open it, open Settings twice, log a
   glass, switch all four themes, and test launch at login after explicit opt-in.
6. Update the Homebrew tap with the published archive URL and SHA-256.

The workflow intentionally cannot publish until the project owner supplies Apple Developer
credentials. Fiscal-sponsor enrollment and Apple Developer membership are owner/legal actions, not
automated repository changes.
