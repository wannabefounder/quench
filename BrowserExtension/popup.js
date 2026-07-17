chrome.storage.local.get("bridgeStatus", ({ bridgeStatus }) => {
  document.getElementById("status").textContent = bridgeStatus || "Open ChatGPT or Claude to begin";
});
