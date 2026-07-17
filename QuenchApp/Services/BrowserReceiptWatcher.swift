import Darwin
import Foundation

/// Watches the count-only browser inbox without polling or observing Quench's SQLite writes.
/// The bridge appends to this stable file; a short debounce coalesces streaming filesystem events.
final class BrowserReceiptWatcher {
    typealias ChangeHandler = @Sendable () -> Void

    private let url: URL
    private let queue = DispatchQueue(label: "app.quench.browser-receipt-watcher", qos: .utility)
    private let handler: ChangeHandler
    private var source: DispatchSourceFileSystemObject?
    private var pending: DispatchWorkItem?

    init(fileManager: FileManager = .default, handler: @escaping ChangeHandler) {
        let directory = fileManager.urls(for: .applicationSupportDirectory,
                                         in: .userDomainMask)[0]
            .appendingPathComponent("Quench", isDirectory: true)
        url = directory.appendingPathComponent("browser-events.jsonl")
        self.handler = handler
        queue.async { [weak self] in self?.prepareAndArm(fileManager: fileManager) }
    }

    deinit {
        pending?.cancel()
        source?.cancel()
    }

    private func prepareAndArm(fileManager: FileManager) {
        do {
            try fileManager.createDirectory(at: url.deletingLastPathComponent(),
                                            withIntermediateDirectories: true)
            if !fileManager.fileExists(atPath: url.path) {
                guard fileManager.createFile(atPath: url.path, contents: nil,
                                             attributes: [.posixPermissions: 0o600]) else { return }
            }
        } catch { return }
        arm(fileManager: fileManager)
    }

    private func arm(fileManager: FileManager) {
        guard source == nil else { return }
        let descriptor = open(url.path, O_EVTONLY)
        guard descriptor >= 0 else { return }
        let watcher = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: descriptor,
            eventMask: [.write, .extend, .rename, .delete],
            queue: queue
        )
        watcher.setCancelHandler { close(descriptor) }
        watcher.setEventHandler { [weak self, weak watcher] in
            guard let self, let watcher else { return }
            let event = watcher.data
            if event.contains(.delete) || event.contains(.rename) {
                watcher.cancel()
                source = nil
                queue.asyncAfter(deadline: .now() + 0.25) { [weak self] in
                    self?.prepareAndArm(fileManager: fileManager)
                }
                return
            }
            scheduleChange()
        }
        source = watcher
        watcher.resume()
    }

    private func scheduleChange() {
        pending?.cancel()
        let work = DispatchWorkItem { [handler] in handler() }
        pending = work
        queue.asyncAfter(deadline: .now() + 0.35, execute: work)
    }
}
