import Foundation
import QuenchEngine

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
    private let store: CredentialStore

    init(store: CredentialStore = KeychainCredentialStore()) {
        self.store = store
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

        Task {
            do {
                let connector: ProviderUsageConnector = switch provider {
                case .openAI: OpenAIUsageConnector(credential: credential)
                case .anthropic: AnthropicUsageConnector(credential: credential)
                }
                let start = Calendar.current.startOfDay(for: Date())
                let page = try await connector.fetchPage(startingAt: start, page: nil)
                states[provider] = .verified(eventCount: page.events.count)
            } catch {
                states[provider] = .failed(error.localizedDescription)
            }
        }
    }

    func remove(_ provider: UsageProvider) {
        do {
            try store.delete(for: provider)
            states[provider] = .disconnected
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
