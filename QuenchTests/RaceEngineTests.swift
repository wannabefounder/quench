import XCTest
@testable import QuenchEngine

final class RaceEngineTests: XCTestCase {
    func testDayKeyFormat() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Kolkata")!
        // 2026-07-17 00:30 IST
        let d = DateComponents(calendar: cal, year: 2026, month: 7, day: 17, hour: 0, minute: 30).date!
        XCTAssertEqual(RaceEngine.dayKey(for: d, calendar: cal), "2026-07-17")
    }

    func testMidnightRollover() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Kolkata")!
        let before = DateComponents(calendar: cal, year: 2026, month: 7, day: 17, hour: 23, minute: 59, second: 59).date!
        let after = before.addingTimeInterval(2)
        XCTAssertNotEqual(RaceEngine.dayKey(for: before, calendar: cal), RaceEngine.dayKey(for: after, calendar: cal))
        XCTAssertFalse(RaceEngine.isSameDay(before, after, calendar: cal))
    }

    func testDSTTransitionDayKeysStable() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "America/New_York")!
        // US DST spring forward 2026-03-08; 2:30 doesn't exist, calendar resolves within same day.
        let d = DateComponents(calendar: cal, year: 2026, month: 3, day: 8, hour: 1, minute: 30).date!
        XCTAssertEqual(RaceEngine.dayKey(for: d, calendar: cal), "2026-03-08")
        let later = d.addingTimeInterval(3600 * 3)
        XCTAssertEqual(RaceEngine.dayKey(for: later, calendar: cal), "2026-03-08")
    }

    func testRaceStates() {
        XCTAssertEqual(RaceEngine.state(userMl: 0, aiMl: 0), .tied)
        XCTAssertEqual(RaceEngine.state(userMl: 1000, aiMl: 950), .tied)   // within 10%
        XCTAssertEqual(RaceEngine.state(userMl: 1000, aiMl: 500), .userAhead)
        XCTAssertEqual(RaceEngine.state(userMl: 200, aiMl: 800), .aiAhead)
    }

    func testFractionsScaleTogether() {
        // AI beyond goal: scale = ai
        XCTAssertEqual(RaceEngine.userFillFraction(userMl: 1000, aiMl: 4000, goalMl: 2000), 0.25)
        XCTAssertEqual(RaceEngine.aiMarkerFraction(userMl: 1000, aiMl: 4000, goalMl: 2000), 1.0)
        // Normal day: scale = goal
        XCTAssertEqual(RaceEngine.userFillFraction(userMl: 500, aiMl: 300, goalMl: 2000), 0.25)
    }

    func testWinnerStrings() {
        XCTAssertEqual(RaceEngine.winner(userMl: 2000, aiMl: 100), "user")
        XCTAssertEqual(RaceEngine.winner(userMl: 100, aiMl: 2000), "ai")
        XCTAssertEqual(RaceEngine.winner(userMl: 0, aiMl: 0), "tie")
    }

    func testUserWinStreakRequiresConsecutiveWins() {
        let days = [
            RaceDayResult(day: "2026-07-18", winner: "user"),
            RaceDayResult(day: "2026-07-17", winner: "user"),
            RaceDayResult(day: "2026-07-16", winner: "ai")
        ]
        XCTAssertEqual(RaceEngine.userWinStreak(days), 2)
    }

    func testUserWinStreakStopsAtMissingDayOrTie() {
        XCTAssertEqual(RaceEngine.userWinStreak([
            RaceDayResult(day: "2026-07-18", winner: "user"),
            RaceDayResult(day: "2026-07-16", winner: "user")
        ]), 1)
        XCTAssertEqual(RaceEngine.userWinStreak([
            RaceDayResult(day: "2026-07-18", winner: "tie"),
            RaceDayResult(day: "2026-07-17", winner: "user")
        ]), 0)
    }
}
