import SwiftUI
import QuenchEngine

struct SettingsView: View {
    @ObservedObject var store: RaceStore
    @StateObject private var credentials = ProviderCredentialsModel()

    var body: some View {
        TabView {
            GeneralSettingsView(store: store)
                .tabItem { Label("Estimation", systemImage: "slider.horizontal.3") }
            ProviderSettingsView(model: credentials)
                .tabItem { Label("Providers", systemImage: "key.fill") }
            HistorySettingsView(store: store)
                .tabItem { Label("History", systemImage: "calendar") }
            DiagnosticsView(store: store)
                .tabItem { Label("Diagnostics", systemImage: "stethoscope") }
        }
        .frame(width: 540, height: 460)
    }
}

private struct HistorySettingsView: View {
    @ObservedObject var store: RaceStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Daily race history").font(.headline)
                        Text("Standard-mode estimates keep winners comparable across days.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Label("\(store.userWinStreak) day streak", systemImage: "flame.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(store.userWinStreak > 0 ? .orange : .secondary)
                }

                if store.recentHistory.isEmpty {
                    ContentUnavailableView(
                        "No race history yet", systemImage: "calendar.badge.clock",
                        description: Text("Quench will save a private daily summary on this Mac.")
                    )
                } else {
                    ForEach(store.recentHistory) { item in
                        GroupBox {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.day).font(.callout.weight(.semibold))
                                    Text("You \(item.userMl) mL • AI \(Int(item.aiMl)) mL")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Label(winnerLabel(item.winner), systemImage: winnerIcon(item.winner))
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(winnerColor(item.winner))
                            }
                            .padding(3)
                        }
                    }
                }
            }
            .padding(20)
        }
    }

    private func winnerLabel(_ winner: String) -> String {
        switch winner { case "user": "You won"; case "ai": "AI won"; default: "Tie" }
    }
    private func winnerIcon(_ winner: String) -> String {
        switch winner { case "user": "checkmark.circle.fill"; case "ai": "cpu"; default: "equal.circle" }
    }
    private func winnerColor(_ winner: String) -> Color {
        switch winner { case "user": .blue; case "ai": .orange; default: .secondary }
    }
}

private struct ProviderSettingsView: View {
    @ObservedObject var model: ProviderCredentialsModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Provider usage APIs")
                        .font(.headline)
                    Text("Optional Tier 1 sources provide exact organization token totals. Admin keys stay in macOS Keychain and are sent only to their own provider.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                ProviderCredentialCard(
                    provider: .openAI,
                    title: "OpenAI",
                    detail: "Requires an organization Admin API key. Verification requests today's hourly usage grouped by model.",
                    documentationURL: URL(string: "https://developers.openai.com/api/reference/resources/admin/subresources/organization/subresources/usage")!,
                    model: model
                )
                OpenRouterReceiptCard(model: model)
                ProviderCredentialCard(
                    provider: .anthropic,
                    title: "Anthropic",
                    detail: "Requires an organization Admin API key. Verification requests today's usage grouped by model.",
                    documentationURL: URL(string: "https://platform.claude.com/docs/en/api/admin/usage_report/retrieve_messages")!,
                    model: model
                )

                Label("Verification sends only a time range and grouping request. It never sends prompts, responses, local paths, or keys to Quench servers.",
                      systemImage: "lock.shield")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Label("If the same API traffic is also present in a local tool log, disable one overlapping source to avoid double-counting.",
                      systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(20)
        }
    }
}

private struct OpenRouterReceiptCard: View {
    @ObservedObject var model: ProviderCredentialsModel
    @State private var credential = ""
    @State private var generationID = ""

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("OpenRouter").font(.callout.weight(.semibold))
                    Spacer()
                    Text(isStored ? "Key saved" : "Not connected")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(isStored ? .blue : .secondary)
                }
                Text("OpenRouter has no documented bulk history API. Quench can import exact token metadata for a generation ID without reading its prompt or response.")
                    .font(.caption).foregroundStyle(.secondary)
                SecureField("OpenRouter API key", text: $credential)
                    .textFieldStyle(.roundedBorder).privacySensitive()
                HStack {
                    Link("Generation API documentation", destination: URL(string: "https://openrouter.ai/docs/api/api-reference/generations/get-generation")!)
                        .font(.caption)
                    Spacer()
                    if isStored { Button("Remove", role: .destructive) { model.remove(.openRouter) } }
                    Button("Save key") {
                        let value = credential
                        credential = ""
                        model.saveAndVerify(value, for: .openRouter)
                    }
                    .disabled(credential.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                HStack {
                    TextField("Generation ID", text: $generationID).textFieldStyle(.roundedBorder)
                    Button("Import receipt") {
                        let value = generationID
                        generationID = ""
                        model.importOpenRouterGeneration(id: value)
                    }
                    .disabled(!isStored || generationID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .buttonStyle(.borderedProminent)
                }
                if let message = model.openRouterImportMessage {
                    Text(message).font(.caption).foregroundStyle(.secondary)
                }
            }
            .padding(4)
        }
    }

    private var isStored: Bool {
        switch model.state(for: .openRouter) {
        case .disconnected: false
        default: true
        }
    }
}

private struct ProviderCredentialCard: View {
    let provider: UsageProvider
    let title: String
    let detail: String
    let documentationURL: URL
    @ObservedObject var model: ProviderCredentialsModel
    @State private var credential = ""

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(title).font(.callout.weight(.semibold))
                    Spacer()
                    Label(stateLabel, systemImage: stateIcon)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(stateColor)
                }
                Text(detail).font(.caption).foregroundStyle(.secondary)
                SecureField("Admin API key", text: $credential)
                    .textFieldStyle(.roundedBorder)
                    .privacySensitive()
                HStack {
                    Link("API documentation", destination: documentationURL)
                        .font(.caption)
                    Spacer()
                    if isStored {
                        Button("Remove", role: .destructive) { model.remove(provider) }
                    }
                    Button("Save & verify") {
                        let value = credential
                        credential = ""
                        model.saveAndVerify(value, for: provider)
                    }
                    .disabled(credential.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isChecking)
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(4)
        }
    }

    private var state: ProviderCredentialState { model.state(for: provider) }
    private var isChecking: Bool { if case .checking = state { true } else { false } }
    private var isStored: Bool {
        switch state {
        case .saved, .checking, .verified, .failed: true
        case .disconnected: false
        }
    }
    private var stateLabel: String {
        switch state {
        case .disconnected: "Not connected"
        case .saved: "Saved in Keychain"
        case .checking: "Verifying…"
        case .verified(let count): "Verified • \(count) groups"
        case .failed(let message): message
        }
    }
    private var stateIcon: String {
        switch state {
        case .disconnected: "minus.circle"
        case .saved: "key.fill"
        case .checking: "arrow.triangle.2.circlepath"
        case .verified: "checkmark.circle.fill"
        case .failed: "exclamationmark.triangle.fill"
        }
    }
    private var stateColor: Color {
        switch state {
        case .disconnected: .secondary
        case .saved: .blue
        case .checking: .blue
        case .verified: .green
        case .failed: .orange
        }
    }
}

private struct GeneralSettingsView: View {
    @ObservedObject var store: RaceStore

    var body: some View {
        Form {
            Section("Estimation") {
                Picker("Water scope", selection: $store.waterMode) {
                    ForEach(WaterMode.allCases, id: \.self) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                Text(store.waterMode.explanation)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Picker("Electricity region", selection: $store.region) {
                    ForEach(store.regionOptions) { option in
                        Text(option.label).tag(option.id)
                    }
                }
                Text("Region changes the water intensity of the electricity behind AI inference.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Privacy") {
                Label("Quench reads token counts and model names, never prompts or responses.",
                      systemImage: "hand.raised.fill")
                    .font(.callout)
                Text("All current usage ingestion and water calculation happens on this Mac.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Gentle nudges") {
                Toggle("Hydration notifications", isOn: store.gentleNotificationsBinding)
                Text("Opt-in, passive, and silent. At most two per day between 10:00 and 18:00, only when AI is at least 250 mL ahead. macOS Focus settings remain in control.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Local sources") {
                Toggle("Claude Code", isOn: $store.claudeCodeEnabled)
                Toggle("Codex", isOn: $store.codexEnabled)
                Toggle("Browser companion", isOn: $store.browserExtensionEnabled)
                Text("Disabled sources are not scanned. Previously normalized counts remain in your local history.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Count in today's race") {
                Toggle("Claude Code logs", isOn: store.bindingForCountedSource("claude-code"))
                Toggle("Codex logs", isOn: store.bindingForCountedSource("codex"))
                Toggle("Browser companion", isOn: store.bindingForCountedSource("browser-extension"))
                Toggle("OpenAI API", isOn: store.bindingForCountedSource("openai-api"))
                Toggle("Anthropic API", isOn: store.bindingForCountedSource("anthropic-api"))
                Toggle("OpenRouter receipts", isOn: store.bindingForCountedSource("openrouter-api"))
                Text("If local logs and a provider API describe the same requests, count only one source. Disabling a source keeps its private history on this Mac but removes it from race totals.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding(.top, 8)
    }
}

private struct DiagnosticsView: View {
    @ObservedObject var store: RaceStore

    var body: some View {
        ScrollView {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Local source health")
                        .font(.headline)
                    Text("Only privacy-safe counts are shown. Log paths and content stay hidden.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(action: { store.refresh(forceProviderSync: true) }) {
                    if store.isRefreshing {
                        ProgressView().controlSize(.small)
                    } else {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                }
                .disabled(store.isRefreshing)
            }

            if store.sourceStatuses.isEmpty {
                ContentUnavailableView("Checking sources", systemImage: "magnifyingglass",
                                       description: Text("Quench is looking for supported local logs."))
            } else {
                ForEach(store.sourceStatuses) { source in
                    DiagnosticSourceCard(source: source)
                }
            }

            Text("Provider sync")
                .font(.headline)
            ForEach(store.providerSyncStatuses) { status in
                ProviderSyncCard(status: status)
            }

            Divider()
            HStack {
                Label("Methodology \(store.coefficientsVersion)", systemImage: "function")
                Spacer()
                Text("\(store.waterMode.displayName) • \(store.selectedRegionLabel)")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(20)
        }
    }
}

private struct ProviderSyncCard: View {
    let status: ProviderSyncStatus

    var body: some View {
        GroupBox {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                VStack(alignment: .leading, spacing: 2) {
                    Text(providerName).font(.caption.weight(.semibold))
                    Text(detail).font(.caption2).foregroundStyle(.secondary)
                }
                Spacer()
                if let success = status.lastSuccess {
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("Last synced").font(.caption2).foregroundStyle(.secondary)
                        Text(success, style: .relative).font(.caption.weight(.medium))
                    }
                }
            }
            .padding(4)
        }
    }

    private var providerName: String {
        switch status.provider {
        case .openAI: "OpenAI"
        case .anthropic: "Anthropic"
        case .openRouter: "OpenRouter"
        }
    }
    private var detail: String {
        switch status.state {
        case .notConfigured: "Not configured • add an Admin key in Providers"
        case .synced: "\(status.importedEvents) model buckets imported"
        case .manual: status.message ?? "Receipt import ready"
        case .failed: status.message ?? "Sync failed"
        }
    }
    private var icon: String {
        switch status.state {
        case .notConfigured: "minus.circle"
        case .synced: "checkmark.circle.fill"
        case .manual: "doc.badge.plus"
        case .failed: "exclamationmark.triangle.fill"
        }
    }
    private var color: Color {
        switch status.state {
        case .notConfigured: .secondary
        case .synced: .green
        case .manual: .blue
        case .failed: .orange
        }
    }
}

private struct DiagnosticSourceCard: View {
    let source: LocalSourceStatus

    var body: some View {
        GroupBox {
            HStack {
                SourceStatusRow(source: source)
                Divider().frame(height: 28)
                metric("Files", source.fileCount)
                metric("Events", source.eventCount)
                metric("Errors", source.errorCount)
                if let lastEvent = source.lastEvent {
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("Last usage").font(.caption2).foregroundStyle(.secondary)
                        Text(lastEvent, style: .relative).font(.caption.weight(.medium))
                    }
                    .frame(minWidth: 72, alignment: .trailing)
                }
            }
            .padding(4)
        }
    }

    private func metric(_ label: String, _ value: Int) -> some View {
        VStack(spacing: 1) {
            Text("\(value)").font(.caption.weight(.semibold))
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(minWidth: 38)
    }
}

extension WaterMode {
    var displayName: String {
        switch self {
        case .conservative: "Conservative"
        case .standard: "Standard"
        case .full: "Full footprint"
        }
    }

    var explanation: String {
        switch self {
        case .conservative: "Scope 1 — on-site data-center cooling water only."
        case .standard: "Scopes 1 + 2 — cooling plus water used to generate electricity."
        case .full: "Scopes 1 + 2 plus an explicit lifecycle and embodied-water allowance."
        }
    }
}
