# Quench browser companion (development preview)

This Manifest V3 extension estimates input/output tokens on `chatgpt.com` and `claude.ai`, then sends
only a count-only receipt to the native Quench bridge. Page text is used transiently inside the tab
to calculate an estimate; it is never included in a message, written to disk, or sent to a server.

## Local installation

1. Build the native host: `swift build -c release --product QuenchBrowserBridge`.
2. Open `chrome://extensions`, enable Developer mode, and choose **Load unpacked**. Select this folder.
3. Copy the extension ID shown by Chrome.
4. Run `BrowserExtension/native-host/install.sh EXTENSION_ID`.
5. Restart Chrome and open ChatGPT or Claude.

The bridge validates and rewrites every receipt before appending it to
`~/Library/Application Support/Quench/browser-events.jsonl` with owner-only permissions. Quench reads
that file incrementally with the same cursor and deduplication guarantees as its CLI log sources.

Selector breakage is expected as vendor UIs change. Selector updates must be reviewed and shipped in
this repository; Quench does not download remote code or selectors.

Run `node BrowserExtension/tests/site-adapters.test.js` from the repository root to verify the
versioned ChatGPT and Claude selector contracts. These fixtures also run in GitHub Actions.

This companion targets Chromium browsers. Safari packaging is intentionally out of scope.
