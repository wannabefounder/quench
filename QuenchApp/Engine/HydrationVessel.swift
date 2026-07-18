import Foundation

/// User-calibrated quick-add actions. Defaults are practical starting points, not medical facts.
public enum HydrationVessel: String, CaseIterable, Hashable, Sendable {
    case sip
    case officeCup
    case glass
    case bottleSip

    public var defaultMl: Int {
        switch self {
        case .sip: 50
        case .officeCup: 180
        case .glass: 250
        case .bottleSip: 100
        }
    }

    public var allowedMl: ClosedRange<Int> {
        switch self {
        case .sip, .bottleSip: 25...500
        case .officeCup, .glass: 100...500
        }
    }

    public func clamped(_ milliliters: Int) -> Int {
        min(max(milliliters, allowedMl.lowerBound), allowedMl.upperBound)
    }
}
