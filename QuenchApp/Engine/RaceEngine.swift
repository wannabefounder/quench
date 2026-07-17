import Foundation

/// Pure race logic. No SwiftUI, no DB. M1: day boundary + race state.
public enum RaceState: String, Equatable {
    case userAhead, aiAhead, tied
}

public enum RaceEngine {

    /// 'YYYY-MM-DD' key in the user's local calendar. Day boundary = local midnight.
    public static func dayKey(for date: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year!, c.month!, c.day!)
    }

    public static func isSameDay(_ a: Date, _ b: Date, calendar: Calendar = .current) -> Bool {
        calendar.isDate(a, inSameDayAs: b)
    }

    /// Race state. "Tied" means within 10% of each other (drives the `content` mood later).
    public static func state(userMl: Double, aiMl: Double) -> RaceState {
        if userMl == 0 && aiMl == 0 { return .tied }
        let hi = max(userMl, aiMl), lo = min(userMl, aiMl)
        if hi == 0 || (hi - lo) / hi <= 0.10 { return .tied }
        return userMl > aiMl ? .userAhead : .aiAhead
    }

    /// Fraction of the bar the user fill occupies (0...1), scaled so both fit.
    public static func userFillFraction(userMl: Double, aiMl: Double, goalMl: Double) -> Double {
        let scale = max(userMl, aiMl, goalMl, 1)
        return min(max(userMl / scale, 0), 1)
    }

    /// Position of the AI marker line on the same scale (0...1).
    public static func aiMarkerFraction(userMl: Double, aiMl: Double, goalMl: Double) -> Double {
        let scale = max(userMl, aiMl, goalMl, 1)
        return min(max(aiMl / scale, 0), 1)
    }

    /// Today's AI water (mL) from the day's usage events. Standard mode by default (Section 7).
    public static func aiWaterMl(_ samples: [UsageSample], mode: WaterMode = .standard,
                                 region: String? = nil, coef: Coefficients) -> Double {
        WaterMath.totalWaterMl(samples, mode: mode, region: region, coef: coef)
    }

    public static func winner(userMl: Double, aiMl: Double) -> String {
        switch state(userMl: userMl, aiMl: aiMl) {
        case .userAhead: return "user"
        case .aiAhead: return "ai"
        case .tied: return "tie"
        }
    }
}
