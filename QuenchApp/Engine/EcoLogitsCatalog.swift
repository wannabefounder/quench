import Foundation

public struct EcoLogitsCatalogEntry: Codable, Equatable, Sendable {
    public let provider: String
    public let name: String
    public let activeParametersB: Double
    public let hasWarnings: Bool

    public init(provider: String, name: String, activeParametersB: Double,
                hasWarnings: Bool) {
        self.provider = provider
        self.name = name
        self.activeParametersB = activeParametersB
        self.hasWarnings = hasWarnings
    }
}

public struct EcoLogitsCatalogSnapshot: Codable, Equatable, Sendable {
    public let apiVersion: String
    public let fetchedAt: Date
    public let providers: [String]
    public let entries: [EcoLogitsCatalogEntry]

    public init(apiVersion: String = "v1beta", fetchedAt: Date,
                providers: [String], entries: [EcoLogitsCatalogEntry]) {
        self.apiVersion = apiVersion
        self.fetchedAt = fetchedAt
        self.providers = providers
        self.entries = entries
    }

    /// Includes both provider-qualified and bare model names. Qualified names avoid collisions;
    /// bare names cover the model strings emitted by most local logs and provider usage APIs.
    public var activeParametersByModel: [String: Double] {
        var result: [String: Double] = [:]
        for entry in entries.sorted(by: { lhs, rhs in
            lhs.provider == rhs.provider ? lhs.name < rhs.name : lhs.provider < rhs.provider
        }) {
            let provider = entry.provider.lowercased()
            let name = entry.name.lowercased()
            result["\(provider)/\(name)"] = entry.activeParametersB
            if result[name] == nil { result[name] = entry.activeParametersB }
        }
        return result
    }

    public var isValid: Bool {
        guard apiVersion == "v1beta", (1...32).contains(providers.count),
              Set(providers).count == providers.count,
              providers.allSatisfy(EcoLogitsCatalogParser.isValidProvider),
              (1...10_000).contains(entries.count) else { return false }
        let allowedProviders = Set(providers)
        let keys = Set(entries.map { "\($0.provider)/\($0.name)" })
        return keys.count == entries.count && entries.allSatisfy {
            allowedProviders.contains($0.provider)
                && EcoLogitsCatalogParser.isValidModelName($0.name)
                && $0.activeParametersB.isFinite
                && (0.001...5_000).contains($0.activeParametersB)
        }
    }
}

public enum EcoLogitsCatalogParser {
    public enum CatalogError: Error, Equatable {
        case invalidResponse
        case invalidProvider
        case noUsableModels
    }

    public static func providers(from data: Data) throws -> [String] {
        let decoded = try JSONDecoder().decode(ProviderResponse.self, from: data)
        let providers = decoded.providers.filter(isValidProvider).uniqued().sorted()
        guard !providers.isEmpty, providers.count <= 32 else { throw CatalogError.invalidResponse }
        return providers
    }

    public static func entries(from data: Data, expectedProvider: String) throws
        -> [EcoLogitsCatalogEntry] {
        guard isValidProvider(expectedProvider) else { throw CatalogError.invalidProvider }
        let decoded = try JSONDecoder().decode(ModelResponse.self, from: data)
        let entries = decoded.models.compactMap { model -> EcoLogitsCatalogEntry? in
            guard model.provider == expectedProvider,
                  isValidModelName(model.name),
                  let active = model.architecture?.activeParametersB,
                  active.isFinite, (0.001...5_000).contains(active) else { return nil }
            return EcoLogitsCatalogEntry(
                provider: model.provider, name: model.name,
                activeParametersB: active,
                hasWarnings: !(model.warnings ?? []).isEmpty
            )
        }
        guard !entries.isEmpty else { throw CatalogError.noUsableModels }
        return entries
    }

    public static func isValidProvider(_ value: String) -> Bool {
        guard (1...64).contains(value.count) else { return false }
        return value.unicodeScalars.allSatisfy { scalar in
            (97...122).contains(scalar.value) || (48...57).contains(scalar.value)
                || scalar == "_" || scalar == "-"
        }
    }

    public static func isValidModelName(_ value: String) -> Bool {
        guard (1...200).contains(value.count) else { return false }
        return value.unicodeScalars.allSatisfy { !CharacterSet.controlCharacters.contains($0) }
    }

    private struct ProviderResponse: Decodable { let providers: [String] }
    private struct ModelResponse: Decodable { let models: [Model] }
    private struct Model: Decodable {
        let provider: String
        let name: String
        let architecture: Architecture?
        let warnings: [Warning]?
    }
    private struct Warning: Decodable { let code: String? }
    private struct Architecture: Decodable {
        let type: String?
        let parameters: Parameters?

        var activeParametersB: Double? {
            guard let parameters else { return nil }
            if type == "moe", let active = parameters.active?.midpoint { return active }
            return parameters.midpoint ?? parameters.total
        }
    }
    private struct Parameters: Decodable {
        let total: Double?
        let active: RangeValue?
        let min: Double?
        let max: Double?

        init(from decoder: Decoder) throws {
            if let value = try? decoder.singleValueContainer().decode(Double.self) {
                total = value
                active = nil
                min = nil
                max = nil
                return
            }
            let values = try decoder.container(keyedBy: CodingKeys.self)
            total = try values.decodeIfPresent(Double.self, forKey: .total)
            active = try values.decodeIfPresent(RangeValue.self, forKey: .active)
            min = try values.decodeIfPresent(Double.self, forKey: .min)
            max = try values.decodeIfPresent(Double.self, forKey: .max)
        }

        var midpoint: Double? {
            if let min, let max { return (min + max) / 2 }
            return min ?? max
        }

        private enum CodingKeys: String, CodingKey { case total, active, min, max }
    }
    private struct RangeValue: Decodable {
        let min: Double?
        let max: Double?

        init(from decoder: Decoder) throws {
            if let value = try? decoder.singleValueContainer().decode(Double.self) {
                min = value
                max = value
                return
            }
            let values = try decoder.container(keyedBy: CodingKeys.self)
            min = try values.decodeIfPresent(Double.self, forKey: .min)
            max = try values.decodeIfPresent(Double.self, forKey: .max)
        }

        var midpoint: Double? {
            if let min, let max { return (min + max) / 2 }
            return min ?? max
        }

        private enum CodingKeys: String, CodingKey { case min, max }
    }
}

public extension Coefficients {
    /// Adds catalog architecture sizes only for models absent from the reviewed bundled table.
    /// A remote catalog can improve unknown-model fallbacks but can never replace local coefficients.
    func mergingCatalogActiveParameters(_ catalog: [String: Double]) -> Coefficients {
        var merged = energy.param_fallback.model_active_params_b
        for (rawName, value) in catalog {
            let name = rawName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty, value.isFinite, (0.001...5_000).contains(value),
                  energy.wh_per_1k_tokens[name] == nil, merged[name] == nil else { continue }
            merged[name] = value
        }
        let fallback = ParamFallback(
            alpha: energy.param_fallback.alpha, beta: energy.param_fallback.beta,
            gamma: energy.param_fallback.gamma, batch: energy.param_fallback.batch,
            system_overhead: energy.param_fallback.system_overhead,
            model_active_params_b: merged
        )
        return Coefficients(
            version: version,
            energy: Energy(wh_per_1k_tokens: energy.wh_per_1k_tokens,
                           param_fallback: fallback),
            water: water, message_fallback: message_fallback,
            minutes_fallback: minutes_fallback
        )
    }
}

private extension Sequence where Element == String {
    func uniqued() -> [String] {
        var seen = Set<String>()
        return filter { seen.insert($0).inserted }
    }
}
