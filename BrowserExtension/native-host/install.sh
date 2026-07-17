#!/bin/sh
set -eu

if [ "$#" -ne 1 ]; then
  echo "Usage: ./install.sh CHROME_EXTENSION_ID" >&2
  exit 64
fi

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
BRIDGE="$ROOT/.build/release/QuenchBrowserBridge"
if [ ! -x "$BRIDGE" ]; then
  echo "Build the bridge first: swift build -c release --product QuenchBrowserBridge" >&2
  exit 1
fi

DEST="$HOME/Library/Application Support/Google/Chrome/NativeMessagingHosts"
mkdir -p "$DEST"
MANIFEST="$DEST/app.quench.browser_bridge.json"
sed -e "s|__BRIDGE_PATH__|$BRIDGE|g" -e "s|__EXTENSION_ID__|$1|g" \
  "$ROOT/BrowserExtension/native-host/manifest.template.json" > "$MANIFEST"
chmod 600 "$MANIFEST"
echo "Installed Quench native host for extension $1"
