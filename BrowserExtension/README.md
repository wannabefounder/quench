# Quench browser companion (development preview)

This Manifest V3 extension estimates input/output tokens on `chatgpt.com` and `claude.ai`, then sends
only a count-only receipt to the native Quench bridge. Page text is used transiently inside the tab
to calculate an estimate; it is never included in a message, written to disk, or sent to a server.

## Local installation

1. In Quench Settings → Estimation, choose **Open companion folder**.
2. Open your browser's Extensions page, enable Developer mode, and choose **Load unpacked**. Select
   the opened `BrowserExtension` folder.
3. Copy the extension ID shown by the browser, paste it into Quench, and choose **Connect locally**.
4. Restart the browser once, then open ChatGPT or Claude.

Repository developers may instead build the bridge and run
`BrowserExtension/native-host/install.sh EXTENSION_ID`. The script prefers the helper inside an
installed `/Applications/Quench.app` and otherwise uses `.build/release`.

The bridge validates and rewrites every receipt before appending it to
`~/Library/Application Support/Quench/browser-events.jsonl` with owner-only permissions. Quench reads
that file incrementally with the same cursor and deduplication guarantees as its CLI log sources.

Selector breakage is expected as vendor UIs change. Selector updates must be reviewed and shipped in
this repository; Quench does not download remote code or selectors.

Run `node BrowserExtension/tests/site-adapters.test.js` from the repository root to verify the
versioned ChatGPT and Claude selector contracts. These fixtures also run in GitHub Actions.

This companion targets Chromium browsers. Safari packaging is intentionally out of scope.
