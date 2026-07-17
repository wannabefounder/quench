import Foundation

/// Privacy-safe usage metadata produced by a source parser. No prompt or response content is kept.
public struct NormalizedUsageEvent: Equatable {
    public let externalID: String
    public let timestamp: Date
    public let source: String
    public let model: String?
    public let inputTokens: Int
    public let outputTokens: Int
    public let accuracyTier: Int

    public init(externalID: String, timestamp: Date, source: String, model: String?,
                inputTokens: Int, outputTokens: Int, accuracyTier: Int = 3) {
        self.externalID = externalID
        self.timestamp = timestamp
        self.source = source
        self.model = model
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
        self.accuracyTier = accuracyTier
    }
}

private enum LogJSON {
    static func object(_ line: Data) -> [String: Any]? {
        (try? JSONSerialization.jsonObject(with: line)) as? [String: Any]
    }

    static func dictionary(_ value: Any?) -> [String: Any]? { value as? [String: Any] }

    static func int(_ value: Any?) -> Int? {
        if let n = value as? NSNumber { return n.intValue }
        if let s = value as? String { return Int(s) }
        return nil
    }

    static func date(_ value: Any?) -> Date? {
        guard let raw = value as? String else { return nil }
        let withFraction = ISO8601DateFormatter()
        withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = withFraction.date(from: raw) { return date }
        return ISO8601DateFormatter().date(from: raw)
    }
}

public enum ClaudeCodeLogParser {
    /// Claude Code records assistant messages with usage metadata on the message object.
    public static func parse(line: Data, externalID: String) -> NormalizedUsageEvent? {
        guard let root = LogJSON.object(line), root["type"] as? String == "assistant",
              let message = LogJSON.dictionary(root["message"]),
              let usage = LogJSON.dictionary(message["usage"]),
              let timestamp = LogJSON.date(root["timestamp"]) else { return nil }

        // Anthropic reports cache tokens separately. They are still tokens processed by the model;
        // keep them in the input total until the energy model gains cache-specific coefficients.
        let input = (LogJSON.int(usage["input_tokens"]) ?? 0)
            + (LogJSON.int(usage["cache_creation_input_tokens"]) ?? 0)
            + (LogJSON.int(usage["cache_read_input_tokens"]) ?? 0)
        let output = LogJSON.int(usage["output_tokens"]) ?? 0
        guard input > 0 || output > 0 else { return nil }

        return NormalizedUsageEvent(
            externalID: externalID,
            timestamp: timestamp,
            source: "claude-code",
            model: message["model"] as? String,
            inputTokens: input,
            outputTokens: output
        )
    }
}

/// Stateful because Codex token-count events may expose cumulative totals instead of per-turn usage.
public struct CodexLogParser {
    public private(set) var currentModel: String?
    public private(set) var cumulativeInputTokens: Int
    public private(set) var cumulativeOutputTokens: Int

    public init(model: String? = nil, cumulativeInputTokens: Int = 0,
                cumulativeOutputTokens: Int = 0) {
        self.currentModel = model
        self.cumulativeInputTokens = cumulativeInputTokens
        self.cumulativeOutputTokens = cumulativeOutputTokens
    }

    public mutating func parse(line: Data, externalID: String) -> NormalizedUsageEvent? {
        guard let root = LogJSON.object(line) else { return nil }
        let payload = LogJSON.dictionary(root["payload"])

        if let model = (payload?["model"] as? String) ?? (root["model"] as? String),
           !model.isEmpty {
            currentModel = model
        }

        guard root["type"] as? String == "event_msg",
              payload?["type"] as? String == "token_count",
              let info = LogJSON.dictionary(payload?["info"]),
              let timestamp = LogJSON.date(root["timestamp"]) else { return nil }

        let total = LogJSON.dictionary(info["total_token_usage"])
        let latest = LogJSON.dictionary(info["last_token_usage"])
        let previousInput = cumulativeInputTokens
        let previousOutput = cumulativeOutputTokens

        if let total {
            cumulativeInputTokens = LogJSON.int(total["input_tokens"]) ?? cumulativeInputTokens
            cumulativeOutputTokens = LogJSON.int(total["output_tokens"]) ?? cumulativeOutputTokens
        }

        let input: Int
        let output: Int
        if let latest {
            input = LogJSON.int(latest["input_tokens"]) ?? 0
            output = LogJSON.int(latest["output_tokens"]) ?? 0
        } else {
            input = max(0, cumulativeInputTokens - previousInput)
            output = max(0, cumulativeOutputTokens - previousOutput)
        }
        guard input > 0 || output > 0 else { return nil }

        return NormalizedUsageEvent(
            externalID: externalID,
            timestamp: timestamp,
            source: "codex",
            model: currentModel,
            inputTokens: input,
            outputTokens: output
        )
    }
}
