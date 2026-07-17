import Foundation
import QuenchEngine

extension Notification.Name {
    static let providerCredentialsChanged = Notification.Name("providerCredentialsChanged")
}

enum ProviderCredentialState: Equatable {
    case disconnected
    case saved
    case checking
    case verified(eventCount: Int)
    case failed(String)
}

@MainActor
final class ProviderCredentialsModel: ObservableObject {
    @Published private(set) var states: [UsageProvider: ProviderCredentialState] = [:]
    @Published private(set) var openRouterImportMessage: String?
    private let store: CredentialStore
    private let database: AppDatabase

    init(store: CredentialStore = KeychainCredentialStore(), database: AppDatabase = .shared) {
        self.store = store
        self.database = database
        reload()
    }

    func state(for provider: UsageProvider) -> ProviderCredentialState {
        states[provider] ?? .disconnected
    }

    func saveAndVerify(_ rawCredential: String, for provider: UsageProvider) {
        let credential = rawCredential.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !credential.isEmpty else {
            states[provider] = .failed("Enter an Admin API key.")
            return
        }
        do {
            try store.save(credential, for: provider)
            states[provider] = .checking
        } catch {
            states[provider] = .failed(error.localizedDescription)
            return
        }

        if provider == .openRouter {
            states[provider] = .saved
            NotificationCenter.default.post(name: .providerCredentialsChanged, object: nil)
            return
        }

        Task {
            do {
                let connector: ProviderUsageConnector = switch provider {
                case .openAI: OpenAIUsageConnector(credential: credential)
                case .anthropic: AnthropicUsageConnector(credential: credential)
                case .openRouter: preconditionFailure("Handled before verification")
                }
                let start = Calendar.current.startOfDay(for: Date())
                let page = try await connector.fetchPage(startingAt: start, page: nil)
                states[provider] = .verified(eventCount: page.events.count)
                NotificationCenter.default.post(name: .providerCredentialsChanged, object: nil)
            } catch {
                states[provider] = .failed(error.localizedDescription)
            }
        }
    }

    func importOpenRouterGeneration(id: String) {
        let trimmedID = id.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedID.isEmpty else {
            openRouterImportMessage = "Enter a generation ID."
            return
        }
        Task {
            do {
                guard let credential = try store.read(for: .openRouter), !credential.isEmpty else {
                    openRouterImportMessage = "Save an OpenRouter API key first."
                    return
                }
                let event = try await OpenRouterGenerationConnector(credential: credential)
                    .fetchGeneration(id: trimmedID)
                try database.commitProviderSync(provider: .openRouter, events: [event], at: Date())
                openRouterImportMessage = "Imported \(event.model ?? "unknown model") • \(event.inputTokens + event.outputTokens) tokens"
                NotificationCenter.default.post(name: .providerCredentialsChanged, object: nil)
            } catch {
                openRouterImportMessage = error is DecodingError
                    ? "OpenRouter returned an unsupported receipt format."
                    : error.localizedDescription
            }
        }
    }

    func remove(_ provider: UsageProvider) {
        do {
            try store.delete(for: provider)
            states[provider] = .disconnected
            NotificationCenter.default.post(name: .providerCredentialsChanged, object: nil)
        } catch {
            states[provider] = .failed(error.localizedDescription)
        }
    }

    private func reload() {
        for provider in UsageProvider.allCases {
            do {
                states[provider] = try store.read(for: provider) == nil ? .disconnected : .saved
            } catch {
                states[provider] = .failed(error.localizedDescription)
            }
        }
    }
}
