import Foundation

private struct BrowserReceipt: Codable {
    let schemaVersion: Int
    let id: String
    let timestamp: String
    let site: String
    let model: String?
    let inputTokens: Int
    let outputTokens: Int

    enum CodingKeys: String, CodingKey {
        case id, timestamp, site, model
        case schemaVersion = "schema_version"
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
    }

    var isValid: Bool {
        schemaVersion == 1
            && (1...200).contains(id.count)
            && ["chatgpt.com", "claude.ai"].contains(site)
            && inputTokens >= 0 && outputTokens >= 0
            && inputTokens + outputTokens > 0
            && inputTokens <= 50_000_000 && outputTokens <= 50_000_000
            && (model?.count ?? 0) <= 200
            && Self.parseTimestamp(timestamp) != nil
    }

    private static func parseTimestamp(_ raw: String) -> Date? {
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return fractional.date(from: raw) ?? ISO8601DateFormatter().date(from: raw)
    }
}

private struct BridgeReply: Codable {
    let accepted: Bool
    let error: String?
}

private let input = FileHandle.standardInput
private let output = FileHandle.standardOutput
private let decoder = JSONDecoder()
private let encoder = JSONEncoder()

private func readExactly(_ count: Int) throws -> Data? {
    var result = Data()
    while result.count < count {
        guard let chunk = try input.read(upToCount: count - result.count), !chunk.isEmpty else {
            return result.isEmpty ? nil : result
        }
        result.append(chunk)
    }
    return result
}

private func reply(_ value: BridgeReply) throws {
    let payload = try encoder.encode(value)
    var length = UInt32(payload.count).littleEndian
    try output.write(contentsOf: Data(bytes: &length, count: MemoryLayout<UInt32>.size))
    try output.write(contentsOf: payload)
}

private func append(_ receipt: BrowserReceipt) throws {
    let override = ProcessInfo.processInfo.environment["QUENCH_BRIDGE_INBOX"]
    let url: URL
    if let override, !override.isEmpty {
        url = URL(fileURLWithPath: override)
    } else {
        url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Quench", isDirectory: true)
            .appendingPathComponent("browser-events.jsonl")
    }
    let directory = url.deletingLastPathComponent()
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    var line = try encoder.encode(receipt)
    line.append(0x0A)
    if !FileManager.default.fileExists(atPath: url.path) {
        guard FileManager.default.createFile(atPath: url.path, contents: nil,
                                             attributes: [.posixPermissions: 0o600]) else {
            throw CocoaError(.fileWriteUnknown)
        }
    }
    let handle = try FileHandle(forWritingTo: url)
    defer { try? handle.close() }
    try handle.seekToEnd()
    try handle.write(contentsOf: line)
}

while let header = try readExactly(4) {
    guard header.count == 4 else { break }
    let bytes = [UInt8](header)
    let length = Int(UInt32(bytes[0]) | UInt32(bytes[1]) << 8
        | UInt32(bytes[2]) << 16 | UInt32(bytes[3]) << 24)
    guard length > 0, length <= 1_048_576,
          let payload = try readExactly(length), payload.count == length else {
        try reply(BridgeReply(accepted: false, error: "Invalid message length."))
        continue
    }
    do {
        let receipt = try decoder.decode(BrowserReceipt.self, from: payload)
        guard receipt.isValid else {
            try reply(BridgeReply(accepted: false, error: "Receipt validation failed."))
            continue
        }
        try append(receipt)
        try reply(BridgeReply(accepted: true, error: nil))
    } catch {
        try reply(BridgeReply(accepted: false, error: "Unsupported receipt."))
    }
}
