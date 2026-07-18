import SwiftUI

enum QuenchTheme: String, CaseIterable, Identifiable {
    case aquaLab
    case forestFlow
    case cosmicSip
    case solarSplash

    var id: String { rawValue }
    var name: String {
        switch self {
        case .aquaLab: "Aqua Lab"
        case .forestFlow: "Forest Flow"
        case .cosmicSip: "Cosmic Sip"
        case .solarSplash: "Solar Splash"
        }
    }
    var buddyName: String {
        switch self {
        case .aquaLab: "Axel the Axolotl"
        case .forestFlow: "Moss the Capybara"
        case .cosmicSip: "Orbit the Otter"
        case .solarSplash: "Kiko the Robot Koi"
        }
    }
    var symbol: String {
        switch self {
        case .aquaLab: "flask.fill"
        case .forestFlow: "leaf.fill"
        case .cosmicSip: "sparkles"
        case .solarSplash: "sun.max.fill"
        }
    }
    var accent: Color {
        switch self {
        case .aquaLab: .cyan
        case .forestFlow: .green
        case .cosmicSip: .purple
        case .solarSplash: .orange
        }
    }
    var secondaryAccent: Color {
        switch self {
        case .aquaLab: .blue
        case .forestFlow: .mint
        case .cosmicSip: .indigo
        case .solarSplash: .red
        }
    }
    var background: LinearGradient {
        switch self {
        case .aquaLab:
            LinearGradient(colors: [.cyan.opacity(0.18), .blue.opacity(0.08)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        case .forestFlow:
            LinearGradient(colors: [.green.opacity(0.16), .mint.opacity(0.08)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        case .cosmicSip:
            LinearGradient(colors: [.purple.opacity(0.20), .indigo.opacity(0.10)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        case .solarSplash:
            LinearGradient(colors: [.orange.opacity(0.18), .red.opacity(0.07)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

enum BuddyActivity: String, Equatable {
    case idle
    case aiDrinking
    case userDrinking
    case userAhead
    case aiAhead
    case tied

    var accessibilityDescription: String {
        switch self {
        case .idle: "waiting for the race"
        case .aiDrinking: "showing that AI usage is adding water"
        case .userDrinking: "celebrating your water entry"
        case .userAhead: "celebrating that you are ahead"
        case .aiAhead: "encouraging you because AI is ahead"
        case .tied: "cheering a tied race"
        }
    }
}
