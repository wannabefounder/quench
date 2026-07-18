#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/dist/Quench.app"
ARCHIVE="$ROOT/dist/Quench.zip"

test -d "$APP"
rm -f "$ARCHIVE" "$ARCHIVE.sha256"
ditto -c -k --sequesterRsrc --keepParent "$APP" "$ARCHIVE"
cd "$ROOT/dist"
shasum -a 256 Quench.zip > Quench.zip.sha256
codesign --verify --deep --strict --verbose=2 "$APP"
echo "$ARCHIVE"
