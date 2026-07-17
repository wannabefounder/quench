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

    enum CodingKeys: String, CodingKey {
        case id, ts, source, model
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
        case messageCount = "message_count"
        case minutesActive = "minutes_active"
        case accuracyTier = "accuracy_tier"
    }

    mutating func didInsert(_ inserted: InsertionSuccess) { id = inserted.rowID }
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
