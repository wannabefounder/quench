import Foundation

public enum WrappedPeriod: Int, CaseIterable, Hashable {
    case week = 7
    case month = 30
    case year = 365

    public var title: String {
        switch self { case .week: "Weekly"; case .month: "Monthly"; case .year: "Yearly" }
    }
}

public struct DailyWaterSummary: Equatable {
    public let day: String
    public let userMl: Int
    public let aiMl: Double
    public let winner: String

    public init(day: String, userMl: Int, aiMl: Double, winner: String) {
        self.day = day; self.userMl = userMl; self.aiMl = aiMl; self.winner = winner
    }
}

public struct WrappedSummary: Equatable {
    public let period: WrappedPeriod
    public let trackedDays: Int
    public let userMl: Int
    public let aiMl: Double
    public let userWinDays: Int
    public let streak: HydrationStreak

    public var winRate: Int {
        guard trackedDays > 0 else { return 0 }
        return Int((Double(userWinDays) / Double(trackedDays) * 100).rounded())
    }

    public init(period: WrappedPeriod, trackedDays: Int, userMl: Int, aiMl: Double,
                userWinDays: Int, streak: HydrationStreak) {
        self.period = period; self.trackedDays = trackedDays; self.userMl = userMl
        self.aiMl = aiMl; self.userWinDays = userWinDays; self.streak = streak
    }
}

public enum WrappedInsights {
    public static func summarize(_ daysNewestFirst: [DailyWaterSummary], period: WrappedPeriod,
                                 asOf now: Date = Date(), calendar: Calendar = .current) -> WrappedSummary {
        let today = calendar.startOfDay(for: now)
        let earliest = calendar.date(byAdding: .day, value: -(period.rawValue - 1), to: today) ?? today
        let included = daysNewestFirst.filter { summary in
            guard let date = date(fromDayKey: summary.day, calendar: calendar) else { return false }
            return date >= earliest && date <= today
        }
        let streak = RaceEngine.hydrationStreak(included.map {
            RaceDayResult(day: $0.day, winner: $0.winner)
        }, asOf: now, calendar: calendar)
        return WrappedSummary(
            period: period,
            trackedDays: included.count,
            userMl: included.reduce(0) { $0 + $1.userMl },
            aiMl: included.reduce(0) { $0 + $1.aiMl },
            userWinDays: included.filter { $0.winner == "user" }.count,
            streak: streak
        )
    }

    private static func date(fromDayKey key: String, calendar: Calendar) -> Date? {
        let parts = key.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
    }
}
