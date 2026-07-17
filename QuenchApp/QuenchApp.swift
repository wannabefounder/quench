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

        Settings {
            SettingsView(store: store)
        }
    }
}

struct RegionOption: Identifiable, Equatable {
    let id: String
    let label: String
}

/// Observable state for the daily race. AI water is computed by WaterMath from today's usage events.
final class RaceStore: ObservableObject {
    @Published var userMl: Int = 0
    @Published var aiMl: Double = 0     // Standard-mode water from today's AI usage (0 until M3+ sources feed events)
    @Published var sourceStatuses: [LocalSourceStatus] = []
    @Published var isRefreshing = false
    @Published var waterMode: WaterMode {
        didSet {
            UserDefaults.standard.set(waterMode.rawValue, forKey: "waterMode")
            refresh()
        }
    }
    @Published var region: String {
        didSet {
            UserDefaults.standard.set(region, forKey: "region")
            refresh()
        }
    }
    let goalMl: Double = 2000

    private let coef: Coefficients
    private let logIngestor = LocalLogIngestor()
    private var currentDay: String
    private var timer: Timer?
    private var needsRefresh = false

    var regionOptions: [RegionOption] {
        coef.water.regions.map { key, value in
            RegionOption(id: key, label: value.label ?? key)
        }.sorted { lhs, rhs in
            if lhs.id == coef.water.default_region { return true }
            if rhs.id == coef.water.default_region { return false }
            return lhs.label.localizedCaseInsensitiveCompare(rhs.label) == .orderedAscending
        }
    }

    var selectedRegionLabel: String {
        regionOptions.first(where: { $0.id == region })?.label ?? region
    }

    init() {
        let coefficients = RaceStore.loadCoefficients()
        coef = coefficients
        waterMode = WaterMode(rawValue: UserDefaults.standard.string(forKey: "waterMode") ?? "")
            ?? .standard
        let savedRegion = UserDefaults.standard.string(forKey: "region")
        region = coefficients.water.regions[savedRegion ?? ""] != nil
            ? savedRegion! : coefficients.water.default_region
        currentDay = RaceEngine.dayKey(for: Date())
        refresh()
        // Day rollover check: once a minute, reset when local midnight passes.
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.checkRollover()
        }
    }

    /// Load bundled coefficients.json; fall back to the built-in defaults if missing/corrupt.
    static func loadCoefficients() -> Coefficients {
        if let url = Bundle.module.url(forResource: "coefficients", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let c = try? Coefficients.load(from: data) {
            return c
        }
        return .fallback
    }

    func refresh() {
        guard !isRefreshing else {
            needsRefresh = true
            return
        }
        isRefreshing = true
        let database = AppDatabase.shared
        let ingestor = logIngestor
        let coefficients = coef
        let selectedMode = waterMode
        let selectedRegion = region
        DispatchQueue.global(qos: .utility).async { [weak self] in
            let statuses = ingestor.ingestAll()
            let user = (try? database.todayUserMl()) ?? 0
            let samples = (try? database.todayUsageSamples()) ?? []
            let ai = RaceEngine.aiWaterMl(samples, mode: selectedMode,
                                          region: selectedRegion, coef: coefficients)
            DispatchQueue.main.async {
                self?.userMl = user
                self?.aiMl = ai
                self?.sourceStatuses = statuses
                self?.isRefreshing = false
                if self?.needsRefresh == true {
                    self?.needsRefresh = false
                    self?.refresh()
                }
            }
        }
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
