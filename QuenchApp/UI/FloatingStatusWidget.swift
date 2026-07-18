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
        let size = NSSize(width: 282, height: 72)
        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless, .nonactivatingPanel],
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
        panel.isMovableByWindowBackground = true
        panel.becomesKeyOnlyIfNeeded = true
        panel.isReleasedWhenClosed = false
        panel.contentView = NSHostingView(rootView: FloatingStatusWidget(store: store))
        panel.setContentSize(size)
        panel.setFrameAutosaveName("QuenchFloatingStatus")
        if !panel.setFrameUsingName("QuenchFloatingStatus") {
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
        HStack(spacing: 10) {
            Button { FloatingStatusPanelController.shared.openDashboard() } label: {
                PixelWaterDrop(theme: store.theme, activity: store.buddyActivity)
                    .frame(width: 42, height: 42)
            }
            .buttonStyle(.plain)
            .help("Open Quench")
            .accessibilityLabel("Open Quench dashboard")

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 5) {
                    Text("YOU").foregroundStyle(store.theme.accent)
                    Text("\(volume(Double(store.userMl))) / \(volume(store.goalMl))")
                }
                HStack(spacing: 5) {
                    Text("AI").foregroundStyle(store.theme.secondaryAccent)
                    Text(volume(store.aiMl))
                }
            }
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .monospacedDigit()
            .lineLimit(1)

            Spacer(minLength: 2)

            Button { store.logWater(ml: 250) } label: {
                VStack(spacing: 1) {
                    Text("+").font(.system(size: 17, weight: .black, design: .monospaced))
                    Text("250").font(.system(size: 8, weight: .bold, design: .monospaced))
                }
                .frame(width: 38, height: 38)
            }
            .buttonStyle(.plain)
            .background(store.theme.secondaryAccent.opacity(0.18), in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8)
                .stroke(store.theme.secondaryAccent.opacity(0.65), lineWidth: 1))
            .help("Log 250 mL")
            .accessibilityLabel("Log 250 milliliters")
        }
        .padding(.horizontal, 12)
        .frame(width: 282, height: 72)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 13, style: .continuous)
            .stroke(.white.opacity(0.24), lineWidth: 1))
        .accessibilityElement(children: .contain)
    }

    private func volume(_ ml: Double) -> String {
        MenuBarStatus.compactMilliliters(ml)
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
