import AppKit
import SwiftUI
import QuenchEngine

@MainActor
final class FloatingStatusPanelController {
    static let shared = FloatingStatusPanelController()
    private var panel: NSPanel?
    private weak var store: RaceStore?

    func attach(to store: RaceStore) {
        self.store = store
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
            PixelBuddy(theme: store.theme, activity: store.buddyActivity)
                .frame(width: 42, height: 42)

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

private struct PixelBuddy: View {
    let theme: QuenchTheme
    let activity: BuddyActivity

    private let face: [[Int]] = [
        [0, 1, 1, 1, 1, 0],
        [1, 1, 1, 1, 1, 1],
        [1, 2, 1, 1, 2, 1],
        [1, 1, 1, 1, 1, 1],
        [1, 1, 3, 3, 1, 1],
        [0, 1, 1, 1, 1, 0]
    ]

    var body: some View {
        GeometryReader { geometry in
            let pixel = min(geometry.size.width, geometry.size.height) / 7
            VStack(spacing: 1) {
                ForEach(face.indices, id: \.self) { row in
                    HStack(spacing: 1) {
                        ForEach(face[row].indices, id: \.self) { column in
                            Rectangle()
                                .fill(color(face[row][column]))
                                .frame(width: pixel, height: pixel)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .scaleEffect(activity == .userDrinking ? 1.08 : 1)
            .animation(.easeInOut(duration: 0.25), value: activity)
        }
        .accessibilityHidden(true)
    }

    private func color(_ code: Int) -> Color {
        switch code {
        case 1: theme.accent
        case 2: .primary
        case 3: activity == .aiDrinking ? theme.secondaryAccent : .primary
        default: .clear
        }
    }
}
