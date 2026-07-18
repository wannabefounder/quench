import Foundation

public enum MenuBarStatus {
    public static func stats(userMl: Int, aiMl: Double, goalMl: Double) -> String {
        "You \(compactMilliliters(Double(userMl)))/\(compactMilliliters(goalMl)) · AI \(compactMilliliters(aiMl))"
    }

    public static func aiDrank(deltaMl: Double) -> String {
        "AI just drank \(compactMilliliters(deltaMl))"
    }

    public static func sipNudge(userMl: Int, goalMl: Double) -> String {
        let remaining = HydrationPacing.remainingMl(userMl: Double(userMl), goalMl: goalMl)
        return "Sip break · \(compactMilliliters(remaining)) left"
    }

    public static func compactMilliliters(_ value: Double) -> String {
        let safeValue = max(0, value)
        if safeValue >= 1_000 {
            let liters = safeValue / 1_000
            return liters >= 10 ? "\(Int(liters.rounded())) L" : String(format: "%.1f L", liters)
        }
        return "\(Int(safeValue.rounded())) mL"
    }
}
