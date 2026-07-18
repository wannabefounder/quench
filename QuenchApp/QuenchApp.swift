import SwiftUI
import QuenchEngine

@main
struct QuenchApp: App {
    @StateObject private var store = RaceStore()

    var body: some Scene {
        WindowGroup("Quench", id: "dashboard") {
            MenuContentView(store: store)
        }
        .defaultSize(width: 402, height: 650)
        .windowResizability(.contentSize)

        MenuBarExtra {
            MenuContentView(store: store)
        } label: {
            BuddyMenuBarIcon(theme: store.theme, activity: store.buddyActivity)
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

struct DailyRaceHistoryItem: Identifiable, Equatable {
    let day: String
    let userMl: Int
    let aiMl: Double
    let winner: String
    var id: String { day }
}

private struct RefreshPayload: @unchecked Sendable {
    let userMl: Int
    let aiMl: Double
    let sourceStatuses: [LocalSourceStatus]
    let providerStatuses: [ProviderSyncStatus]
    let streak: HydrationStreak
    let history: [DailyRaceHistoryItem]
    let thirstiestModel: ModelWaterTotal?
}

/// Observable state for the daily race. AI water is computed by WaterMath from today's usage events.
@MainActor
final class RaceStore: ObservableObject {
    @Published var userMl: Int = 0
    @Published var aiMl: Double = 0     // Standard-mode water from today's AI usage (0 until M3+ sources feed events)
    @Published var sourceStatuses: [LocalSourceStatus] = []
    @Published var providerSyncStatuses: [ProviderSyncStatus] = []
    @Published var isRefreshing = false
    @Published var userWinStreak = 0
    @Published var streakFreezeDaysUsed = 0
    @Published var thirstiestModel: ModelWaterTotal?
    @Published private(set) var buddyActivity: BuddyActivity = .idle
    @Published var recentHistory: [DailyRaceHistoryItem] = []
    @Published private(set) var gentleNotificationsEnabled: Bool
    @Published var theme: QuenchTheme {
        didSet { UserDefaults.standard.set(theme.rawValue, forKey: "quenchTheme") }
    }
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
    @Published var geminiCLIEnabled: Bool {
        didSet {
            UserDefaults.standard.set(geminiCLIEnabled, forKey: "geminiCLIEnabled")
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
    private let notificationService = HydrationNotificationService.makeIfAvailable()
    private var currentDay: String
    private var timer: Timer?
    private var needsRefresh = false
    private var credentialObserver: NSObjectProtocol?
    private var browserReceiptWatcher: BrowserReceiptWatcher?
    private var buddyActivityTask: Task<Void, Never>?

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

    func wrappedSummary(for period: WrappedPeriod) -> WrappedSummary {
        WrappedInsights.summarize(recentHistory.map {
            DailyWaterSummary(day: $0.day, userMl: $0.userMl, aiMl: $0.aiMl, winner: $0.winner)
        }, period: period)
    }

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
        geminiCLIEnabled = UserDefaults.standard.object(forKey: "geminiCLIEnabled") as? Bool ?? true
        browserExtensionEnabled = UserDefaults.standard.object(forKey: "browserExtensionEnabled") as? Bool ?? true
        gentleNotificationsEnabled = UserDefaults.standard.bool(forKey: "gentleNotificationsEnabled")
        theme = QuenchTheme(rawValue: UserDefaults.standard.string(forKey: "quenchTheme") ?? "")
            ?? .aquaLab
        countedSources = Set(UserDefaults.standard.stringArray(forKey: "countedSources")
            ?? ["claude-code", "codex", "gemini-cli", "browser-extension", "openai-api", "anthropic-api", "openrouter-api"])
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
        let sourceTreeURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("Resources/coefficients.json")
        let candidates = [Bundle.main.url(forResource: "coefficients", withExtension: "json"),
                          sourceTreeURL]
        for url in candidates.compactMap({ $0 }) {
            if let data = try? Data(contentsOf: url),
               let coefficients = try? Coefficients.load(from: data) {
                return coefficients
            }
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
        if geminiCLIEnabled { enabledSources.insert("gemini-cli") }
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
                let low = RaceEngine.aiWaterMl(samples, mode: .conservative,
                                               region: selectedRegion, coef: coefficients)
                let standard = RaceEngine.aiWaterMl(samples, mode: .standard,
                                                    region: selectedRegion, coef: coefficients)
                let high = RaceEngine.aiWaterMl(samples, mode: .full,
                                                region: selectedRegion, coef: coefficients)
                let ai = RaceEngine.aiWaterMl(samples, mode: selectedMode,
                                              region: selectedRegion, coef: coefficients)
                let day = RaceEngine.dayKey(for: Date())
                try? database.saveDailySummary(
                    day: day, aiMlLow: low, aiMlMid: standard, aiMlHigh: high,
                    userMl: user, winner: RaceEngine.winner(userMl: Double(user), aiMl: standard)
                )
                let summaries = (try? database.recentDailySummaries(limit: 366)) ?? []
                let streak = RaceEngine.hydrationStreak(summaries.map {
                    RaceDayResult(day: $0.day, winner: $0.winner ?? "tie")
                })
                let weekStart = Calendar.current.date(byAdding: .day, value: -6, to: startOfDay)
                    ?? startOfDay
                let weeklySamples = (try? database.usageSamples(
                    since: weekStart, includedSources: sourcesCountedInRace
                )) ?? []
                let thirstiestModel = HistoryInsights.thirstiestModel(
                    weeklySamples, region: selectedRegion, coef: coefficients
                )
                let history = summaries.map {
                    DailyRaceHistoryItem(day: $0.day, userMl: $0.userMl ?? 0,
                                         aiMl: $0.aiMlMid ?? 0, winner: $0.winner ?? "tie")
                }
                return RefreshPayload(userMl: user, aiMl: ai, sourceStatuses: statuses,
                                      providerStatuses: providerStatuses, streak: streak,
                                      history: history, thirstiestModel: thirstiestModel)
            }.value
            guard let self else { return }
            let previousAI = aiMl
            userMl = payload.userMl
            aiMl = payload.aiMl
            sourceStatuses = payload.sourceStatuses
            providerSyncStatuses = payload.providerStatuses
            userWinStreak = payload.streak.winDays
            streakFreezeDaysUsed = payload.streak.freezeDaysUsed
            recentHistory = payload.history
            thirstiestModel = payload.thirstiestModel
            if payload.aiMl > previousAI + 0.01 {
                showBuddyActivity(.aiDrinking, for: 4.5)
            } else if buddyActivity != .userDrinking && buddyActivity != .aiDrinking {
                buddyActivity = restingBuddyActivity
            }
            if gentleNotificationsEnabled {
                Task { await self.notificationService?.consider(
                    userMl: payload.userMl, aiMl: payload.aiMl
                ) }
            }
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

    var gentleNotificationsBinding: Binding<Bool> {
        Binding(
            get: { self.gentleNotificationsEnabled },
            set: { self.setGentleNotificationsEnabled($0) }
        )
    }

    private func setGentleNotificationsEnabled(_ enabled: Bool) {
        if !enabled {
            gentleNotificationsEnabled = false
            UserDefaults.standard.set(false, forKey: "gentleNotificationsEnabled")
            return
        }
        Task {
            let granted = await notificationService?.requestPermission() ?? false
            gentleNotificationsEnabled = granted
            UserDefaults.standard.set(granted, forKey: "gentleNotificationsEnabled")
            if granted { refresh() }
        }
    }

    func logWater(ml: Int) {
        try? AppDatabase.shared.logWater(ml: ml)
        showBuddyActivity(.userDrinking, for: 2.5)
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

    private var restingBuddyActivity: BuddyActivity {
        switch RaceEngine.state(userMl: Double(userMl), aiMl: aiMl) {
        case .userAhead: .userAhead
        case .aiAhead: .aiAhead
        case .tied: .tied
        }
    }

    private func showBuddyActivity(_ activity: BuddyActivity, for duration: TimeInterval) {
        buddyActivityTask?.cancel()
        buddyActivity = activity
        buddyActivityTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(duration))
            guard !Task.isCancelled, let self else { return }
            self.buddyActivity = self.restingBuddyActivity
        }
    }
}
