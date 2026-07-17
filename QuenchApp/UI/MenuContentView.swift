import SwiftUI
import QuenchEngine

struct MenuContentView: View {
    @ObservedObject var store: RaceStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("\(store.userMl) \(Strings.mlSuffix)", systemImage: "person.fill")
                    .foregroundStyle(.blue)
                Spacer()
                Label("\(Int(store.aiMl)) \(Strings.mlSuffix)", systemImage: "cpu")
                    .foregroundStyle(.orange)
            }
            .font(.system(.body, design: .rounded).weight(.semibold))

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

            HStack {
                Text(Strings.estimateNote)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Spacer()
                Button(Strings.quit) { NSApp.terminate(nil) }
                    .buttonStyle(.plain)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(width: 280)
        .onAppear { store.refresh() }
    }

    private var statusLine: String {
        switch RaceEngine.state(userMl: Double(store.userMl), aiMl: store.aiMl) {
        case .userAhead: return Strings.userAhead
        case .aiAhead: return Strings.aiAhead
        case .tied: return Strings.tied
        }
    }
}
