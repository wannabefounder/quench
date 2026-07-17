import SwiftUI
import QuenchEngine

struct MenuContentView: View {
    @ObservedObject var store: RaceStore

    var body: some View {
        Group {
            if store.hasCompletedOnboarding {
                dashboard
            } else {
                OnboardingView(store: store)
            }
        }
        .padding(14)
        .frame(width: 300)
        .onAppear { store.refresh() }
    }

    private var dashboard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("\(store.userMl) \(Strings.mlSuffix)", systemImage: "person.fill")
                    .foregroundStyle(.blue)
                Spacer()
                Label("\(Int(store.aiMl)) \(Strings.mlSuffix)", systemImage: "cpu")
                    .foregroundStyle(.orange)
            }
            .font(.system(.body, design: .rounded).weight(.semibold))

            Text("\(store.waterMode.displayName) • \(store.selectedRegionLabel)")
                .font(.caption2)
                .foregroundStyle(.secondary)

            RaceBarView(userMl: Double(store.userMl), aiMl: store.aiMl, goalMl: store.goalMl)

            Text(statusLine)
                .font(.callout)
                .foregroundStyle(.secondary)

            Button(action: { store.logWater(ml: 250) }) {
                Label(Strings.logGlass, systemImage: "drop.fill")
                    .frame(maxWidth: .infinity)
            }
            .controlSize(.large)
            .buttonStyle(.borderedProminent)

            Divider()

            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    Text(Strings.sources)
                        .font(.caption.weight(.semibold))
                    Spacer()
                    if store.isRefreshing {
                        ProgressView().controlSize(.small)
                    }
                }

                ForEach(store.sourceStatuses) { source in
                    SourceStatusRow(source: source)
                }
            }

            Divider()

            HStack {
                Text(Strings.estimateNote)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Spacer()
                SettingsLink {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(.plain)
                .help(Strings.settings)
                Button(Strings.quit) { NSApp.terminate(nil) }
                    .buttonStyle(.plain)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var statusLine: String {
        switch RaceEngine.state(userMl: Double(store.userMl), aiMl: store.aiMl) {
        case .userAhead: return Strings.userAhead
        case .aiAhead: return Strings.aiAhead
        case .tied: return Strings.tied
        }
    }
}

struct SourceStatusRow: View {
    let source: LocalSourceStatus

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 14)
            VStack(alignment: .leading, spacing: 1) {
                Text(source.displayName)
                    .font(.caption)
                Text(detail)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
            Text(stateLabel)
                .font(.caption2.weight(.medium))
                .foregroundStyle(color)
        }
        .accessibilityElement(children: .combine)
    }

    private var stateLabel: String {
        switch source.state {
        case .disabled: Strings.disabled
        case .tracking: Strings.tracking
        case .watching: Strings.watching
        case .notFound: Strings.notFound
        case .needsAttention: Strings.needsAttention
        }
    }

    private var icon: String {
        switch source.state {
        case .disabled: "pause.circle"
        case .tracking: "checkmark.circle.fill"
        case .watching: "eye.circle"
        case .notFound: "minus.circle"
        case .needsAttention: "exclamationmark.triangle.fill"
        }
    }

    private var color: Color {
        switch source.state {
        case .disabled: .secondary
        case .tracking: .green
        case .watching: .blue
        case .notFound: .secondary
        case .needsAttention: .orange
        }
    }

    private var detail: String {
        if !source.isEnabled { return "Turn on in Settings" }
        if source.eventCount > 0 { return "\(source.eventCount) usage events" }
        if source.fileCount > 0 { return "\(source.fileCount) log files found" }
        return "No supported local logs"
    }
}
