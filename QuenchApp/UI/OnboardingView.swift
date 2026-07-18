import SwiftUI
import QuenchEngine

struct OnboardingView: View {
    @ObservedObject var store: RaceStore

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                BuddyStageView(theme: store.theme, activity: .idle, compact: true)
                    .frame(width: 74, height: 74)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Welcome to Quench")
                        .font(.title3.weight(.bold))
                    Text("You vs. your AI — measured honestly")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Picker("Choose your buddy", selection: $store.theme) {
                ForEach(QuenchTheme.allCases) { theme in
                    Label(theme.name, systemImage: theme.symbol).tag(theme)
                }
            }
            .accessibilityHint("Changes the always-visible animated character and color theme")

            OnboardingPoint(icon: "lock.shield.fill", title: "Private by design",
                            detail: "Only model names, timestamps, and token counts are kept. Never prompts or responses.")
            OnboardingPoint(icon: "chart.line.uptrend.xyaxis", title: "Estimates with context",
                            detail: "Every result has a scope and electricity region. You can change both in Settings.")

            VStack(alignment: .leading, spacing: 7) {
                Text("Local sources")
                    .font(.caption.weight(.semibold))
                if store.sourceStatuses.isEmpty {
                    HStack {
                        ProgressView().controlSize(.small)
                        Text("Checking Claude Code, Codex, and browser receipts…")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    ForEach(store.sourceStatuses) { source in
                        SourceStatusRow(source: source)
                    }
                }
            }

            Button(action: store.completeOnboarding) {
                Label("Start the race with \(store.theme.buddyName)", systemImage: "flag.checkered")
                    .frame(maxWidth: .infinity)
            }
            .controlSize(.large)
            .buttonStyle(.borderedProminent)
            .tint(store.theme.accent)
        }
    }
}

private struct OnboardingPoint: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.callout.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
