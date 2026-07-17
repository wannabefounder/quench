import Foundation
import Security
import QuenchEngine

protocol CredentialStore {
    func save(_ credential: String, for provider: UsageProvider) throws
    func read(for provider: UsageProvider) throws -> String?
    func delete(for provider: UsageProvider) throws
}

enum CredentialStoreError: LocalizedError {
    case invalidEncoding
    case keychain(OSStatus)

    var errorDescription: String? {
        switch self {
        case .invalidEncoding: "The credential could not be encoded."
        case .keychain(let status):
            (SecCopyErrorMessageString(status, nil) as String?) ?? "Keychain error \(status)."
        }
    }
}

/// Admin credentials live only in macOS Keychain. They never enter UserDefaults, SQLite, or logs.
final class KeychainCredentialStore: CredentialStore {
    private let service = "app.quench.provider-credentials"

    func save(_ credential: String, for provider: UsageProvider) throws {
        guard let data = credential.data(using: .utf8) else {
            throw CredentialStoreError.invalidEncoding
        }
        let query = baseQuery(provider)
        let update: [CFString: Any] = [kSecValueData: data]
        let status = SecItemUpdate(query as CFDictionary, update as CFDictionary)
        if status == errSecItemNotFound {
            var add = query
            add[kSecValueData] = data
            add[kSecAttrAccessible] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            let addStatus = SecItemAdd(add as CFDictionary, nil)
            guard addStatus == errSecSuccess else { throw CredentialStoreError.keychain(addStatus) }
        } else if status != errSecSuccess {
            throw CredentialStoreError.keychain(status)
        }
    }

    func read(for provider: UsageProvider) throws -> String? {
        var query = baseQuery(provider)
        query[kSecReturnData] = true
        query[kSecMatchLimit] = kSecMatchLimitOne
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else { throw CredentialStoreError.keychain(status) }
        guard let data = item as? Data, let value = String(data: data, encoding: .utf8) else {
            throw CredentialStoreError.invalidEncoding
        }
        return value
    }

    func delete(for provider: UsageProvider) throws {
        let status = SecItemDelete(baseQuery(provider) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw CredentialStoreError.keychain(status)
        }
    }

    private func baseQuery(_ provider: UsageProvider) -> [CFString: Any] {
        [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: provider.rawValue,
            kSecAttrSynchronizable: false
        ]
    }
}
