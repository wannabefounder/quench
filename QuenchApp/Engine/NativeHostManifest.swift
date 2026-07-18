import Foundation

public struct NativeHostManifest: Codable, Equatable {
    public let name: String
    public let description: String
    public let path: String
    public let type: String
    public let allowed_origins: [String]

    public init(bridgePath: String, extensionID: String) {
        name = "app.quench.browser_bridge"
        description = "Local count-only bridge for Quench"
        path = bridgePath
        type = "stdio"
        allowed_origins = ["chrome-extension://\(extensionID)/"]
    }
}

public enum NativeHostManifestBuilder {
    public static func isValidExtensionID(_ value: String) -> Bool {
        guard value.count == 32 else { return false }
        return value.unicodeScalars.allSatisfy { scalar in
            (97...112).contains(Int(scalar.value))
        }
    }

    public static func data(extensionID: String, bridgePath: String) throws -> Data {
        guard isValidExtensionID(extensionID), bridgePath.hasPrefix("/") else {
            throw ValidationError.invalidConfiguration
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(NativeHostManifest(
            bridgePath: bridgePath, extensionID: extensionID
        ))
    }

    public static func extensionID(from data: Data) -> String? {
        guard let manifest = try? JSONDecoder().decode(NativeHostManifest.self, from: data),
              manifest.name == "app.quench.browser_bridge",
              manifest.type == "stdio",
              manifest.allowed_origins.count == 1,
              let origin = manifest.allowed_origins.first,
              origin.hasPrefix("chrome-extension://"), origin.hasSuffix("/") else { return nil }
        let id = String(origin.dropFirst("chrome-extension://".count).dropLast())
        return isValidExtensionID(id) ? id : nil
    }

    public enum ValidationError: Error { case invalidConfiguration }
}
