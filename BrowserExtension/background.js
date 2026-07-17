const HOST = "app.quench.browser_bridge";

function validReceipt(value) {
  return value && value.schema_version === 1
    && typeof value.id === "string" && value.id.length > 0 && value.id.length <= 200
    && ["chatgpt.com", "claude.ai"].includes(value.site)
    && Number.isInteger(value.input_tokens) && value.input_tokens >= 0
    && Number.isInteger(value.output_tokens) && value.output_tokens >= 0
    && value.input_tokens + value.output_tokens > 0
    && typeof value.timestamp === "string"
    && (value.model === null || typeof value.model === "string");
}

chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  let senderSite;
  try { senderSite = new URL(sender.url).hostname; } catch { senderSite = null; }
  if (message?.type !== "quench-receipt" || !validReceipt(message.receipt)
      || senderSite !== message.receipt.site) {
    sendResponse({ accepted: false, error: "Invalid count-only receipt." });
    return false;
  }

  const port = chrome.runtime.connectNative(HOST);
  let answered = false;
  port.onMessage.addListener((reply) => {
    answered = true;
    chrome.storage.local.set({ bridgeStatus: reply.accepted ? "Connected" : "Receipt rejected" });
    sendResponse(reply);
    port.disconnect();
  });
  port.onDisconnect.addListener(() => {
    if (!answered) {
      chrome.storage.local.set({ bridgeStatus: "Native bridge not installed" });
      sendResponse({ accepted: false, error: "Native bridge not installed." });
    }
  });
  port.postMessage(message.receipt);
  return true;
});
