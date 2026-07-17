import SwiftUI
import QuenchEngine

/// Single horizontal race bar: user's blue fill from the left, AI marker line.
struct RaceBarView: View {
    let userMl: Double
    let aiMl: Double
    let goalMl: Double

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let userW = w * RaceEngine.userFillFraction(userMl: userMl, aiMl: aiMl, goalMl: goalMl)
            let aiX = w * RaceEngine.aiMarkerFraction(userMl: userMl, aiMl: aiMl, goalMl: goalMl)
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.secondary.opacity(0.15))
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.blue.gradient)
                    .frame(width: max(userW, userMl > 0 ? 8 : 0))
                Rectangle()
                    .fill(Color.orange)
                    .frame(width: 2)
                    .offset(x: max(aiX - 1, 0))
            }
        }
        .frame(height: 14)
        .animation(.spring(response: 0.4), value: userMl)
    }
}
