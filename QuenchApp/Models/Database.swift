import Foundation
import GRDB
import QuenchEngine

/// Single SQLite DB at ~/Library/Application Support/Quench/quench.sqlite
final class AppDatabase {
    static let shared = try! AppDatabase()
    let dbQueue: DatabaseQueue

    private init() throws {
        let dir = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Quench", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        dbQueue = try DatabaseQueue(path: dir.appendingPathComponent("quench.sqlite").path)
        try migrator.migrate(dbQueue)
    }

    private var migrator: DatabaseMigrator {
        var m = DatabaseMigrator()
        m.registerMigration("v1") { db in
            try db.execute(sql: """
                CREATE TABLE usage_events (
                  id INTEGER PRIMARY KEY,
                  ts INTEGER NOT NULL,
                  source TEXT NOT NULL,
                  model TEXT,
                  input_tokens INTEGER,
                  output_tokens INTEGER,
                  message_count INTEGER,
                  minutes_active REAL,
                  accuracy_tier INTEGER NOT NULL
                );
                CREATE TABLE water_entries (
                  id INTEGER PRIMARY KEY,
                  ts INTEGER NOT NULL,
                  ml INTEGER NOT NULL
                );
                CREATE TABLE daily_summary (
                  day TEXT PRIMARY KEY,
                  ai_ml_low REAL, ai_ml_mid REAL, ai_ml_high REAL,
                  user_ml INTEGER,
                  winner TEXT
                );
                CREATE INDEX idx_usage_ts ON usage_events(ts);
                CREATE INDEX idx_water_ts ON water_entries(ts);
                """)
        }
        m.registerMigration("v2-local-log-ingestion") { db in
            try db.alter(table: "usage_events") { table in
                table.add(column: "external_id", .text)
            }
            try db.create(index: "idx_usage_external_id", on: "usage_events",
                          columns: ["external_id"], unique: true)
            try db.create(table: "source_cursors") { table in
                table.column("path", .text).primaryKey()
                table.column("source", .text).notNull()
                table.column("byte_offset", .integer).notNull()
                table.column("generation", .integer).notNull().defaults(to: 0)
                table.column("last_model", .text)
                table.column("cumulative_input_tokens", .integer).notNull().defaults(to: 0)
                table.column("cumulative_output_tokens", .integer).notNull().defaults(to: 0)
            }
        }
        m.registerMigration("v3-provider-sync") { db in
            try db.create(table: "provider_sync_state") { table in
                table.column("provider", .text).primaryKey()
                table.column("last_attempt_ts", .integer)
                table.column("last_success_ts", .integer)
                table.column("last_error", .text)
                table.column("imported_events", .integer).notNull().defaults(to: 0)
            }
        }
        return m
    }

    // MARK: - Water logging

    func logWater(ml: Int, at date: Date = Date()) throws {
        try dbQueue.write { db in
            var entry = WaterEntry(id: nil, ts: Int64(date.timeIntervalSince1970), ml: ml)
            try entry.insert(db)
        }
    }

    /// Total ml the user drank today (local midnight boundary).
    func todayUserMl(now: Date = Date(), calendar: Calendar = .current) throws -> Int {
        let start = calendar.startOfDay(for: now)
        let startTs = Int64(start.timeIntervalSince1970)
        return try dbQueue.read { db in
            try Int.fetchOne(
                db,
                sql: "SELECT COALESCE(SUM(ml), 0) FROM water_entries WHERE ts >= ?",
                arguments: [startTs]
            ) ?? 0
        }
    }

    /// Today's usage events as pure engine samples (local midnight boundary). Empty until M3+ populate them.
    func todayUsageSamples(includedSources: Set<String>? = nil,
                           now: Date = Date(), calendar: Calendar = .current) throws -> [UsageSample] {
        let startTs = Int64(calendar.startOfDay(for: now).timeIntervalSince1970)
        return try dbQueue.read { db in
            let rows = try UsageEvent.fetchAll(
                db, sql: "SELECT * FROM usage_events WHERE ts >= ?", arguments: [startTs])
            return rows.filter { includedSources?.contains($0.source) ?? true }.map {
                UsageSample(model: $0.model, inputTokens: $0.inputTokens,
                            outputTokens: $0.outputTokens, messageCount: $0.messageCount,
                            minutesActive: $0.minutesActive)
            }
        }
    }

    // MARK: - Daily race history

    func saveDailySummary(day: String, aiMlLow: Double, aiMlMid: Double, aiMlHigh: Double,
                          userMl: Int, winner: String) throws {
        try dbQueue.write { db in
            let summary = DailySummary(day: day, aiMlLow: aiMlLow, aiMlMid: aiMlMid,
                                       aiMlHigh: aiMlHigh, userMl: userMl, winner: winner)
            try summary.save(db)
        }
    }

    func recentDailySummaries(limit: Int = 14) throws -> [DailySummary] {
        try dbQueue.read { db in
            try DailySummary.fetchAll(
                db,
                sql: "SELECT * FROM daily_summary ORDER BY day DESC LIMIT ?",
                arguments: [max(1, min(limit, 366))]
            )
        }
    }

    // MARK: - Local usage ingestion

    func sourceCursor(path: String) throws -> SourceCursor? {
        try dbQueue.read { db in try SourceCursor.fetchOne(db, key: path) }
    }

    /// Insert normalized metadata and advance its file cursor atomically. Duplicate external IDs
    /// are ignored, making restarts and rescans safe.
    func commitIngestion(events: [NormalizedUsageEvent], cursor: SourceCursor) throws {
        try dbQueue.write { db in
            for event in events {
                try db.execute(sql: """
                    INSERT OR IGNORE INTO usage_events
                      (ts, source, model, input_tokens, output_tokens, accuracy_tier, external_id)
                    VALUES (?, ?, ?, ?, ?, ?, ?)
                    """, arguments: [
                        Int64(event.timestamp.timeIntervalSince1970), event.source, event.model,
                        event.inputTokens, event.outputTokens, event.accuracyTier, event.externalID
                    ])
            }
            try cursor.save(db)
        }
    }

    func sourceEventSummary(source: String) throws -> (count: Int, lastEvent: Date?) {
        try dbQueue.read { db in
            let count = try Int.fetchOne(
                db, sql: "SELECT COUNT(*) FROM usage_events WHERE source = ?", arguments: [source]
            ) ?? 0
            let lastTimestamp = try Int64.fetchOne(
                db, sql: "SELECT MAX(ts) FROM usage_events WHERE source = ?", arguments: [source]
            )
            return (count, lastTimestamp.map { Date(timeIntervalSince1970: TimeInterval($0)) })
        }
    }

    // MARK: - Provider usage sync

    func providerSyncRecord(_ provider: UsageProvider) throws -> ProviderSyncRecord? {
        try dbQueue.read { db in try ProviderSyncRecord.fetchOne(db, key: provider.rawValue) }
    }

    func commitProviderSync(provider: UsageProvider, events: [NormalizedUsageEvent], at date: Date) throws {
        try dbQueue.write { db in
            for event in events {
                try db.execute(sql: """
                    INSERT INTO usage_events
                      (ts, source, model, input_tokens, output_tokens, accuracy_tier, external_id)
                    VALUES (?, ?, ?, ?, ?, ?, ?)
                    ON CONFLICT(external_id) DO UPDATE SET
                      ts = excluded.ts,
                      source = excluded.source,
                      model = excluded.model,
                      input_tokens = excluded.input_tokens,
                      output_tokens = excluded.output_tokens,
                      accuracy_tier = excluded.accuracy_tier
                    """, arguments: [
                        Int64(event.timestamp.timeIntervalSince1970), event.source, event.model,
                        event.inputTokens, event.outputTokens, event.accuracyTier, event.externalID
                    ])
            }
            let timestamp = Int64(date.timeIntervalSince1970)
            let record = ProviderSyncRecord(provider: provider.rawValue,
                                            lastAttemptTs: timestamp,
                                            lastSuccessTs: timestamp,
                                            lastError: nil,
                                            importedEvents: events.count)
            try record.save(db)
        }
    }

    func recordProviderSyncFailure(provider: UsageProvider, message: String, at date: Date) throws {
        try dbQueue.write { db in
            var record = try ProviderSyncRecord.fetchOne(db, key: provider.rawValue)
                ?? ProviderSyncRecord(provider: provider.rawValue, lastAttemptTs: nil,
                                      lastSuccessTs: nil, lastError: nil, importedEvents: 0)
            record.lastAttemptTs = Int64(date.timeIntervalSince1970)
            record.lastError = message
            try record.save(db)
        }
    }
}
