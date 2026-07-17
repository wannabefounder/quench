import Foundation
import QuenchEngine

enum ProviderSyncState: Equatable {
    case notConfigured
    case synced
    case failed
}

struct ProviderSyncStatus: Identifiable, Equatable {
    let provider: UsageProvider
    let state: ProviderSyncState
    let lastAttempt: Date?
    let lastSuccess: Date?
    let importedEvents: Int
    let message: String?
    var id: String { provider.rawValue }
}

final class ProviderSyncService {
    private let credentials: CredentialStore
    private let database: AppDatabase
    private let throttle: TimeInterval
    private let maxPages: Int

    init(credentials: CredentialStore = KeychainCredentialStore(),
         database: AppDatabase = .shared,
         throttle: TimeInterval = 15 * 60,
         maxPages: Int = 20) {
        self.credentials = credentials
        self.database = database
        self.throttle = throttle
        self.maxPages = maxPages
    }

    func syncAll(startingAt: Date, force: Bool = false, now: Date = Date()) async -> [ProviderSyncStatus] {
        var statuses: [ProviderSyncStatus] = []
        for provider in UsageProvider.allCases {
            statuses.append(await sync(provider, startingAt: startingAt, force: force, now: now))
        }
        return statuses
    }

    private func sync(_ provider: UsageProvider, startingAt: Date,
                      force: Bool, now: Date) async -> ProviderSyncStatus {
        let existing = try? database.providerSyncRecord(provider)
        let credential: String?
        do {
            credential = try credentials.read(for: provider)
        } catch {
            let message = "Quench could not read this provider key from Keychain."
            try? database.recordProviderSyncFailure(provider: provider, message: message, at: now)
            let record = try? database.providerSyncRecord(provider)
            return status(provider, state: .failed, record: record, message: message)
        }
        guard let credential, !credential.isEmpty else {
            return status(provider, state: .notConfigured, record: existing, message: nil)
        }

        if !force, let lastAttempt = existing?.lastAttemptTs,
           now.timeIntervalSince1970 - TimeInterval(lastAttempt) < throttle {
            let state: ProviderSyncState = existing?.lastError == nil ? .synced : .failed
            return status(provider, state: state, record: existing, message: existing?.lastError)
        }

        let connector: ProviderUsageConnector = switch provider {
        case .openAI: OpenAIUsageConnector(credential: credential)
        case .anthropic: AnthropicUsageConnector(credential: credential)
        }

        do {
            var events: [NormalizedUsageEvent] = []
            var page: String?
            var pagination = ProviderPaginationGuard(maxPages: maxPages)
            repeat {
                let result = try await connector.fetchPage(startingAt: startingAt, page: page)
                events.append(contentsOf: result.events)
                page = result.nextPage
                try pagination.accept(nextPage: page)
            } while page != nil

            try database.commitProviderSync(provider: provider, events: events, at: now)
            let record = try? database.providerSyncRecord(provider)
            return status(provider, state: .synced, record: record, message: nil)
        } catch {
            let message = sanitizedMessage(error)
            try? database.recordProviderSyncFailure(provider: provider, message: message, at: now)
            let record = try? database.providerSyncRecord(provider)
            return status(provider, state: .failed, record: record, message: message)
        }
    }

    private func status(_ provider: UsageProvider, state: ProviderSyncState,
                        record: ProviderSyncRecord?, message: String?) -> ProviderSyncStatus {
        ProviderSyncStatus(
            provider: provider,
            state: state,
            lastAttempt: record?.lastAttemptTs.map { Date(timeIntervalSince1970: TimeInterval($0)) },
            lastSuccess: record?.lastSuccessTs.map { Date(timeIntervalSince1970: TimeInterval($0)) },
            importedEvents: record?.importedEvents ?? 0,
            message: message
        )
    }

    private func sanitizedMessage(_ error: Error) -> String {
        if let connector = error as? ProviderConnectorError { return connector.localizedDescription }
        if error is DecodingError { return "The provider returned an unsupported response format." }
        if let url = error as? URLError {
            return url.code == .timedOut ? "The provider request timed out." : "The provider is unavailable."
        }
        if let pagination = error as? ProviderPaginationError { return pagination.localizedDescription }
        return "Provider sync failed."
    }
}
