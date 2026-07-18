import AppKit
import Foundation
import QuenchEngine

/// Watches only foreground-app activation while explicitly enabled. No Accessibility permission,
/// window title, keyboard input, document, URL, or conversation content is observed.
@MainActor
final class ActivityProxyService {
    private let database: AppDatabase
    private let workspace: NSWorkspace
    private let onRecorded: () -> Void
    private var isEnabled = false
    private var activeModel: String?
    private var segmentStart: Date?
    private var observers: [NSObjectProtocol] = []
    private var timer: Timer?

    init(database: AppDatabase = .shared, workspace: NSWorkspace = .shared,
         onRecorded: @escaping () -> Void) {
        self.database = database
        self.workspace = workspace
        self.onRecorded = onRecorded
        let center = workspace.notificationCenter
        observers.append(center.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil, queue: .main
        ) { [weak self] notification in
            let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey]
                as? NSRunningApplication
            Task { @MainActor in self?.applicationActivated(app, at: Date()) }
        })
        for name in [NSWorkspace.sessionDidResignActiveNotification,
                     NSWorkspace.screensDidSleepNotification] {
            observers.append(center.addObserver(forName: name, object: nil, queue: .main) {
                [weak self] _ in Task { @MainActor in self?.pause(at: Date()) }
            })
        }
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.flush(at: Date(), continueTracking: true) }
        }
    }

    deinit {
        timer?.invalidate()
        let center = workspace.notificationCenter
        observers.forEach(center.removeObserver)
    }

    func setEnabled(_ enabled: Bool) {
        guard enabled != isEnabled else { return }
        if !enabled { flush(at: Date(), continueTracking: false) }
        isEnabled = enabled
        if enabled {
            applicationActivated(workspace.frontmostApplication, at: Date())
        } else {
            activeModel = nil
            segmentStart = nil
        }
    }

    private func applicationActivated(_ application: NSRunningApplication?, at date: Date) {
        guard isEnabled else { return }
        flush(at: date, continueTracking: false)
        activeModel = ActivityProxyPolicy.model(forBundleIdentifier: application?.bundleIdentifier)
        segmentStart = activeModel == nil ? nil : date
    }

    private func pause(at date: Date) {
        flush(at: date, continueTracking: false)
        activeModel = nil
        segmentStart = nil
    }

    private func flush(at date: Date, continueTracking: Bool) {
        guard isEnabled, let model = activeModel, let start = segmentStart else { return }
        if let minutes = ActivityProxyPolicy.billableMinutes(from: start, to: date) {
            try? database.recordActivityProxy(
                model: model, minutes: minutes, at: start,
                externalID: "activity-proxy:\(UUID().uuidString)"
            )
            onRecorded()
        }
        segmentStart = continueTracking ? date : nil
        if !continueTracking { activeModel = nil }
    }
}
