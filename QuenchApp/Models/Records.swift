import Foundation
import GRDB

struct WaterEntry: Codable, FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "water_entries"
    var id: Int64?
    var ts: Int64
    var ml: Int

    mutating func didInsert(_ inserted: InsertionSuccess) { id = inserted.rowID }
}

struct UsageEvent: Codable, FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "usage_events"
    var id: Int64?
    var ts: Int64
    var source: String
    var model: String?
    var inputTokens: Int?
    var outputTokens: Int?
    var messageCount: Int?
    var minutesActive: Double?
    var accuracyTier: Int
    var externalID: String?

    enum CodingKeys: String, CodingKey {
        case id, ts, source, model
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
        case messageCount = "message_count"
        case minutesActive = "minutes_active"
        case accuracyTier = "accuracy_tier"
        case externalID = "external_id"
    }

    mutating func didInsert(_ inserted: InsertionSuccess) { id = inserted.rowID }
}

struct SourceCursor: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "source_cursors"
    var path: String
    var source: String
    var byteOffset: Int64
    var generation: Int
    var lastModel: String?
    var cumulativeInputTokens: Int
    var cumulativeOutputTokens: Int

    enum CodingKeys: String, CodingKey {
        case path, source, generation
        case byteOffset = "byte_offset"
        case lastModel = "last_model"
        case cumulativeInputTokens = "cumulative_input_tokens"
        case cumulativeOutputTokens = "cumulative_output_tokens"
    }
}

struct DailySummary: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "daily_summary"
    var day: String
    var aiMlLow: Double?
    var aiMlMid: Double?
    var aiMlHigh: Double?
    var userMl: Int?
    var winner: String?

    enum CodingKeys: String, CodingKey {
        case day, winner
        case aiMlLow = "ai_ml_low"
        case aiMlMid = "ai_ml_mid"
        case aiMlHigh = "ai_ml_high"
        case userMl = "user_ml"
    }
}
