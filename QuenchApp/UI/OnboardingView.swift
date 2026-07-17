import SwiftUI
import QuenchEngine

struct OnboardingView: View {
    @ObservedObject var store: RaceStore

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "drop.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.blue.gradient)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Welcome to Quench")
                        .font(.headline)
                    Text("You vs. your AI — measured honestly")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

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
                        Text("Checking for Claude Code and Codex…")
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
                Text("Start the race")
                    .frame(maxWidth: .infinity)
            }
            .controlSize(.large)
            .buttonStyle(.borderedProminent)
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
