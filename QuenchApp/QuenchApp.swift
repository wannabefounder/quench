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

private struct RefreshPayload: @unchecked Sendable {
    let userMl: Int
    let aiMl: Double
    let sourceStatuses: [LocalSourceStatus]
    let providerStatuses: [ProviderSyncStatus]
}

/// Observable state for the daily race. AI water is computed by WaterMath from today's usage events.
@MainActor
final class RaceStore: ObservableObject {
    @Published var userMl: Int = 0
    @Published var aiMl: Double = 0     // Standard-mode water from today's AI usage (0 until M3+ sources feed events)
    @Published var sourceStatuses: [LocalSourceStatus] = []
    @Published var providerSyncStatuses: [ProviderSyncStatus] = []
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
    @Published var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
        }
    }
    @Published var claudeCodeEnabled: Bool {
        didSet {
            UserDefaults.standard.set(claudeCodeEnabled, forKey: "claudeCodeEnabled")
            refresh()
        }
    }
    @Published var codexEnabled: Bool {
        didSet {
            UserDefaults.standard.set(codexEnabled, forKey: "codexEnabled")
            refresh()
        }
    }
    @Published var browserExtensionEnabled: Bool {
        didSet {
            UserDefaults.standard.set(browserExtensionEnabled, forKey: "browserExtensionEnabled")
            refresh()
        }
    }
    @Published var countedSources: Set<String> {
        didSet {
            UserDefaults.standard.set(Array(countedSources), forKey: "countedSources")
            refresh()
        }
    }
    let goalMl: Double = 2000

    private let coef: Coefficients
    private let logIngestor = LocalLogIngestor()
    private let providerSync = ProviderSyncService()
    private var currentDay: String
    private var timer: Timer?
    private var needsRefresh = false
    private var credentialObserver: NSObjectProtocol?
    private var browserReceiptWatcher: BrowserReceiptWatcher?

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

    var coefficientsVersion: String { coef.version }

    init() {
        let coefficients = RaceStore.loadCoefficients()
        coef = coefficients
        waterMode = WaterMode(rawValue: UserDefaults.standard.string(forKey: "waterMode") ?? "")
            ?? .standard
        let savedRegion = UserDefaults.standard.string(forKey: "region")
        region = coefficients.water.regions[savedRegion ?? ""] != nil
            ? savedRegion! : coefficients.water.default_region
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        claudeCodeEnabled = UserDefaults.standard.object(forKey: "claudeCodeEnabled") as? Bool ?? true
        codexEnabled = UserDefaults.standard.object(forKey: "codexEnabled") as? Bool ?? true
        browserExtensionEnabled = UserDefaults.standard.object(forKey: "browserExtensionEnabled") as? Bool ?? true
        countedSources = Set(UserDefaults.standard.stringArray(forKey: "countedSources")
            ?? ["claude-code", "codex", "browser-extension", "openai-api", "anthropic-api", "openrouter-api"])
        currentDay = RaceEngine.dayKey(for: Date())
        credentialObserver = NotificationCenter.default.addObserver(
            forName: .providerCredentialsChanged, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.refresh(forceProviderSync: true) }
        }
        browserReceiptWatcher = BrowserReceiptWatcher { [weak self] in
            Task { @MainActor in self?.refresh() }
        }
        refresh()
        // Day rollover check: once a minute, reset when local midnight passes.
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.checkRollover() }
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

    func refresh(forceProviderSync: Bool = false) {
        guard !isRefreshing else {
            needsRefresh = true
            return
        }
        isRefreshing = true
        let database = AppDatabase.shared
        let ingestor = logIngestor
        let providerSynchronizer = providerSync
        let coefficients = coef
        let selectedMode = waterMode
        let selectedRegion = region
        var enabledSources = Set<String>()
        if claudeCodeEnabled { enabledSources.insert("claude-code") }
        if codexEnabled { enabledSources.insert("codex") }
        if browserExtensionEnabled { enabledSources.insert("browser-extension") }
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let sourcesCountedInRace = countedSources
        Task { [weak self] in
            let payload = await Task.detached(priority: .utility) {
                let statuses = ingestor.ingestAll(enabledSources: enabledSources)
                let providerStatuses = await providerSynchronizer.syncAll(
                    startingAt: startOfDay, force: forceProviderSync
                )
                let user = (try? database.todayUserMl()) ?? 0
                let samples = (try? database.todayUsageSamples(includedSources: sourcesCountedInRace)) ?? []
                let ai = RaceEngine.aiWaterMl(samples, mode: selectedMode,
                                              region: selectedRegion, coef: coefficients)
                return RefreshPayload(userMl: user, aiMl: ai, sourceStatuses: statuses,
                                      providerStatuses: providerStatuses)
            }.value
            guard let self else { return }
            userMl = payload.userMl
            aiMl = payload.aiMl
            sourceStatuses = payload.sourceStatuses
            providerSyncStatuses = payload.providerStatuses
            isRefreshing = false
            if needsRefresh {
                needsRefresh = false
                refresh()
            }
        }
    }

    func bindingForCountedSource(_ source: String) -> Binding<Bool> {
        Binding(
            get: { self.countedSources.contains(source) },
            set: { enabled in
                if enabled { self.countedSources.insert(source) }
                else { self.countedSources.remove(source) }
            }
        )
    }

    func logWater(ml: Int) {
        try? AppDatabase.shared.logWater(ml: ml)
        refresh()
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
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
