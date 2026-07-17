import Foundation
import GRDB

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
}
