import XCTest
@testable import QuenchEngine

final class WrappedInsightsTests: XCTestCase {
    private var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = TimeZone(identifier: "Asia/Kolkata")!
        return value
    }

    func testWeeklySummaryIncludesOnlySevenCalendarDays() {
        let now = DateComponents(calendar: calendar, year: 2026, month: 7, day: 18).date!
        let result = WrappedInsights.summarize([
            .init(day: "2026-07-18", userMl: 2000, aiMl: 500, winner: "user"),
            .init(day: "2026-07-17", userMl: 1800, aiMl: 1900, winner: "tie"),
            .init(day: "2026-07-12", userMl: 1000, aiMl: 500, winner: "user"),
            .init(day: "2026-07-11", userMl: 9000, aiMl: 9000, winner: "ai")
        ], period: .week, asOf: now, calendar: calendar)
        XCTAssertEqual(result.trackedDays, 3)
        XCTAssertEqual(result.userMl, 4800)
        XCTAssertEqual(result.aiMl, 2900)
        XCTAssertEqual(result.userWinDays, 2)
        XCTAssertEqual(result.winRate, 67)
    }

    func testEmptyWrappedSummaryIsStable() {
        let result = WrappedInsights.summarize([], period: .year)
        XCTAssertEqual(result.trackedDays, 0)
        XCTAssertEqual(result.winRate, 0)
        XCTAssertEqual(result.streak, HydrationStreak(winDays: 0, freezeDaysUsed: 0))
    }

    func testRelatableComparisonsScaleFromCupsToShowers() {
        XCTAssertEqual(WrappedInsights.relatableComparison(aiMl: 250), "≈ 1 cup")
        XCTAssertEqual(WrappedInsights.relatableComparison(aiMl: 1_500), "≈ 2 reusable bottles")
        XCTAssertEqual(WrappedInsights.relatableComparison(aiMl: 130_000),
                       "≈ 2 five-minute showers")
    }

    func testPrivatePledgeScalesWithAILiters() {
        XCTAssertEqual(WrappedInsights.pledgeAmount(aiMl: 4_200, amountPerLiter: 10),
                       42, accuracy: 1e-9)
        XCTAssertEqual(WrappedInsights.pledgeAmount(aiMl: 4_200, amountPerLiter: 0), 0)
    }
}
