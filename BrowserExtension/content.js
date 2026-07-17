(() => {
  const site = location.hostname;
  const adapter = globalThis.QuenchSiteAdapters.forHost(site);
  if (!adapter) return;
  const sentKey = "quench-sent-receipts-v1";
  const sent = new Set(JSON.parse(sessionStorage.getItem(sentKey) || "[]"));
  let scanning = false;
  let scanTimer;
  let conversationPath = location.pathname;
  let baselineAssistantCount;

  // Text is read transiently in this page process only. Only the resulting integer leaves the tab.
  const estimateTokens = (node) => globalThis.QuenchSiteAdapters.estimateTokens(node.innerText || "");

  async function stableID(assistantIndex) {
    const localKey = `${site}|${location.pathname}|${assistantIndex}`;
    const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(localKey));
    return [...new Uint8Array(digest)].map((byte) => byte.toString(16).padStart(2, "0")).join("");
  }

  async function scan() {
    if (scanning) return;
    scanning = true;
    try {
      const messages = [...document.querySelectorAll(adapter.candidateSelector)]
        .map((node) => ({ node, role: globalThis.QuenchSiteAdapters.roleForElement(site, node) }))
        .filter((message) => message.role);
      const users = messages.filter((message) => message.role === "user").map((message) => message.node);
      const assistants = messages.filter((message) => message.role === "assistant").map((message) => message.node);
      if (globalThis.QuenchSiteAdapters.shouldBaseline(
        conversationPath, location.pathname, baselineAssistantCount
      )) {
        // Existing history may be days or months old. Baseline it instead of turning a reopened
        // conversation into today's usage; only assistant turns completed after this point count.
        conversationPath = location.pathname;
        baselineAssistantCount = assistants.length;
        return;
      }
      conversationPath = location.pathname;
      for (let index = 0; index < assistants.length; index += 1) {
        if (index < baselineAssistantCount) continue;
        const assistant = assistants[index];
        const user = [...users].reverse().find((candidate) =>
          candidate.compareDocumentPosition(assistant) & Node.DOCUMENT_POSITION_FOLLOWING);
        if (!user || !assistant.innerText?.trim()) continue;
        const inputTokens = estimateTokens(user);
        const outputTokens = estimateTokens(assistant);
        const id = await stableID(index);
        if (sent.has(id)) continue;
        const receipt = {
          schema_version: 1,
          id,
          timestamp: new Date().toISOString(),
          site,
          model: null,
          input_tokens: inputTokens,
          output_tokens: outputTokens
        };
        chrome.runtime.sendMessage({ type: "quench-receipt", receipt }, (reply) => {
          if (reply?.accepted) {
            sent.add(id);
            sessionStorage.setItem(sentKey, JSON.stringify([...sent].slice(-1000)));
          }
        });
      }
    } finally {
      scanning = false;
    }
  }

  function scheduleScan() {
    window.clearTimeout(scanTimer);
    // Both sites stream into the last assistant node. Debounce until mutations settle so a turn
    // becomes one receipt instead of a series of partial-response receipts.
    scanTimer = window.setTimeout(scan, 2500);
  }

  const observer = new MutationObserver(scheduleScan);
  observer.observe(document.documentElement, { childList: true, subtree: true, characterData: true });
  scheduleScan();
})();
