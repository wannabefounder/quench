import SwiftUI

struct RaceBarView: View {
    let userMl: Double
    let aiMl: Double
    let goalMl: Double
    let theme: QuenchTheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var scale: Double { max(userMl, aiMl, goalMl, 1) }

    var body: some View {
        VStack(spacing: 10) {
            lane(label: "YOU", value: userMl, color: theme.accent, icon: "person.fill")
            lane(label: "EST. AI", value: aiMl, color: theme.secondaryAccent, icon: "cpu")
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Race progress. You: \(Int(userMl)) milliliters. Estimated AI water: \(Int(aiMl)) milliliters.")
    }

    private func lane(label: String, value: Double, color: Color, icon: String) -> some View {
        HStack(spacing: 9) {
            Label(label, systemImage: icon)
                .font(.caption2.weight(.bold))
                .frame(width: 65, alignment: .leading)
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(.secondary.opacity(0.13))
                    Capsule().fill(color.gradient)
                        .frame(width: max(value > 0 ? 7 : 0, geometry.size.width * value / scale))
                }
            }
            .frame(height: 10)
            Text(volume(value))
                .font(.caption.monospacedDigit().weight(.semibold))
                .frame(width: 58, alignment: .trailing)
        }
        .animation(reduceMotion ? nil : .spring(duration: 0.55, bounce: 0.2), value: value)
    }

    private func volume(_ ml: Double) -> String {
        ml >= 1000 ? String(format: "%.1f L", ml / 1000) : "\(Int(ml)) mL"
    }
}
