import Foundation

public struct HydrationNudgeState: Equatable {
    public let day: String
    public let sentCount: Int
    public let lastSent: Date?

    public init(day: String, sentCount: Int, lastSent: Date?) {
        self.day = day
        self.sentCount = sentCount
        self.lastSent = lastSent
    }
}

public enum HydrationNudgePolicy {
    public static let minimumLeadMl = 250.0
    public static let maximumPerDay = 2
    public static let cooldown: TimeInterval = 3 * 60 * 60

    /// Nudges only during daytime, when hydration is behind a steady pace or AI is meaningfully
    /// ahead, and never more than twice. The goal is explicitly user-controlled.
    public static func shouldSend(now: Date, userMl: Double, aiMl: Double, goalMl: Double = 2_000,
                                  state: HydrationNudgeState?, calendar: Calendar = .current) -> Bool {
        let hour = calendar.component(.hour, from: now)
        let hydrationBehind = HydrationPacing.shouldNudge(
            now: now, userMl: userMl, goalMl: goalMl, calendar: calendar)
        guard (HydrationPacing.dayStartHour..<HydrationPacing.dayEndHour).contains(hour),
              hydrationBehind || aiMl - userMl >= minimumLeadMl else { return false }
        let today = RaceEngine.dayKey(for: now, calendar: calendar)
        guard state?.day == today else { return true }
        guard (state?.sentCount ?? 0) < maximumPerDay else { return false }
        if let lastSent = state?.lastSent, now.timeIntervalSince(lastSent) < cooldown { return false }
        return true
    }
}
