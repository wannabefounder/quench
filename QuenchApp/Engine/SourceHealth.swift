import Foundation

public enum LocalSourceState: Equatable {
    case disabled
    case tracking
    case watching
    case notFound
    case needsAttention
}

/// Privacy-safe source diagnostics. File paths and parsed content never cross into the UI.
public struct LocalSourceStatus: Identifiable, Equatable {
    public let source: String
    public let displayName: String
    public let fileCount: Int
    public let eventCount: Int
    public let errorCount: Int
    public let lastEvent: Date?
    public let isEnabled: Bool
    public let itemLabel: String

    public init(source: String, displayName: String, fileCount: Int, eventCount: Int,
                errorCount: Int, lastEvent: Date?, isEnabled: Bool = true,
                itemLabel: String = "Files") {
        self.source = source
        self.displayName = displayName
        self.fileCount = fileCount
        self.eventCount = eventCount
        self.errorCount = errorCount
        self.lastEvent = lastEvent
        self.isEnabled = isEnabled
        self.itemLabel = itemLabel
    }

    public var id: String { source }
    public var state: LocalSourceState {
        if !isEnabled { return .disabled }
        if errorCount > 0 { return .needsAttention }
        if fileCount == 0 { return .notFound }
        return eventCount > 0 ? .tracking : .watching
    }
}
