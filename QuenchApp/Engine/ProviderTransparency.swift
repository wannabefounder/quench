import Foundation

public struct TransparencyCriterion: Codable, Equatable, Sendable, Identifiable {
    public let id: String
    public let title: String
    public let explanation: String

    public init(id: String, title: String, explanation: String) {
        self.id = id
        self.title = title
        self.explanation = explanation
    }
}

public struct TransparencySource: Codable, Equatable, Sendable {
    public let title: String
    public let url: String

    public init(title: String, url: String) {
        self.title = title
        self.url = url
    }
}

public struct ProviderTransparencyRecord: Codable, Equatable, Sendable, Identifiable {
    public let id: String
    public let name: String
    public let summary: String
    public let evidence: [String]
    public let sources: [TransparencySource]

    public init(id: String, name: String, summary: String, evidence: [String],
                sources: [TransparencySource]) {
        self.id = id
        self.name = name
        self.summary = summary
        self.evidence = evidence
        self.sources = sources
    }

    public func discloses(_ criterionID: String) -> Bool { evidence.contains(criterionID) }
}

public struct ProviderTransparencyReport: Codable, Equatable, Sendable {
    public let version: String
    public let reviewedAt: String
    public let disclaimer: String
    public let criteria: [TransparencyCriterion]
    public let providers: [ProviderTransparencyRecord]

    public init(version: String, reviewedAt: String, disclaimer: String,
                criteria: [TransparencyCriterion], providers: [ProviderTransparencyRecord]) {
        self.version = version
        self.reviewedAt = reviewedAt
        self.disclaimer = disclaimer
        self.criteria = criteria
        self.providers = providers
    }

    public static func load(from data: Data) throws -> ProviderTransparencyReport {
        try JSONDecoder().decode(ProviderTransparencyReport.self, from: data)
    }

    public func evidenceCount(for provider: ProviderTransparencyRecord) -> Int {
        Set(provider.evidence).intersection(criteria.map(\.id)).count
    }

    public var isValid: Bool {
        guard !version.isEmpty, reviewedAt.range(
            of: #"^\d{4}-\d{2}-\d{2}$"#, options: .regularExpression) != nil,
              !disclaimer.isEmpty, !criteria.isEmpty, !providers.isEmpty,
              Set(criteria.map(\.id)).count == criteria.count,
              Set(providers.map(\.id)).count == providers.count else { return false }
        let criterionIDs = Set(criteria.map(\.id))
        guard criteria.allSatisfy({ validID($0.id) && !$0.title.isEmpty && !$0.explanation.isEmpty })
        else { return false }
        return providers.allSatisfy { provider in
            validID(provider.id) && !provider.name.isEmpty && !provider.summary.isEmpty
                && Set(provider.evidence).count == provider.evidence.count
                && Set(provider.evidence).isSubset(of: criterionIDs)
                && !provider.sources.isEmpty
                && provider.sources.allSatisfy { source in
                    guard !source.title.isEmpty, let url = URL(string: source.url) else { return false }
                    return url.scheme == "https" && !(url.host ?? "").isEmpty
                }
        }
    }

    private func validID(_ value: String) -> Bool {
        guard (1...64).contains(value.count) else { return false }
        return value.unicodeScalars.allSatisfy { scalar in
            (97...122).contains(scalar.value) || (48...57).contains(scalar.value)
                || scalar == "-"
        }
    }
}
