import XCTest
@testable import QuenchEngine

final class HistoryInsightsTests: XCTestCase {
    func testThirstiestModelAggregatesCoefficientFamilies() {
        let samples = [
            UsageSample(model: "openai/gpt-5", inputTokens: 100, outputTokens: 300),
            UsageSample(model: "gpt-5-2026-07", inputTokens: 100, outputTokens: 300),
            UsageSample(model: "claude-haiku", inputTokens: 5, outputTokens: 5)
        ]
        let result = HistoryInsights.thirstiestModel(samples, coef: .fallback)
        XCTAssertEqual(result?.model, "gpt-5")
        XCTAssertGreaterThan(result?.waterMl ?? 0, 0)
    }

    func testThirstiestModelReturnsNilWithoutMeasurableUsage() {
        XCTAssertNil(HistoryInsights.thirstiestModel([], coef: .fallback))
        XCTAssertNil(HistoryInsights.thirstiestModel(
            [UsageSample(model: "gpt-5")], coef: .fallback
        ))
    }
}
