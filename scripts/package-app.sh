#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIGURATION="${CONFIGURATION:-release}"
SIGN_IDENTITY="${SIGN_IDENTITY:--}"
VERSION="${VERSION:-0.1.0}"
BUILD_NUMBER="${BUILD_NUMBER:-1}"
APP="$ROOT/dist/Quench.app"
ICONSET="$ROOT/dist/Quench.iconset"

cd "$ROOT"
swift build -c "$CONFIGURATION" --product QuenchApp
swift build -c "$CONFIGURATION" --product QuenchBrowserBridge
BIN_DIR="$(swift build -c "$CONFIGURATION" --show-bin-path)"

rm -rf "$APP" "$ICONSET"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$APP/Contents/Helpers" "$ICONSET"
cp "$BIN_DIR/QuenchApp" "$APP/Contents/MacOS/QuenchApp"
cp "$BIN_DIR/QuenchBrowserBridge" "$APP/Contents/Helpers/QuenchBrowserBridge"
cp "$ROOT/Packaging/Info.plist" "$APP/Contents/Info.plist"
cp "$ROOT/QuenchApp/Resources/coefficients.json" "$APP/Contents/Resources/coefficients.json"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" "$APP/Contents/Info.plist"

MASTER="$ROOT/QuenchApp/Resources/AppIconMaster.png"
sips -z 16 16 "$MASTER" --out "$ICONSET/icon_16x16.png" >/dev/null
sips -z 32 32 "$MASTER" --out "$ICONSET/icon_16x16@2x.png" >/dev/null
sips -z 32 32 "$MASTER" --out "$ICONSET/icon_32x32.png" >/dev/null
sips -z 64 64 "$MASTER" --out "$ICONSET/icon_32x32@2x.png" >/dev/null
sips -z 128 128 "$MASTER" --out "$ICONSET/icon_128x128.png" >/dev/null
sips -z 256 256 "$MASTER" --out "$ICONSET/icon_128x128@2x.png" >/dev/null
sips -z 256 256 "$MASTER" --out "$ICONSET/icon_256x256.png" >/dev/null
sips -z 512 512 "$MASTER" --out "$ICONSET/icon_256x256@2x.png" >/dev/null
sips -z 512 512 "$MASTER" --out "$ICONSET/icon_512x512.png" >/dev/null
sips -z 1024 1024 "$MASTER" --out "$ICONSET/icon_512x512@2x.png" >/dev/null
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/Quench.icns"
rm -rf "$ICONSET"

codesign --force --options runtime --sign "$SIGN_IDENTITY" \
    "$APP/Contents/Helpers/QuenchBrowserBridge"
codesign --force --options runtime --entitlements "$ROOT/Packaging/Quench.entitlements" \
    --sign "$SIGN_IDENTITY" "$APP"
codesign --verify --deep --strict --verbose=2 "$APP"
plutil -lint "$APP/Contents/Info.plist"

echo "$APP"
