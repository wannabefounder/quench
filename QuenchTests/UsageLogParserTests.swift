import XCTest
@testable import QuenchEngine

final class UsageLogParserTests: XCTestCase {
    func testBrowserReceiptParsesCountsWithoutContent() throws {
        let line = Data(#"{"schema_version":1,"id":"abc123","timestamp":"2026-07-18T12:00:00Z","site":"chatgpt.com","model":null,"input_tokens":120,"output_tokens":340}"#.utf8)
        let event = BrowserReceiptParser.parse(line: line)

        XCTAssertEqual(event?.externalID, "browser:abc123")
        XCTAssertEqual(event?.source, "browser-extension")
        XCTAssertEqual(event?.inputTokens, 120)
        XCTAssertEqual(event?.outputTokens, 340)
        XCTAssertEqual(event?.accuracyTier, 2)
    }

    func testBrowserReceiptRejectsUnknownSitesAndEmptyUsage() {
        XCTAssertNil(BrowserReceiptParser.parse(line: Data(#"{"schema_version":1,"id":"x","timestamp":"2026-07-18T12:00:00Z","site":"example.com","input_tokens":1,"output_tokens":1}"#.utf8)))
        XCTAssertNil(BrowserReceiptParser.parse(line: Data(#"{"schema_version":1,"id":"x","timestamp":"2026-07-18T12:00:00Z","site":"claude.ai","input_tokens":0,"output_tokens":0}"#.utf8)))
    }

    func testClaudeCodeParsesOnlyUsageMetadataAndIncludesCacheTokens() {
        let line = Data(#"{"type":"assistant","timestamp":"2026-07-18T10:20:30.123Z","message":{"id":"redacted","model":"claude-sonnet-4-5","usage":{"input_tokens":100,"cache_creation_input_tokens":20,"cache_read_input_tokens":30,"output_tokens":40},"content":[{"type":"text","text":"must never be retained"}]}}"#.utf8)

        let event = ClaudeCodeLogParser.parse(line: line, externalID: "fixture:0")

        XCTAssertEqual(event?.externalID, "fixture:0")
        XCTAssertEqual(event?.source, "claude-code")
        XCTAssertEqual(event?.model, "claude-sonnet-4-5")
        XCTAssertEqual(event?.inputTokens, 150)
        XCTAssertEqual(event?.outputTokens, 40)
        XCTAssertEqual(event?.accuracyTier, 3)
    }

    func testClaudeCodeIgnoresUserAndMalformedLines() {
        XCTAssertNil(ClaudeCodeLogParser.parse(
            line: Data(#"{"type":"user","timestamp":"2026-07-18T10:20:30Z"}"#.utf8),
            externalID: "fixture:1"))
        XCTAssertNil(ClaudeCodeLogParser.parse(line: Data("not-json".utf8), externalID: "fixture:2"))
    }

    func testCodexTracksModelAndUsesLastTurnUsage() {
        var parser = CodexLogParser()
        let context = Data(#"{"timestamp":"2026-07-18T10:20:00Z","type":"turn_context","payload":{"model":"gpt-5"}}"#.utf8)
        XCTAssertNil(parser.parse(line: context, externalID: "fixture:0"))

        let count = Data(#"{"timestamp":"2026-07-18T10:20:30Z","type":"event_msg","payload":{"type":"token_count","info":{"total_token_usage":{"input_tokens":1200,"output_tokens":300},"last_token_usage":{"input_tokens":200,"output_tokens":50}}}}"#.utf8)
        let event = parser.parse(line: count, externalID: "fixture:1")

        XCTAssertEqual(event?.source, "codex")
        XCTAssertEqual(event?.model, "gpt-5")
        XCTAssertEqual(event?.inputTokens, 200)
        XCTAssertEqual(event?.outputTokens, 50)
        XCTAssertEqual(parser.cumulativeInputTokens, 1200)
        XCTAssertEqual(parser.cumulativeOutputTokens, 300)
    }

    func testCodexFallsBackToCumulativeDelta() {
        var parser = CodexLogParser(model: "gpt-4o", cumulativeInputTokens: 100,
                                    cumulativeOutputTokens: 20)
        let line = Data(#"{"timestamp":"2026-07-18T10:20:30Z","type":"event_msg","payload":{"type":"token_count","info":{"total_token_usage":{"input_tokens":180,"output_tokens":45}}}}"#.utf8)
        let event = parser.parse(line: line, externalID: "fixture:2")
        XCTAssertEqual(event?.inputTokens, 80)
        XCTAssertEqual(event?.outputTokens, 25)
    }

    func testCodexIgnoresUnrelatedAndZeroDeltaEvents() {
        var parser = CodexLogParser(cumulativeInputTokens: 10, cumulativeOutputTokens: 5)
        let unrelated = Data(#"{"timestamp":"2026-07-18T10:20:30Z","type":"event_msg","payload":{"type":"task_started"}}"#.utf8)
        XCTAssertNil(parser.parse(line: unrelated, externalID: "fixture:3"))
        let same = Data(#"{"timestamp":"2026-07-18T10:20:31Z","type":"event_msg","payload":{"type":"token_count","info":{"total_token_usage":{"input_tokens":10,"output_tokens":5}}}}"#.utf8)
        XCTAssertNil(parser.parse(line: same, externalID: "fixture:4"))
    }
}
