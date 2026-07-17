import SwiftUI
import QuenchEngine

struct SettingsView: View {
    @ObservedObject var store: RaceStore

    var body: some View {
        TabView {
            GeneralSettingsView(store: store)
                .tabItem { Label("Estimation", systemImage: "slider.horizontal.3") }
            DiagnosticsView(store: store)
                .tabItem { Label("Diagnostics", systemImage: "stethoscope") }
        }
        .frame(width: 520, height: 390)
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

            Section("Local sources") {
                Toggle("Claude Code", isOn: $store.claudeCodeEnabled)
                Toggle("Codex", isOn: $store.codexEnabled)
                Text("Disabled sources are not scanned. Previously normalized counts remain in your local history.")
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
                Button(action: store.refresh) {
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

            Spacer()
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
