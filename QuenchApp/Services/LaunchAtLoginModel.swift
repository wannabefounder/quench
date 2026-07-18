import Foundation
import ServiceManagement
import SwiftUI

/// Opt-in login-item control backed by macOS' registered main-app service.
/// Raw SwiftPM executables cannot register; packaged Quench.app builds can.
@MainActor
final class LaunchAtLoginModel: ObservableObject {
    @Published private(set) var isEnabled = false
    @Published private(set) var isChanging = false
    @Published private(set) var message: String?

    var isAvailable: Bool { Bundle.main.bundleURL.pathExtension == "app" }

    var binding: Binding<Bool> {
        Binding(get: { self.isEnabled }, set: { self.setEnabled($0) })
    }

    init() {
        refresh()
    }

    func refresh() {
        guard isAvailable else {
            isEnabled = false
            message = "Available in the packaged Quench app."
            return
        }
        let status = SMAppService.mainApp.status
        isEnabled = status == .enabled
        message = status == .requiresApproval
            ? "Finish approval in System Settings > General > Login Items." : nil
    }

    private func setEnabled(_ enabled: Bool) {
        guard isAvailable, !isChanging else { return }
        isChanging = true
        message = nil
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            message = "macOS could not update the login item. Try again in System Settings."
        }
        isChanging = false
        refresh()
    }
}
