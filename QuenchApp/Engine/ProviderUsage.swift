import Foundation

public enum UsageProvider: String, CaseIterable, Hashable {
    case openAI = "openai"
    case anthropic = "anthropic"
}

public struct ProviderUsagePage: Equatable {
    public let events: [NormalizedUsageEvent]
    public let nextPage: String?

    public init(events: [NormalizedUsageEvent], nextPage: String?) {
        self.events = events
        self.nextPage = nextPage
    }
}

public enum ProviderUsageParser {
    public static func openAI(_ data: Data) throws -> ProviderUsagePage {
        let response = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        var events: [NormalizedUsageEvent] = []
        for bucket in response.data {
            for (index, result) in bucket.results.enumerated() {
                guard result.inputTokens > 0 || result.outputTokens > 0 else { continue }
                let model = result.model ?? "unknown-openai-model"
                events.append(NormalizedUsageEvent(
                    externalID: "openai:\(bucket.startTime):\(bucket.endTime):\(model):\(index)",
                    timestamp: Date(timeIntervalSince1970: TimeInterval(bucket.startTime)),
                    source: "openai-api",
                    model: result.model,
                    inputTokens: result.inputTokens,
                    outputTokens: result.outputTokens,
                    accuracyTier: 1
                ))
            }
        }
        return ProviderUsagePage(events: events,
                                 nextPage: response.hasMore ? response.nextPage : nil)
    }

    public static func anthropic(_ data: Data) throws -> ProviderUsagePage {
        let response = try JSONDecoder().decode(AnthropicResponse.self, from: data)
        var events: [NormalizedUsageEvent] = []
        for bucket in response.data {
            guard let timestamp = parseDate(bucket.startingAt) else { continue }
            for (index, result) in bucket.results.enumerated() {
                let cacheCreation = (result.cacheCreation?.ephemeral1hInputTokens ?? 0)
                    + (result.cacheCreation?.ephemeral5mInputTokens ?? 0)
                let input = result.uncachedInputTokens + result.cacheReadInputTokens + cacheCreation
                guard input > 0 || result.outputTokens > 0 else { continue }
                let model = result.model ?? "unknown-anthropic-model"
                events.append(NormalizedUsageEvent(
                    externalID: "anthropic:\(bucket.startingAt):\(bucket.endingAt):\(model):\(index)",
                    timestamp: timestamp,
                    source: "anthropic-api",
                    model: result.model,
                    inputTokens: input,
                    outputTokens: result.outputTokens,
                    accuracyTier: 1
                ))
            }
        }
        return ProviderUsagePage(events: events,
                                 nextPage: response.hasMore ? response.nextPage : nil)
    }

    private static func parseDate(_ raw: String) -> Date? {
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return fractional.date(from: raw) ?? ISO8601DateFormatter().date(from: raw)
    }
}

private struct OpenAIResponse: Decodable {
    let data: [Bucket]
    let hasMore: Bool
    let nextPage: String?

    enum CodingKeys: String, CodingKey {
        case data
        case hasMore = "has_more"
        case nextPage = "next_page"
    }

    struct Bucket: Decodable {
        let startTime: Int64
        let endTime: Int64
        let results: [Result]
        enum CodingKeys: String, CodingKey {
            case startTime = "start_time"
            case endTime = "end_time"
            case results
        }
    }

    struct Result: Decodable {
        let inputTokens: Int
        let outputTokens: Int
        let model: String?
        enum CodingKeys: String, CodingKey {
            case inputTokens = "input_tokens"
            case outputTokens = "output_tokens"
            case model
        }
    }
}

private struct AnthropicResponse: Decodable {
    let data: [Bucket]
    let hasMore: Bool
    let nextPage: String?

    enum CodingKeys: String, CodingKey {
        case data
        case hasMore = "has_more"
        case nextPage = "next_page"
    }

    struct Bucket: Decodable {
        let startingAt: String
        let endingAt: String
        let results: [Result]
        enum CodingKeys: String, CodingKey {
            case startingAt = "starting_at"
            case endingAt = "ending_at"
            case results
        }
    }

    struct Result: Decodable {
        let uncachedInputTokens: Int
        let cacheCreation: CacheCreation?
        let cacheReadInputTokens: Int
        let outputTokens: Int
        let model: String?
        enum CodingKeys: String, CodingKey {
            case uncachedInputTokens = "uncached_input_tokens"
            case cacheCreation = "cache_creation"
            case cacheReadInputTokens = "cache_read_input_tokens"
            case outputTokens = "output_tokens"
            case model
        }
    }

    struct CacheCreation: Decodable {
        let ephemeral1hInputTokens: Int
        let ephemeral5mInputTokens: Int
        enum CodingKeys: String, CodingKey {
            case ephemeral1hInputTokens = "ephemeral_1h_input_tokens"
            case ephemeral5mInputTokens = "ephemeral_5m_input_tokens"
        }
    }
}
