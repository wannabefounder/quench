import SwiftUI
import QuenchEngine

extension HydrationVessel {
    var displayName: String {
        switch self {
        case .sip: "Sip"
        case .officeCup: "Office cup"
        case .glass: "Glass"
        case .bottleSip: "1 L bottle sip"
        }
    }

    var compactName: String {
        switch self {
        case .sip: "SIP"
        case .officeCup: "CUP"
        case .glass: "GLASS"
        case .bottleSip: "BOTTLE"
        }
    }

    var symbol: String {
        switch self {
        case .sip: "drop.fill"
        case .officeCup: "cup.and.saucer.fill"
        case .glass: "mug.fill"
        case .bottleSip: "waterbottle.fill"
        }
    }

    var adjustmentStep: Int {
        switch self {
        case .sip, .bottleSip: 25
        case .officeCup, .glass: 10
        }
    }
}
