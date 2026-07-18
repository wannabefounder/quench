import XCTest
@testable import QuenchEngine

final class HydrationPacingTests: XCTestCase {
    private var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = TimeZone(identifier: "Asia/Kolkata")!
        return value
    }

    private func date(hour: Int, minute: Int = 0) -> Date {
        DateComponents(calendar: calendar, year: 2026, month: 7, day: 18,
                       hour: hour, minute: minute).date!
    }

    func testGoalIsSpreadAcrossDaytime() {
        XCTAssertEqual(HydrationPacing.expectedMl(
            now: date(hour: 8), goalMl: 2_000, calendar: calendar), 0, accuracy: 0.01)
        XCTAssertEqual(HydrationPacing.expectedMl(
            now: date(hour: 14), goalMl: 2_000, calendar: calendar), 1_000, accuracy: 0.01)
        XCTAssertEqual(HydrationPacing.expectedMl(
            now: date(hour: 20), goalMl: 2_000, calendar: calendar), 2_000, accuracy: 0.01)
    }

    func testNudgeRequiresOneGlassGapAndDaytime() {
        XCTAssertFalse(HydrationPacing.shouldNudge(
            now: date(hour: 7), userMl: 0, goalMl: 2_000, calendar: calendar))
        XCTAssertFalse(HydrationPacing.shouldNudge(
            now: date(hour: 14), userMl: 800, goalMl: 2_000, calendar: calendar))
        XCTAssertTrue(HydrationPacing.shouldNudge(
            now: date(hour: 14), userMl: 700, goalMl: 2_000, calendar: calendar))
        XCTAssertFalse(HydrationPacing.shouldNudge(
            now: date(hour: 19), userMl: 2_000, goalMl: 2_000, calendar: calendar))
    }

    func testRemainingNeverGoesNegative() {
        XCTAssertEqual(HydrationPacing.remainingMl(userMl: 2_500, goalMl: 2_000), 0)
    }
}
