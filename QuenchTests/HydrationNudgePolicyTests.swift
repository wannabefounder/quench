import XCTest
@testable import QuenchEngine

final class HydrationNudgePolicyTests: XCTestCase {
    private var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = TimeZone(identifier: "Asia/Kolkata")!
        return value
    }

    private func date(hour: Int) -> Date {
        DateComponents(calendar: calendar, year: 2026, month: 7, day: 18, hour: hour).date!
    }

    func testNudgeRequiresDaytimeAndMeaningfulLead() {
        XCTAssertFalse(HydrationNudgePolicy.shouldSend(
            now: date(hour: 9), userMl: 0, aiMl: 1000, state: nil, calendar: calendar))
        XCTAssertFalse(HydrationNudgePolicy.shouldSend(
            now: date(hour: 18), userMl: 0, aiMl: 1000, state: nil, calendar: calendar))
        XCTAssertFalse(HydrationNudgePolicy.shouldSend(
            now: date(hour: 12), userMl: 800, aiMl: 900, state: nil, calendar: calendar))
        XCTAssertTrue(HydrationNudgePolicy.shouldSend(
            now: date(hour: 12), userMl: 500, aiMl: 900, state: nil, calendar: calendar))
    }

    func testNudgeHonorsCooldownAndDailyLimit() {
        let now = date(hour: 15)
        XCTAssertFalse(HydrationNudgePolicy.shouldSend(
            now: now, userMl: 0, aiMl: 1000,
            state: .init(day: "2026-07-18", sentCount: 1,
                         lastSent: now.addingTimeInterval(-60 * 60)), calendar: calendar))
        XCTAssertFalse(HydrationNudgePolicy.shouldSend(
            now: now, userMl: 0, aiMl: 1000,
            state: .init(day: "2026-07-18", sentCount: 2, lastSent: nil), calendar: calendar))
        XCTAssertTrue(HydrationNudgePolicy.shouldSend(
            now: now, userMl: 0, aiMl: 1000,
            state: .init(day: "2026-07-17", sentCount: 2, lastSent: now), calendar: calendar))
    }
}
