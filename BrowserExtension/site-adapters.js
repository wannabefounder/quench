(function (root, factory) {
  const api = factory();
  if (typeof module === "object" && module.exports) module.exports = api;
  root.QuenchSiteAdapters = api;
})(typeof globalThis !== "undefined" ? globalThis : this, function () {
  "use strict";

  const definitions = Object.freeze({
    "chatgpt.com": Object.freeze({
      candidateSelector: "[data-message-author-role]",
      role(attributes) {
        const role = attributes["data-message-author-role"];
        return role === "user" || role === "assistant" ? role : null;
      }
    }),
    "claude.ai": Object.freeze({
      candidateSelector: '[data-testid="user-message"], [data-is-streaming="false"], [data-message-author="assistant"]',
      role(attributes) {
        if (attributes["data-testid"] === "user-message") return "user";
        if (attributes["data-is-streaming"] === "false"
            || attributes["data-message-author"] === "assistant") return "assistant";
        return null;
      }
    })
  });

  function forHost(hostname) { return definitions[hostname] || null; }
  function attributesFor(element) {
    return Object.fromEntries([...element.attributes].map((attribute) => [attribute.name, attribute.value]));
  }
  function roleForElement(hostname, element) {
    return forHost(hostname)?.role(attributesFor(element)) || null;
  }
  function estimateTokens(text) { return Math.max(1, Math.ceil((text || "").length / 4)); }
  function shouldBaseline(previousPath, nextPath, baselineAssistantCount) {
    if (baselineAssistantCount === undefined) return true;
    if (previousPath === nextPath) return false;
    // ChatGPT changes / into /c/<id> after the first prompt. That is the same new conversation,
    // not reopened history, so its first assistant response must still be counted.
    return !(previousPath === "/" && baselineAssistantCount === 0);
  }

  return Object.freeze({ forHost, roleForElement, estimateTokens, shouldBaseline });
});
