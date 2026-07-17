import SwiftUI
import QuenchEngine

@main
struct QuenchApp: App {
    @StateObject private var store = RaceStore()

    var body: some Scene {
        MenuBarExtra {
            MenuContentView(store: store)
        } label: {
            Image(systemName: store.userMl >= Int(store.goalMl) ? "drop.fill" : "drop")
        }
        .menuBarExtraStyle(.window)
    }
}

/// Observable state for the daily race. AI water is computed by WaterMath from today's usage events.
final class RaceStore: ObservableObject {
    @Published var userMl: Int = 0
    @Published var aiMl: Double = 0     // Standard-mode water from today's AI usage (0 until M3+ sources feed events)
    let goalMl: Double = 2000

    private let coef: Coefficients = RaceStore.loadCoefficients()
    private var currentDay: String
    private var timer: Timer?

    init() {
        currentDay = RaceEngine.dayKey(for: Date())
        refresh()
        // Day rollover check: once a minute, reset when local midnight passes.
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.checkRollover()
        }
    }

    /// Load bundled coefficients.json; fall back to the built-in defaults if missing/corrupt.
    static func loadCoefficients() -> Coefficients {
        if let url = Bundle.main.url(forResource: "coefficients", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let c = try? Coefficients.load(from: data) {
            return c
        }
        return .fallback
    }

    func refresh() {
        userMl = (try? AppDatabase.shared.todayUserMl()) ?? 0
        let samples = (try? AppDatabase.shared.todayUsageSamples()) ?? []
        aiMl = RaceEngine.aiWaterMl(samples, coef: coef)
    }

    func logWater(ml: Int) {
        try? AppDatabase.shared.logWater(ml: ml)
        refresh()
    }

    private func checkRollover() {
        let day = RaceEngine.dayKey(for: Date())
        if day != currentDay {
            currentDay = day
            refresh()
        }
    }
}
