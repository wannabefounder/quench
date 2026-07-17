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

/// Observable state for the daily race. M1: AI side is hardcoded.
final class RaceStore: ObservableObject {
    @Published var userMl: Int = 0
    let aiMl: Double = 800          // M1 placeholder; WaterMath takes over in M2
    let goalMl: Double = 2000

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

    func refresh() {
        userMl = (try? AppDatabase.shared.todayUserMl()) ?? 0
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
