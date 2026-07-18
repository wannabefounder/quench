import AppKit
import SwiftUI
import QuenchEngine

@MainActor
final class FloatingStatusPanelController {
    static let shared = FloatingStatusPanelController()
    private var panel: NSPanel?
    private weak var store: RaceStore?
    private var openDashboardAction: (() -> Void)?

    func attach(to store: RaceStore, openDashboard: @escaping () -> Void) {
        self.store = store
        openDashboardAction = openDashboard
        setVisible(store.floatingWidgetEnabled)
    }

    func setVisible(_ visible: Bool) {
        guard visible else {
            panel?.orderOut(nil)
            return
        }
        guard let store else { return }
        if panel == nil { panel = makePanel(store: store) }
        panel?.orderFrontRegardless()
    }

    func openDashboard() {
        NSApp.activate(ignoringOtherApps: true)
        let dashboard = NSApp.windows.first {
            $0 !== panel && $0.title == "Quench" && $0.styleMask.contains(.titled)
        }
        if let dashboard {
            dashboard.makeKeyAndOrderFront(nil)
        } else {
            openDashboardAction?()
        }
    }

    private func makePanel(store: RaceStore) -> NSPanel {
        let size = NSSize(width: 480, height: 240)
        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.titled, .fullSizeContentView, .nonactivatingPanel, .resizable],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.standardWindowButton(.closeButton)?.isHidden = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true
        panel.isMovableByWindowBackground = true
        panel.becomesKeyOnlyIfNeeded = true
        panel.isReleasedWhenClosed = false
        panel.contentMinSize = NSSize(width: 340, height: 124)
        panel.contentMaxSize = NSSize(width: 640, height: 360)
        panel.contentView = NSHostingView(rootView: FloatingStatusWidget(store: store)
            .frame(minWidth: 340, maxWidth: 640, minHeight: 124, maxHeight: 360))
        panel.setContentSize(size)
        let frameName = "QuenchFloatingStatusV3"
        panel.setFrameAutosaveName(frameName)
        if !panel.setFrameUsingName(frameName) {
            positionAtTopRight(panel, size: size)
        }
        return panel
    }

    private func positionAtTopRight(_ panel: NSPanel, size: NSSize) {
        guard let visible = NSScreen.main?.visibleFrame else {
            panel.center()
            return
        }
        panel.setFrameOrigin(NSPoint(
            x: visible.maxX - size.width - 18,
            y: visible.maxY - size.height - 18
        ))
    }
}

private struct FloatingStatusWidget: View {
    @ObservedObject var store: RaceStore

    var body: some View {
        GeometryReader { proxy in
            Group {
                if proxy.size.height < 170 || proxy.size.width < 410 {
                    compactInstrument
                } else {
                    expandedInstrument(showDetail: proxy.size.height >= 240)
                }
            }
            .padding(proxy.size.height < 170 ? 10 : 14)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(instrumentBackground)
        }
        .accessibilityElement(children: .contain)
    }

    private var compactInstrument: some View {
        VStack(spacing: 9) {
            HStack(spacing: 9) {
                dropButton(size: 38)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Q//HYDRATION").instrumentLabel(size: 10)
                    Text("YOU \(volume(Double(store.userMl)))/\(volume(store.goalMl))  ·  AI≈\(volume(store.aiMl))")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
                Spacer(minLength: 2)
                Text("\(progressPercent)%")
                    .font(.system(size: 18, weight: .black, design: .monospaced))
                    .foregroundStyle(store.theme.accent)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(statusAccessibility)
            quickAddStrip(compact: true)
        }
    }

    private func expandedInstrument(showDetail: Bool) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                dropButton(size: 44)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 7) {
                        Text("Q//01 HYDRATION UNIT").instrumentLabel(size: 10)
                        Circle().fill(.green).frame(width: 6, height: 6)
                        Text("LIVE").instrumentLabel(size: 8).foregroundStyle(.green)
                    }
                    Text("\(store.waterMode.displayName.uppercased())  /  \(store.selectedRegionLabel.uppercased())")
                        .instrumentLabel(size: 8).foregroundStyle(.white.opacity(0.48))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 0) {
                    Text("\(progressPercent)%")
                        .font(.system(size: 22, weight: .black, design: .monospaced))
                        .foregroundStyle(store.theme.accent)
                    Text("DAILY TARGET").instrumentLabel(size: 7)
                }
            }

            HStack(spacing: 12) {
                instrumentChannel(
                    label: "HUMAN INPUT",
                    value: "\(volume(Double(store.userMl))) / \(volume(store.goalMl))",
                    fraction: store.goalMl > 0 ? Double(store.userMl) / store.goalMl : 0,
                    color: store.theme.accent
                )
                instrumentChannel(
                    label: "AI WATER ≈",
                    value: volume(store.aiMl),
                    detail: "RANGE \(volume(store.aiMlLow))–\(volume(store.aiMlHigh))",
                    fraction: store.aiMlHigh > 0 ? store.aiMl / store.aiMlHigh : 0,
                    color: store.theme.secondaryAccent
                )
            }

            quickAddStrip(compact: false)

            if showDetail {
                HStack {
                    Label(raceStatus, systemImage: raceSymbol)
                    Spacer()
                    Text("DRAG TO MOVE  ·  EDGES TO RESIZE")
                }
                .instrumentLabel(size: 8)
                .foregroundStyle(.white.opacity(0.46))
            }
        }
    }

    private func dropButton(size: CGFloat) -> some View {
        Button { FloatingStatusPanelController.shared.openDashboard() } label: {
            PixelWaterDrop(theme: store.theme, activity: store.buddyActivity)
                .frame(width: size, height: size)
                .padding(5)
                .background(.black.opacity(0.38), in: RoundedRectangle(cornerRadius: 9))
                .overlay(RoundedRectangle(cornerRadius: 9)
                    .stroke(store.theme.accent.opacity(0.55), lineWidth: 1))
        }
        .buttonStyle(InstrumentButtonStyle())
        .help("Open Quench")
        .accessibilityLabel("Open Quench dashboard")
    }

    private func quickAddStrip(compact: Bool) -> some View {
        HStack(spacing: compact ? 5 : 7) {
            ForEach(HydrationVessel.allCases, id: \.self) { vessel in
                Button { store.logDrink(vessel) } label: {
                    HStack(spacing: compact ? 3 : 5) {
                        Image(systemName: vessel.symbol)
                            .font(.system(size: compact ? 9 : 11, weight: .bold))
                        VStack(alignment: .leading, spacing: 0) {
                            Text(vessel.compactName)
                                .font(.system(size: compact ? 7 : 8, weight: .black, design: .monospaced))
                            Text("+\(store.drinkAmount(for: vessel))")
                                .font(.system(size: compact ? 9 : 11, weight: .bold, design: .monospaced))
                                .monospacedDigit()
                        }
                    }
                    .foregroundStyle(Color(red: 0.08, green: 0.09, blue: 0.09))
                    .frame(maxWidth: .infinity, minHeight: compact ? 34 : 40)
                    .background(Color(red: 0.88, green: 0.87, blue: 0.78),
                                in: RoundedRectangle(cornerRadius: 7))
                    .overlay(alignment: .top) {
                        Rectangle().fill(store.theme.accent).frame(height: 3)
                            .clipShape(.rect(topLeadingRadius: 7, topTrailingRadius: 7))
                    }
                }
                .buttonStyle(InstrumentButtonStyle())
                .help("Log \(store.drinkAmount(for: vessel)) mL for \(vessel.displayName.lowercased())")
                .accessibilityLabel("Log \(store.drinkAmount(for: vessel)) milliliters, \(vessel.displayName)")
            }
        }
    }

    private func instrumentChannel(label: String, value: String, detail: String? = nil,
                                   fraction: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(label).instrumentLabel(size: 8)
                Spacer()
                Text(value)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                    .monospacedDigit()
            }
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle().fill(.white.opacity(0.09))
                    Rectangle().fill(color.gradient)
                        .frame(width: geometry.size.width * min(max(fraction, 0), 1))
                }
            }
            .frame(height: 7)
            if let detail {
                Text(detail).instrumentLabel(size: 7).foregroundStyle(.white.opacity(0.45))
            }
        }
        .padding(8)
        .background(.black.opacity(0.28), in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.09)))
    }

    private var instrumentBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(red: 0.07, green: 0.075, blue: 0.072))
            InstrumentGrid().stroke(.white.opacity(0.035), lineWidth: 0.5)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(store.theme.accent.opacity(0.75), lineWidth: 1.5)
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .inset(by: 5).stroke(.white.opacity(0.08), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.42), radius: 18, y: 8)
    }

    private var progressPercent: Int {
        guard store.goalMl > 0 else { return 0 }
        return min(999, Int((Double(store.userMl) / store.goalMl * 100).rounded()))
    }

    private var statusAccessibility: String {
        "You logged \(volume(Double(store.userMl))) of \(volume(store.goalMl)). " +
        "Estimated AI water is \(volume(store.aiMl)), with a range from " +
        "\(volume(store.aiMlLow)) to \(volume(store.aiMlHigh))."
    }

    private var raceStatus: String {
        switch RaceEngine.state(userMl: Double(store.userMl), aiMl: store.aiMl) {
        case .userAhead: "HUMAN LEADING"
        case .aiAhead: "AI LEADING · TAKE A SIP"
        case .tied: "RACE EVEN"
        }
    }

    private var raceSymbol: String {
        switch RaceEngine.state(userMl: Double(store.userMl), aiMl: store.aiMl) {
        case .userAhead: "arrow.up.right"
        case .aiAhead: "drop.fill"
        case .tied: "equal"
        }
    }

    private func volume(_ ml: Double) -> String {
        MenuBarStatus.compactMilliliters(ml)
    }
}

private struct InstrumentGrid: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        stride(from: rect.minX, through: rect.maxX, by: 20).forEach { x in
            path.move(to: CGPoint(x: x, y: rect.minY))
            path.addLine(to: CGPoint(x: x, y: rect.maxY))
        }
        stride(from: rect.minY, through: rect.maxY, by: 20).forEach { y in
            path.move(to: CGPoint(x: rect.minX, y: y))
            path.addLine(to: CGPoint(x: rect.maxX, y: y))
        }
        return path
    }
}

private struct InstrumentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.72 : 1)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

private extension View {
    func instrumentLabel(size: CGFloat) -> some View {
        font(.system(size: size, weight: .bold, design: .monospaced))
            .tracking(0.8)
            .foregroundStyle(.white.opacity(0.62))
    }
}

private struct PixelWaterDrop: View {
    let theme: QuenchTheme
    let activity: BuddyActivity
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isFloating = false

    private let drop: [[Int]] = [
        [0, 0, 0, 1, 0, 0, 0],
        [0, 0, 1, 1, 1, 0, 0],
        [0, 1, 1, 2, 1, 1, 0],
        [0, 1, 2, 1, 1, 1, 0],
        [1, 1, 1, 1, 1, 1, 1],
        [1, 1, 1, 1, 1, 1, 1],
        [0, 1, 1, 1, 1, 1, 0],
        [0, 0, 1, 1, 1, 0, 0]
    ]

    var body: some View {
        GeometryReader { geometry in
            let pixel = min(geometry.size.width, geometry.size.height) / 9
            VStack(spacing: 1) {
                ForEach(drop.indices, id: \.self) { row in
                    HStack(spacing: 1) {
                        ForEach(drop[row].indices, id: \.self) { column in
                            Rectangle()
                                .fill(color(drop[row][column]))
                                .frame(width: pixel, height: pixel)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .offset(y: reduceMotion ? 0 : (isFloating ? -2 : 2))
            .scaleEffect(activity == .userDrinking ? 1.1 : 1)
            .animation(.easeInOut(duration: 0.25), value: activity)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 1.15).repeatForever(autoreverses: true)) {
                    isFloating = true
                }
            }
        }
        .accessibilityHidden(true)
    }

    private func color(_ code: Int) -> Color {
        switch code {
        case 1: activity == .aiDrinking ? theme.secondaryAccent : theme.accent
        case 2: .white.opacity(0.8)
        default: .clear
        }
    }
}
