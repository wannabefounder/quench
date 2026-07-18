import Foundation

/// A deliberately simple, non-medical pacing aid. The goal is user-selected; Quench only spreads
/// it across daytime hours and never claims that one volume fits every person.
public enum HydrationPacing {
    public static let dayStartHour = 8
    public static let dayEndHour = 20
    public static let meaningfulGapMl = 250.0

    public static func expectedMl(now: Date, goalMl: Double,
                                  calendar: Calendar = .current) -> Double {
        guard goalMl > 0,
              let start = calendar.date(bySettingHour: dayStartHour, minute: 0, second: 0, of: now),
              let end = calendar.date(bySettingHour: dayEndHour, minute: 0, second: 0, of: now)
        else { return 0 }
        if now <= start { return 0 }
        if now >= end { return goalMl }
        let progress = now.timeIntervalSince(start) / end.timeIntervalSince(start)
        return goalMl * min(max(progress, 0), 1)
    }

    public static func shouldNudge(now: Date, userMl: Double, goalMl: Double,
                                   calendar: Calendar = .current) -> Bool {
        let hour = calendar.component(.hour, from: now)
        guard (dayStartHour..<dayEndHour).contains(hour), userMl < goalMl else { return false }
        return expectedMl(now: now, goalMl: goalMl, calendar: calendar) - userMl >= meaningfulGapMl
    }

    public static func remainingMl(userMl: Double, goalMl: Double) -> Double {
        max(0, goalMl - userMl)
    }
}
