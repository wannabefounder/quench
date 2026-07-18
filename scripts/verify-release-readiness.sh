#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="${APP_PATH:-$ROOT/dist/Quench.app}"
ARCHIVE="${ARCHIVE_PATH:-$ROOT/dist/Quench.zip}"
PLIST="$APP/Contents/Info.plist"
EXTENSION="$APP/Contents/Resources/BrowserExtension"

fail() { echo "release check failed: $*" >&2; exit 1; }
pass() { echo "✓ $*"; }

cd "$ROOT"

git diff --check
if test "${ALLOW_DIRTY:-0}" != "1"; then
  git diff --quiet || fail "tracked worktree changes are present"
  git diff --cached --quiet || fail "staged changes are present"
fi
if git grep -nE 'gh[pousr]_[A-Za-z0-9_]{20,}' -- .; then
  fail "a GitHub credential pattern is present in tracked files"
fi
pass "clean tracked source and secret-pattern scan"

for document in LICENSE README.md PRIVACY.md SECURITY.md METHODOLOGY.md GOVERNANCE.md \
  CONTRIBUTING.md CODE_OF_CONDUCT.md COMPLETION_AUDIT.md RELEASING.md; do
  test -s "$document" || fail "missing required project document: $document"
done
pass "open-source, privacy, methodology, governance, and release documents"

test -d "$APP" || fail "app bundle not found: $APP"
test -x "$APP/Contents/MacOS/QuenchApp" || fail "main executable missing"
test -x "$APP/Contents/Helpers/QuenchBrowserBridge" || fail "browser bridge missing"
test -s "$APP/Contents/Resources/Quench.icns" || fail "app icon missing"
test -s "$APP/Contents/Resources/coefficients.json" || fail "coefficients missing"
plutil -lint "$PLIST" >/dev/null
test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$PLIST")" = \
  "com.wannabefounder.quench" || fail "unexpected bundle identifier"
test "$(/usr/libexec/PlistBuddy -c 'Print :LSMinimumSystemVersion' "$PLIST")" = \
  "14.0" || fail "unexpected minimum macOS version"
if /usr/libexec/PlistBuddy -c 'Print :LSUIElement' "$PLIST" >/dev/null 2>&1; then
  fail "LSUIElement would hide the user-visible Dock application"
fi
for permission in NSCameraUsageDescription NSMicrophoneUsageDescription \
  NSScreenCaptureUsageDescription NSAppleEventsUsageDescription; do
  if /usr/libexec/PlistBuddy -c "Print :$permission" "$PLIST" >/dev/null 2>&1; then
    fail "unexpected sensitive permission declaration: $permission"
  fi
done
jq empty "$APP/Contents/Resources/coefficients.json"
pass "bundle identity, deployment target, resources, and permission surface"

for asset in manifest.json background.js content.js site-adapters.js popup.html popup.js README.md; do
  test -s "$EXTENSION/$asset" || fail "browser companion asset missing: $asset"
done
jq -e '
  .manifest_version == 3 and
  (.permissions | sort) == ["nativeMessaging", "storage"] and
  (.host_permissions | sort) == ["https://chatgpt.com/*", "https://claude.ai/*"] and
  (.content_scripts | length) == 1 and
  (.content_scripts[0].matches | sort) == ["https://chatgpt.com/*", "https://claude.ai/*"]
' "$EXTENSION/manifest.json" >/dev/null || fail "browser extension permission contract changed"
node BrowserExtension/tests/site-adapters.test.js >/dev/null
pass "bundled Chromium companion and count-only adapter fixtures"

codesign --verify --deep --strict --verbose=2 "$APP"
codesign --verify --strict --verbose=2 "$APP/Contents/Helpers/QuenchBrowserBridge"
codesign -dvv "$APP" 2>&1 | grep -F 'runtime' >/dev/null \
  || fail "app signature is missing hardened runtime"
ENTITLEMENTS="$(mktemp -t quench-entitlements).plist"
trap 'rm -f "$ENTITLEMENTS"' EXIT
codesign -d --entitlements :- "$APP" >"$ENTITLEMENTS" 2>/dev/null
plutil -lint "$ENTITLEMENTS" >/dev/null
plutil -convert json -o - "$ENTITLEMENTS" | jq -e 'keys | length == 0' >/dev/null \
  || fail "unexpected app entitlements"
pass "hardened signature structure and empty entitlement surface"

ruby -c Packaging/quench.rb.template >/dev/null
grep -Fq 'releases/download/v#{version}/Quench.zip' Packaging/quench.rb.template \
  || fail "Homebrew cask release URL drifted"
pass "Homebrew cask template syntax and release URL"

if test -f "$ARCHIVE" || test -f "$ARCHIVE.sha256"; then
  test -f "$ARCHIVE" && test -f "$ARCHIVE.sha256" \
    || fail "archive and checksum must be produced together"
  (cd "$(dirname "$ARCHIVE")" && shasum -a 256 -c "$(basename "$ARCHIVE").sha256")
  unzip -tq "$ARCHIVE" >/dev/null
  unzip -Z1 "$ARCHIVE" | grep -F 'Quench.app/Contents/MacOS/QuenchApp' >/dev/null \
    || fail "archive does not contain Quench.app"
  pass "release archive integrity and SHA-256"
else
  echo "• archive check skipped (run scripts/archive-app.sh to include it)"
fi

pass "Quench release-readiness gate complete"
