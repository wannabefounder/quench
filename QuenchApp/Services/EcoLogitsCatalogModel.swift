import Foundation
import QuenchEngine

extension Notification.Name {
    static let ecoLogitsCatalogChanged = Notification.Name("EcoLogitsCatalogChanged")
}

enum EcoLogitsCatalogCache {
    static var url: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Quench", isDirectory: true)
            .appendingPathComponent("ecologits-model-catalog.json")
    }

    static func load() -> EcoLogitsCatalogSnapshot? {
        guard let data = try? Data(contentsOf: url), data.count <= 5_000_000 else { return nil }
        guard let snapshot = try? JSONDecoder().decode(EcoLogitsCatalogSnapshot.self, from: data),
              snapshot.isValid else { return nil }
        return snapshot
    }

    static func save(_ snapshot: EcoLogitsCatalogSnapshot) throws {
        guard snapshot.isValid else { throw CatalogNetworkError.invalidHTTPResponse }
        let data = try JSONEncoder().encode(snapshot)
        guard data.count <= 5_000_000 else { throw CatalogNetworkError.responseTooLarge }
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url, options: .atomic)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
    }
}

@MainActor
final class EcoLogitsCatalogModel: ObservableObject {
    @Published private(set) var isRefreshing = false
    @Published private(set) var snapshot: EcoLogitsCatalogSnapshot?
    @Published private(set) var message = "Optional — never sends your AI usage"

    init() {
        snapshot = EcoLogitsCatalogCache.load()
        if let snapshot {
            message = "Cached \(snapshot.entries.count) model architectures"
        }
    }

    var lastUpdatedText: String? {
        snapshot?.fetchedAt.formatted(date: .abbreviated, time: .shortened)
    }

    var warningCount: Int { snapshot?.entries.filter(\.hasWarnings).count ?? 0 }

    func refresh() {
        guard !isRefreshing else { return }
        isRefreshing = true
        message = "Downloading public model names and architecture sizes…"
        Task {
            do {
                let updated = try await CatalogClient.fetch()
                try EcoLogitsCatalogCache.save(updated)
                snapshot = updated
                message = "Updated \(updated.entries.count) model architectures"
                NotificationCenter.default.post(name: .ecoLogitsCatalogChanged, object: nil)
            } catch {
                message = snapshot == nil
                    ? "Catalog unavailable — local estimates still work"
                    : "Refresh failed — using the cached catalog"
            }
            isRefreshing = false
        }
    }
}

private enum CatalogNetworkError: Error {
    case invalidHTTPResponse
    case responseTooLarge
}

private enum CatalogClient {
    private static let baseURL = URL(string: "https://api.ecologits.ai/v1beta")!
    private static let maximumResponseBytes = 2_000_000

    static func fetch() async throws -> EcoLogitsCatalogSnapshot {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 10
        configuration.timeoutIntervalForResource = 30
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }

        let providerData = try await get(baseURL.appendingPathComponent("providers"), session: session)
        let providers = try EcoLogitsCatalogParser.providers(from: providerData)
        let entries = try await withThrowingTaskGroup(
            of: [EcoLogitsCatalogEntry].self, returning: [EcoLogitsCatalogEntry].self
        ) { group in
            for provider in providers {
                group.addTask {
                    let url = baseURL.appendingPathComponent("models")
                        .appendingPathComponent(provider)
                    let data = try await get(url, session: session)
                    return try EcoLogitsCatalogParser.entries(
                        from: data, expectedProvider: provider)
                }
            }
            var all: [EcoLogitsCatalogEntry] = []
            for try await providerEntries in group { all.append(contentsOf: providerEntries) }
            return all.sorted { lhs, rhs in
                lhs.provider == rhs.provider ? lhs.name < rhs.name : lhs.provider < rhs.provider
            }
        }
        return EcoLogitsCatalogSnapshot(
            fetchedAt: Date(), providers: providers, entries: entries)
    }

    private static func get(_ url: URL, session: URLSession) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw CatalogNetworkError.invalidHTTPResponse
        }
        guard data.count <= maximumResponseBytes else { throw CatalogNetworkError.responseTooLarge }
        return data
    }
}
