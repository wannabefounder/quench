import XCTest
@testable import QuenchEngine

final class ProviderTransparencyTests: XCTestCase {
    private func loadReport() throws -> ProviderTransparencyReport {
        let url = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("QuenchApp/Resources/provider-transparency.json")
        return try ProviderTransparencyReport.load(from: Data(contentsOf: url))
    }

    func testRealScorecardIsValidAndDeterministic() throws {
        let report = try loadReport()
        XCTAssertTrue(report.isValid)
        XCTAssertEqual(report.criteria.count, 4)
        let scores = Dictionary(uniqueKeysWithValues: report.providers.map {
            ($0.id, report.evidenceCount(for: $0))
        })
        XCTAssertEqual(scores["google"], 3)
        XCTAssertEqual(scores["mistral"], 3)
        XCTAssertEqual(scores["openai"], 2)
        XCTAssertEqual(scores["anthropic"], 0)
    }

    func testRejectsUnknownEvidenceAndInsecureSource() throws {
        let valid = try loadReport()
        let provider = ProviderTransparencyRecord(
            id: "example", name: "Example", summary: "Example disclosure",
            evidence: ["invented-check"],
            sources: [.init(title: "Example", url: "http://example.com")]
        )
        let invalid = ProviderTransparencyReport(
            version: valid.version, reviewedAt: valid.reviewedAt,
            disclaimer: valid.disclaimer, criteria: valid.criteria, providers: [provider])
        XCTAssertFalse(invalid.isValid)

        let malformed = ProviderTransparencyRecord(
            id: "example", name: "Example", summary: "Example disclosure", evidence: [],
            sources: [.init(title: "Example", url: "https:missing-host")])
        XCTAssertFalse(ProviderTransparencyReport(
            version: valid.version, reviewedAt: valid.reviewedAt,
            disclaimer: valid.disclaimer, criteria: valid.criteria,
            providers: [malformed]).isValid)
    }

    func testEvidenceCountIgnoresDuplicatesAndUnknownIDs() throws {
        let report = try loadReport()
        let provider = ProviderTransparencyRecord(
            id: "example", name: "Example", summary: "Example",
            evidence: ["request-water", "request-water", "unknown"],
            sources: [.init(title: "Example", url: "https://example.com")])
        XCTAssertEqual(report.evidenceCount(for: provider), 1)
    }
}
