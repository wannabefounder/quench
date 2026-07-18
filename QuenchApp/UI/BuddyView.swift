import SwiftUI

struct BuddyMenuBarIcon: View {
    let theme: QuenchTheme
    let activity: BuddyActivity

    var body: some View {
        ZStack {
            Circle().fill(theme.accent.opacity(0.24))
            Circle().stroke(theme.accent, lineWidth: 1.4)
            HStack(spacing: 3) {
                Capsule().fill(.primary).frame(width: 2.5, height: 4)
                Capsule().fill(.primary).frame(width: 2.5, height: 4)
            }
            if activity == .aiDrinking {
                Circle().fill(theme.secondaryAccent).frame(width: 4, height: 4)
                    .offset(x: 7, y: -7)
            }
        }
        .frame(width: 18, height: 18)
        .accessibilityLabel("Quench, \(theme.buddyName), \(activity.accessibilityDescription)")
    }
}

struct BuddyStageView: View {
    let theme: QuenchTheme
    let activity: BuddyActivity
    var compact = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { context in
            let time = context.date.timeIntervalSinceReferenceDate
            let bob = reduceMotion ? 0 : sin(time * 2.1) * (compact ? 1.5 : 3.5)
            let celebrate = activity == .userDrinking || activity == .userAhead
            let tilt = reduceMotion ? 0 : (celebrate ? sin(time * 5.5) * 3.5 : sin(time * 1.3) * 1.2)
            let blink = !reduceMotion && Int(time * 2).isMultiple(of: 13)

            ZStack {
                ambientBackground(time: time)
                character(blink: blink, time: time)
                    .rotationEffect(.degrees(tilt))
                    .offset(y: bob)
                if activity == .aiDrinking { drinkingBubbles(time: time) }
            }
            .animation(.easeInOut(duration: 0.35), value: activity)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(theme.buddyName), \(activity.accessibilityDescription)")
    }

    @ViewBuilder
    private func character(blink: Bool, time: TimeInterval) -> some View {
        switch theme {
        case .aquaLab: AxolotlBuddy(blink: blink, activity: activity)
        case .forestFlow: CapybaraBuddy(blink: blink, activity: activity)
        case .cosmicSip: OtterBuddy(blink: blink, activity: activity)
        case .solarSplash: KoiBuddy(blink: blink, activity: activity, time: time)
        }
    }

    private func ambientBackground(time: TimeInterval) -> some View {
        ZStack {
            Circle().fill(theme.accent.opacity(0.12))
                .scaleEffect(reduceMotion ? 0.94 : 0.92 + sin(time * 1.2) * 0.025)
            ForEach(0..<4, id: \.self) { index in
                Image(systemName: index.isMultiple(of: 2) ? "drop.fill" : theme.symbol)
                    .font(.system(size: compact ? 6 : 9))
                    .foregroundStyle(theme.accent.opacity(0.25))
                    .offset(x: CGFloat([-42, 38, -30, 45][index]) * (compact ? 0.55 : 1),
                            y: CGFloat([-32, -18, 38, 29][index]) * (compact ? 0.55 : 1))
            }
        }
    }

    private func drinkingBubbles(time: TimeInterval) -> some View {
        ForEach(0..<4, id: \.self) { index in
            let progress = (time * 0.38 + Double(index) * 0.24).truncatingRemainder(dividingBy: 1)
            Circle()
                .stroke(theme.accent.opacity(1 - progress), lineWidth: 1.5)
                .frame(width: compact ? 5 : 8, height: compact ? 5 : 8)
                .offset(x: CGFloat(index * 10 - 15), y: CGFloat(36 - progress * 90))
        }
    }
}

private struct BuddyEyes: View {
    let blink: Bool
    let color: Color
    var spacing: CGFloat = 22
    var body: some View {
        HStack(spacing: spacing) {
            Capsule().fill(color).frame(width: 7, height: blink ? 1.5 : 9)
            Capsule().fill(color).frame(width: 7, height: blink ? 1.5 : 9)
        }
    }
}

private struct AxolotlBuddy: View {
    let blink: Bool
    let activity: BuddyActivity
    var body: some View {
        ZStack {
            HStack(spacing: 70) {
                gills.rotationEffect(.degrees(-18))
                gills.rotationEffect(.degrees(18)).scaleEffect(x: -1)
            }
            Ellipse().fill(LinearGradient(colors: [.cyan.opacity(0.9), .blue.opacity(0.72)],
                                          startPoint: .top, endPoint: .bottom))
                .frame(width: 92, height: 100)
                .overlay(Ellipse().stroke(.white.opacity(0.55), lineWidth: 2))
            RoundedRectangle(cornerRadius: 16).fill(.white.opacity(0.88))
                .frame(width: 74, height: 45).offset(y: 31)
                .overlay(Image(systemName: "flask.fill").foregroundStyle(.cyan).offset(y: 30))
            BuddyEyes(blink: blink, color: .black.opacity(0.78)).offset(y: -16)
            HStack(spacing: 22) {
                Circle().stroke(.black.opacity(0.55), lineWidth: 2).frame(width: 24, height: 24)
                Circle().stroke(.black.opacity(0.55), lineWidth: 2).frame(width: 24, height: 24)
            }.offset(y: -15)
            Capsule().fill(.black.opacity(0.65)).frame(width: 18, height: 3)
                .offset(y: activity == .aiAhead ? 7 : 11)
                .rotationEffect(.degrees(activity == .aiAhead ? 180 : 0))
            cup.offset(x: 45, y: 33)
        }
    }
    private var gills: some View {
        VStack(spacing: 3) {
            ForEach(0..<3) { _ in Capsule().fill(.pink.opacity(0.8)).frame(width: 28, height: 8) }
        }
    }
    private var cup: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4).fill(.cyan.opacity(0.55)).frame(width: 24, height: 30)
            Capsule().fill(.white).frame(width: 3, height: 28).rotationEffect(.degrees(18)).offset(y: -18)
        }
    }
}

private struct CapybaraBuddy: View {
    let blink: Bool
    let activity: BuddyActivity
    var body: some View {
        ZStack {
            Ellipse().fill(Color(red: 0.54, green: 0.36, blue: 0.22))
                .frame(width: 105, height: 92).offset(y: 8)
            HStack(spacing: 54) {
                Circle().fill(Color(red: 0.39, green: 0.25, blue: 0.15)).frame(width: 20)
                Circle().fill(Color(red: 0.39, green: 0.25, blue: 0.15)).frame(width: 20)
            }.offset(y: -33)
            Ellipse().fill(Color(red: 0.72, green: 0.53, blue: 0.34)).frame(width: 68, height: 48).offset(y: 4)
            BuddyEyes(blink: blink, color: .black.opacity(0.78), spacing: 25).offset(y: -16)
            Capsule().fill(.black.opacity(0.75)).frame(width: 14, height: 7).offset(y: 1)
            Image(systemName: "leaf.fill").font(.system(size: 29)).foregroundStyle(.green)
                .rotationEffect(.degrees(-18)).offset(x: 13, y: -51)
            Image(systemName: activity == .aiDrinking ? "wateringcan.fill" : "sprout.fill")
                .font(.system(size: 28)).foregroundStyle(.mint).offset(x: 49, y: 29)
        }
    }
}

private struct OtterBuddy: View {
    let blink: Bool
    let activity: BuddyActivity
    var body: some View {
        ZStack {
            Circle().fill(.indigo.opacity(0.4)).frame(width: 118)
                .overlay(Circle().stroke(.white.opacity(0.75), lineWidth: 3))
            Circle().fill(Color(red: 0.47, green: 0.29, blue: 0.20)).frame(width: 82)
            HStack(spacing: 58) {
                Circle().fill(Color(red: 0.38, green: 0.22, blue: 0.16)).frame(width: 18)
                Circle().fill(Color(red: 0.38, green: 0.22, blue: 0.16)).frame(width: 18)
            }.offset(y: -25)
            Ellipse().fill(Color(red: 0.78, green: 0.62, blue: 0.47)).frame(width: 54, height: 38).offset(y: 11)
            BuddyEyes(blink: blink, color: .white, spacing: 22).offset(y: -11)
            Circle().fill(.black.opacity(0.8)).frame(width: 10).offset(y: 5)
            Image(systemName: activity == .aiDrinking ? "drop.circle.fill" : "star.fill")
                .foregroundStyle(.yellow).offset(x: 36, y: 38)
        }
    }
}

private struct KoiBuddy: View {
    let blink: Bool
    let activity: BuddyActivity
    let time: TimeInterval
    var body: some View {
        HStack(spacing: -8) {
            KoiTailShape().fill(.orange.gradient).frame(width: 42, height: 64)
                .rotationEffect(.degrees(sin(time * 4) * (activity == .aiDrinking ? 10 : 4)))
            ZStack {
                Ellipse().fill(LinearGradient(colors: [.orange, .red.opacity(0.8)],
                                              startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 100, height: 66)
                    .overlay(Ellipse().stroke(.white.opacity(0.7), lineWidth: 2))
                HStack(spacing: 16) {
                    ForEach(0..<3) { _ in Capsule().stroke(.white.opacity(0.55), lineWidth: 2).frame(width: 20, height: 48) }
                }
                BuddyEyes(blink: blink, color: .black.opacity(0.75), spacing: 19).offset(x: 23, y: -7)
                Capsule().fill(.white.opacity(0.85)).frame(width: 17, height: 5).offset(x: 42, y: 12)
            }
        }
    }
}

private struct KoiTailShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addCurve(to: CGPoint(x: rect.minX, y: rect.minY),
                      control1: CGPoint(x: rect.midX, y: rect.midY), control2: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + 5, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addCurve(to: CGPoint(x: rect.maxX, y: rect.midY),
                      control1: CGPoint(x: rect.midX, y: rect.midY), control2: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}
