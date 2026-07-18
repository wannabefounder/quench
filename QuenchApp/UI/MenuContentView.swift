import AppKit
import SwiftUI
import QuenchEngine

struct MenuContentView: View {
    @ObservedObject var store: RaceStore
    @Environment(\.openSettings) private var openSettings
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Group {
            if store.hasCompletedOnboarding { dashboard }
            else { OnboardingView(store: store) }
        }
        .padding(16)
        .frame(width: 370)
        .background(store.theme.background)
        .onAppear { store.refresh() }
        .task {
            FloatingStatusPanelController.shared.attach(to: store) {
                openWindow(id: "dashboard")
            }
        }
    }

    private var dashboard: some View {
        VStack(alignment: .leading, spacing: 13) {
            header
            hero
            raceCard
            actionRow
            sourceSummary
            footer
        }
    }

    private var header: some View {
        HStack(spacing: 9) {
            Image(systemName: store.theme.symbol)
                .foregroundStyle(store.theme.accent)
                .font(.headline)
            VStack(alignment: .leading, spacing: 0) {
                Text("Quench").font(.headline)
                Text("You vs. Your AI").font(.caption2).foregroundStyle(.secondary)
            }
            Spacer()
            Picker("Theme", selection: $store.theme) {
                ForEach(QuenchTheme.allCases) { theme in
                    Label(theme.name, systemImage: theme.symbol).tag(theme)
                }
            }
            .labelsHidden()
            .frame(maxWidth: 135)
            .accessibilityLabel("Character theme")
        }
    }

    private var hero: some View {
        HStack(spacing: 14) {
            BuddyStageView(theme: store.theme, activity: store.buddyActivity)
                .frame(width: 138, height: 128)
            VStack(alignment: .leading, spacing: 6) {
                Text(store.theme.buddyName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(store.theme.accent)
                Text(buddyHeadline)
                    .font(.title3.weight(.bold))
                    .fixedSize(horizontal: false, vertical: true)
                Text(buddyDetail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                if store.buddyActivity == .aiDrinking {
                    Label("AI usage just added water", systemImage: "waveform.path.ecg")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(store.theme.secondaryAccent)
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var raceCard: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack {
                Text("TODAY'S RACE").font(.caption2.weight(.bold)).foregroundStyle(.secondary)
                Spacer()
                Text("\(store.waterMode.displayName) • \(store.selectedRegionLabel)")
                    .font(.caption2).foregroundStyle(.secondary)
            }
            RaceBarView(userMl: Double(store.userMl), aiMl: store.aiMl,
                        goalMl: store.goalMl, theme: store.theme)
            HStack(spacing: 5) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                Text("Estimated range")
                Spacer()
                Text("\(volume(store.aiMlLow)) – \(volume(store.aiMlHigh))")
                    .monospacedDigit()
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
            .help("Scope 1 cooling through the Full lifecycle allowance. The selected scope remains the race value.")
            .accessibilityElement(children: .combine)
            .accessibilityLabel("AI water estimate range, \(volume(store.aiMlLow)) to \(volume(store.aiMlHigh)). The selected \(store.waterMode.displayName) estimate is \(volume(store.aiMl)).")
            HStack {
                Label("Daily fluid goal", systemImage: "target")
                Spacer()
                Text("\(MenuBarStatus.compactMilliliters(Double(store.userMl))) of \(MenuBarStatus.compactMilliliters(store.goalMl))")
                    .monospacedDigit()
            }
            .font(.caption.weight(.semibold))
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Daily fluid goal. \(store.userMl) of \(Int(store.goalMl)) milliliters logged.")
            HStack(spacing: 8) {
                statChip(icon: "flame.fill", text: "\(store.userWinStreak) day streak")
                if let model = store.thirstiestModel {
                    statChip(icon: "drop.triangle.fill", text: "Top: \(model.model)")
                }
                if store.streakFreezeDaysUsed > 0 {
                    statChip(icon: "snowflake", text: "Freeze used")
                }
            }
        }
        .padding(13)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.22)))
    }

    private var actionRow: some View {
        Button(action: { store.logDrink(.glass) }) {
            HStack {
                Image(systemName: "plus.circle.fill").font(.title3)
                VStack(alignment: .leading, spacing: 0) {
                    Text("Log glass · \(store.drinkAmount(for: .glass)) mL")
                        .font(.body.weight(.bold))
                    Text("Shift-Command-D").font(.caption2).opacity(0.75)
                }
                Spacer()
                Image(systemName: "drop.fill")
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 3)
        }
        .controlSize(.large)
        .buttonStyle(.borderedProminent)
        .tint(store.theme.secondaryAccent)
        .keyboardShortcut("d", modifiers: [.command, .shift])
        .help("Log your calibrated glass while the Quench menu is open")
        .accessibilityHint("Adds \(store.drinkAmount(for: .glass)) milliliters to today's private water log")
    }

    private var sourceSummary: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text("LIVE SOURCES").font(.caption2.weight(.bold)).foregroundStyle(.secondary)
                Spacer()
                if store.isRefreshing { ProgressView().controlSize(.mini) }
                else { Text("Content never leaves this Mac").font(.caption2).foregroundStyle(.tertiary) }
            }
            ForEach(store.sourceStatuses.prefix(4)) { source in SourceStatusRow(source: source) }
        }
    }

    private var footer: some View {
        HStack {
            Label("Estimated locally", systemImage: "lock.fill")
                .font(.caption2).foregroundStyle(.tertiary)
            Spacer()
            Button {
                NSApp.activate(ignoringOtherApps: true)
                openSettings()
            } label: { Label("Settings", systemImage: "gearshape") }
            .buttonStyle(.plain)
            .font(.caption)
            .help("Open Quench Settings")
            .accessibilityHint("Opens the Quench Settings window and brings it forward")
            Button("Quit") { NSApp.terminate(nil) }
                .buttonStyle(.plain).font(.caption).foregroundStyle(.secondary)
        }
    }

    private func statChip(icon: String, text: String) -> some View {
        Label(text, systemImage: icon)
            .font(.caption2.weight(.semibold))
            .lineLimit(1)
            .padding(.horizontal, 8).padding(.vertical, 5)
            .background(store.theme.accent.opacity(0.1), in: Capsule())
            .accessibilityLabel(text)
    }

    private func volume(_ ml: Double) -> String {
        MenuBarStatus.compactMilliliters(ml)
    }

    private var buddyHeadline: String {
        switch store.buddyActivity {
        case .aiDrinking: "Your AI is drinking."
        case .userDrinking: "Nice sip!"
        case .userAhead: "You're leading."
        case .aiAhead: "AI is ahead."
        case .tied: "Neck and neck."
        case .idle: "Race ready."
        }
    }
    private var buddyDetail: String {
        switch store.buddyActivity {
        case .aiDrinking: "The estimate moved with new usage—not conversation content."
        case .userDrinking: "Your glass is in the race. Keep the rhythm easy."
        case .userAhead: "You're out-drinking today's estimated AI footprint."
        case .aiAhead: "A glass puts you closer. No guilt, just a friendly race."
        case .tied: "One small sip can move the race."
        case .idle: "Use AI normally. Quench will keep score privately."
        }
    }
}

struct SourceStatusRow: View {
    let source: LocalSourceStatus

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon).foregroundStyle(color).frame(width: 14)
            VStack(alignment: .leading, spacing: 1) {
                Text(source.displayName).font(.caption)
                Text(detail).font(.caption2).foregroundStyle(.tertiary)
            }
            Spacer()
            Label(stateLabel, systemImage: stateSymbol)
                .labelStyle(.titleAndIcon)
                .font(.caption2.weight(.medium)).foregroundStyle(color)
        }
        .accessibilityElement(children: .combine)
    }

    private var stateLabel: String {
        switch source.state {
        case .disabled: Strings.disabled; case .tracking: Strings.tracking
        case .watching: Strings.watching; case .notFound: Strings.notFound
        case .needsAttention: Strings.needsAttention
        }
    }
    private var stateSymbol: String {
        switch source.state {
        case .disabled: "pause.fill"; case .tracking: "checkmark"
        case .watching: "eye.fill"; case .notFound: "minus"
        case .needsAttention: "exclamationmark"
        }
    }
    private var icon: String {
        switch source.state {
        case .disabled: "pause.circle"; case .tracking: "checkmark.circle.fill"
        case .watching: "eye.circle"; case .notFound: "minus.circle"
        case .needsAttention: "exclamationmark.triangle.fill"
        }
    }
    private var color: Color {
        switch source.state {
        case .disabled, .notFound: .secondary; case .tracking: .green
        case .watching: .blue; case .needsAttention: .orange
        }
    }
    private var detail: String {
        if !source.isEnabled { return "Turn on in Settings" }
        if source.source == "activity-proxy" { return "Rough foreground-time estimate" }
        if source.eventCount > 0 { return "\(source.eventCount) usage events" }
        if source.fileCount > 0 { return "\(source.fileCount) log files found" }
        return "No supported local logs"
    }
}
