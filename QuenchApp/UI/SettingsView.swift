import SwiftUI
import QuenchEngine

struct SettingsView: View {
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
        }
        .formStyle(.grouped)
        .frame(width: 480, height: 330)
        .navigationTitle("Quench Settings")
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
