import XCTest
@testable import QuenchEngine

final class ProviderUsageTests: XCTestCase {
    func testOpenAIUsagePageNormalizesHourlyModelBuckets() throws {
        let data = Data(#"{"data":[{"start_time":1763452800,"end_time":1763456400,"results":[{"input_tokens":1000,"output_tokens":250,"input_cached_tokens":400,"num_model_requests":3,"model":"gpt-5"}]}],"has_more":true,"next_page":"page_2"}"#.utf8)
        let page = try ProviderUsageParser.openAI(data)

        XCTAssertEqual(page.nextPage, "page_2")
        XCTAssertEqual(page.events.count, 1)
        XCTAssertEqual(page.events[0].source, "openai-api")
        XCTAssertEqual(page.events[0].model, "gpt-5")
        XCTAssertEqual(page.events[0].inputTokens, 1000)
        XCTAssertEqual(page.events[0].outputTokens, 250)
        XCTAssertEqual(page.events[0].accuracyTier, 1)
    }

    func testOpenAIStopsPaginationWhenHasMoreIsFalse() throws {
        let data = Data(#"{"data":[],"has_more":false,"next_page":"ignored"}"#.utf8)
        XCTAssertNil(try ProviderUsageParser.openAI(data).nextPage)
    }

    func testAnthropicIncludesEveryInputTokenClass() throws {
        let data = Data(#"{"data":[{"starting_at":"2026-07-18T00:00:00Z","ending_at":"2026-07-18T01:00:00Z","results":[{"uncached_input_tokens":1500,"cache_creation":{"ephemeral_1h_input_tokens":1000,"ephemeral_5m_input_tokens":500},"cache_read_input_tokens":200,"output_tokens":500,"model":"claude-sonnet-4"}]}],"has_more":false,"next_page":null}"#.utf8)
        let page = try ProviderUsageParser.anthropic(data)

        XCTAssertEqual(page.events.count, 1)
        XCTAssertEqual(page.events[0].source, "anthropic-api")
        XCTAssertEqual(page.events[0].inputTokens, 3200)
        XCTAssertEqual(page.events[0].outputTokens, 500)
        XCTAssertEqual(page.events[0].accuracyTier, 1)
        XCTAssertNil(page.nextPage)
    }

    func testMalformedProviderResponsesThrow() {
        XCTAssertThrowsError(try ProviderUsageParser.openAI(Data("{}".utf8)))
        XCTAssertThrowsError(try ProviderUsageParser.anthropic(Data("not-json".utf8)))
    }
}
