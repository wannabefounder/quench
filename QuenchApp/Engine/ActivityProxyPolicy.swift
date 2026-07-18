import Foundation

/// Pure policy for the opt-in Tier 4 fallback. Bundle identifiers are matched in memory and are
/// never persisted; the database receives only a generic model family and active minutes.
public enum ActivityProxyPolicy {
    public static let accuracyTier = 4
    public static let supportedAppCount = 2

    public static func model(forBundleIdentifier bundleIdentifier: String?) -> String? {
        switch bundleIdentifier?.lowercased() {
        case "com.openai.chat", "com.openai.chatgpt": "chatgpt"
        case "com.anthropic.claudefordesktop", "com.anthropic.claude": "claude-sonnet"
        default: nil
        }
    }

    /// Ignore accidental focus flickers and cap a segment so sleep/wake gaps cannot be counted.
    public static func billableMinutes(from start: Date, to end: Date) -> Double? {
        let seconds = end.timeIntervalSince(start)
        guard seconds >= 15 else { return nil }
        return min(seconds, 120) / 60
    }
}
