import Foundation
import QuenchEngine

struct LocalSourceStatus: Identifiable, Equatable {
    enum State { case tracking, watching, notFound, needsAttention }

    let source: String
    let displayName: String
    let fileCount: Int
    let eventCount: Int
    let errorCount: Int
    let lastEvent: Date?

    var id: String { source }
    var state: State {
        if errorCount > 0 { return .needsAttention }
        if fileCount == 0 { return .notFound }
        return eventCount > 0 ? .tracking : .watching
    }
}

/// Incrementally reads privacy-safe usage metadata from supported local JSONL logs.
final class LocalLogIngestor {
    private let database: AppDatabase
    private let fileManager: FileManager

    init(database: AppDatabase = .shared, fileManager: FileManager = .default) {
        self.database = database
        self.fileManager = fileManager
    }

    func ingestAll() -> [LocalSourceStatus] {
        let home = fileManager.homeDirectoryForCurrentUser
        return [
            ingestTree(home.appendingPathComponent(".claude/projects"),
                       source: "claude-code", displayName: "Claude Code"),
            ingestTree(home.appendingPathComponent(".codex/sessions"),
                       source: "codex", displayName: "Codex")
        ]
    }

    private func ingestTree(_ root: URL, source: String, displayName: String) -> LocalSourceStatus {
        var fileCount = 0
        var errorCount = 0
        guard let enumerator = fileManager.enumerator(
            at: root,
            includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else {
            let summary = try? database.sourceEventSummary(source: source)
            return LocalSourceStatus(source: source, displayName: displayName, fileCount: 0,
                                     eventCount: summary?.count ?? 0, errorCount: 0,
                                     lastEvent: summary?.lastEvent)
        }

        for case let url as URL in enumerator where url.pathExtension.lowercased() == "jsonl" {
            fileCount += 1
            do { try ingestFile(url, source: source) }
            catch { errorCount += 1 }
        }
        let summary = try? database.sourceEventSummary(source: source)
        return LocalSourceStatus(source: source, displayName: displayName, fileCount: fileCount,
                                 eventCount: summary?.count ?? 0, errorCount: errorCount,
                                 lastEvent: summary?.lastEvent)
    }

    private func ingestFile(_ url: URL, source: String) throws {
        let size = Int64((try url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
        var cursor = try database.sourceCursor(path: url.path) ?? SourceCursor(
            path: url.path, source: source, byteOffset: 0, generation: 0, lastModel: nil,
            cumulativeInputTokens: 0, cumulativeOutputTokens: 0
        )

        // A smaller file at the same path was truncated or rotated. Start a new cursor generation
        // so offsets remain unique without losing the old events.
        if size < cursor.byteOffset {
            cursor.byteOffset = 0
            cursor.generation += 1
            cursor.lastModel = nil
            cursor.cumulativeInputTokens = 0
            cursor.cumulativeOutputTokens = 0
        }
        guard size > cursor.byteOffset else { return }

        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        try handle.seek(toOffset: UInt64(cursor.byteOffset))
        let chunk = try handle.readToEnd() ?? Data()
        guard let finalNewline = chunk.lastIndex(of: 0x0A) else { return }
        let complete = chunk[chunk.startIndex...finalNewline]

        var events: [NormalizedUsageEvent] = []
        var codex = CodexLogParser(
            model: cursor.lastModel,
            cumulativeInputTokens: cursor.cumulativeInputTokens,
            cumulativeOutputTokens: cursor.cumulativeOutputTokens
        )
        var relativeOffset = 0

        for rawLine in complete.split(separator: 0x0A, omittingEmptySubsequences: false) {
            defer { relativeOffset += rawLine.count + 1 }
            guard !rawLine.isEmpty else { continue }
            let externalID = "\(url.path)#\(cursor.generation):\(cursor.byteOffset + Int64(relativeOffset))"
            let line = Data(rawLine)
            if source == "claude-code" {
                if let event = ClaudeCodeLogParser.parse(line: line, externalID: externalID) {
                    events.append(event)
                }
            } else if let event = codex.parse(line: line, externalID: externalID) {
                events.append(event)
            }
        }

        cursor.byteOffset += Int64(finalNewline - chunk.startIndex + 1)
        cursor.lastModel = codex.currentModel
        cursor.cumulativeInputTokens = codex.cumulativeInputTokens
        cursor.cumulativeOutputTokens = codex.cumulativeOutputTokens
        try database.commitIngestion(events: events, cursor: cursor)
    }
}
