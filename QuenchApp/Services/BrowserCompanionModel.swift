import AppKit
import Foundation
import QuenchEngine

enum ChromiumBrowser: String, CaseIterable, Identifiable {
    case chrome = "Google Chrome"
    case brave = "Brave"
    case edge = "Microsoft Edge"

    var id: String { rawValue }

    var nativeHostDirectory: String {
        switch self {
        case .chrome: "Google/Chrome/NativeMessagingHosts"
        case .brave: "BraveSoftware/Brave-Browser/NativeMessagingHosts"
        case .edge: "Microsoft Edge/NativeMessagingHosts"
        }
    }
}

@MainActor
final class BrowserCompanionModel: ObservableObject {
    @Published var browser: ChromiumBrowser {
        didSet {
            UserDefaults.standard.set(browser.rawValue, forKey: "companionBrowser")
            refresh()
        }
    }
    @Published var extensionID = ""
    @Published private(set) var message = "Not connected"
    @Published private(set) var isConnected = false

    init() {
        browser = ChromiumBrowser(rawValue: UserDefaults.standard.string(
            forKey: "companionBrowser") ?? "") ?? .chrome
        refresh()
    }

    func connect() {
        let id = extensionID.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard NativeHostManifestBuilder.isValidExtensionID(id) else {
            message = "Paste the 32-character extension ID shown by your browser."
            isConnected = false
            return
        }
        guard let bridgeURL, FileManager.default.isExecutableFile(atPath: bridgeURL.path) else {
            message = "Install Quench in Applications before connecting the browser."
            isConnected = false
            return
        }
        do {
            let data = try NativeHostManifestBuilder.data(
                extensionID: id, bridgePath: bridgeURL.path)
            let url = manifestURL
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: url, options: .atomic)
            try FileManager.default.setAttributes(
                [.posixPermissions: 0o600], ofItemAtPath: url.path)
            extensionID = id
            UserDefaults.standard.set(id, forKey: "companionExtensionID")
            isConnected = true
            message = "Connected locally to \(browser.rawValue). Restart the browser once."
        } catch {
            isConnected = false
            message = "Quench could not create the local browser connection."
        }
    }

    func disconnect() {
        do {
            if FileManager.default.fileExists(atPath: manifestURL.path) {
                try FileManager.default.removeItem(at: manifestURL)
            }
            isConnected = false
            message = "Disconnected from \(browser.rawValue)."
        } catch {
            message = "Quench could not remove the local browser connection."
        }
    }

    func revealCompanionFolder() {
        guard let companionFolderURL else {
            message = "The companion folder is available in the packaged Quench app."
            return
        }
        NSWorkspace.shared.activateFileViewerSelecting([companionFolderURL])
    }

    func refresh() {
        let saved = UserDefaults.standard.string(forKey: "companionExtensionID") ?? ""
        extensionID = saved
        guard let data = try? Data(contentsOf: manifestURL),
              let connectedID = NativeHostManifestBuilder.extensionID(from: data) else {
            isConnected = false
            message = "Not connected"
            return
        }
        extensionID = connectedID
        isConnected = true
        message = "Connected locally to \(browser.rawValue)."
    }

    private var manifestURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(browser.nativeHostDirectory, isDirectory: true)
            .appendingPathComponent("app.quench.browser_bridge.json")
    }

    private var bridgeURL: URL? {
        guard Bundle.main.bundleURL.pathExtension == "app" else { return nil }
        return Bundle.main.bundleURL
            .appendingPathComponent("Contents/Helpers/QuenchBrowserBridge")
    }

    private var companionFolderURL: URL? {
        if let bundled = Bundle.main.resourceURL?.appendingPathComponent(
            "BrowserExtension", isDirectory: true),
           FileManager.default.fileExists(atPath: bundled.path) { return bundled }
        let source = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("BrowserExtension", isDirectory: true)
        return FileManager.default.fileExists(atPath: source.path) ? source : nil
    }
}
