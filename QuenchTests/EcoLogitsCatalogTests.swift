import XCTest
@testable import QuenchEngine

final class EcoLogitsCatalogTests: XCTestCase {
    func testProviderResponseIsStrictlyFilteredAndSorted() throws {
        let data = Data(#"{"providers":["openai","anthropic","openai","bad/provider"]}"#.utf8)
        XCTAssertEqual(try EcoLogitsCatalogParser.providers(from: data), ["anthropic", "openai"])
        XCTAssertFalse(EcoLogitsCatalogParser.isValidProvider("../openai"))
    }

    func testParsesDenseAndMoEActiveParameterRanges() throws {
        let data = Data(#"""
        {"models":[
          {"provider":"openai","name":"dense-new","architecture":{"type":"dense","parameters":{"min":20,"max":60}},"warnings":[]},
          {"provider":"openai","name":"moe-new","architecture":{"type":"moe","parameters":{"total":900,"active":{"min":90,"max":300}}},"warnings":[{"code":"approximate"}]},
          {"provider":"openai","name":"scalar-new","architecture":{"type":"dense","parameters":7},"warnings":[]},
          {"provider":"other","name":"wrong-provider","architecture":{"type":"dense","parameters":{"min":10,"max":20}},"warnings":[]}
        ]}
        """#.utf8)
        let entries = try EcoLogitsCatalogParser.entries(from: data, expectedProvider: "openai")
        XCTAssertEqual(entries.count, 3)
        XCTAssertEqual(entries.first(where: { $0.name == "dense-new" })?.activeParametersB, 40)
        XCTAssertEqual(entries.first(where: { $0.name == "moe-new" })?.activeParametersB, 195)
        XCTAssertEqual(entries.first(where: { $0.name == "scalar-new" })?.activeParametersB, 7)
        XCTAssertTrue(entries.first(where: { $0.name == "moe-new" })?.hasWarnings == true)
    }

    func testSnapshotProvidesQualifiedAndBareKeys() {
        let snapshot = EcoLogitsCatalogSnapshot(
            fetchedAt: Date(timeIntervalSince1970: 1), providers: ["openai"],
            entries: [.init(provider: "openai", name: "gpt-next",
                            activeParametersB: 123, hasWarnings: false)]
        )
        XCTAssertEqual(snapshot.activeParametersByModel["openai/gpt-next"], 123)
        XCTAssertEqual(snapshot.activeParametersByModel["gpt-next"], 123)
        XCTAssertTrue(snapshot.isValid)
        XCTAssertFalse(EcoLogitsCatalogSnapshot(
            apiVersion: "latest", fetchedAt: Date(), providers: ["openai"],
            entries: snapshot.entries).isValid)
    }

    func testCatalogImprovesUnknownModelWithoutOverridingReviewedCoefficient() throws {
        let base = Coefficients.fallback
        let merged = base.mergingCatalogActiveParameters([
            "future-model": 300,
            "default": 5_000,
            "invalid": .infinity
        ])
        let sample = UsageSample(model: "future-model", inputTokens: 100, outputTokens: 300)
        XCTAssertGreaterThan(WaterMath.energyWh(sample, coef: merged),
                             WaterMath.energyWh(sample, coef: base))
        XCTAssertEqual(
            WaterMath.energyWh(UsageSample(model: "default", inputTokens: 100, outputTokens: 300),
                               coef: merged),
            WaterMath.energyWh(UsageSample(model: "default", inputTokens: 100, outputTokens: 300),
                               coef: base), accuracy: 0.000_001
        )
    }
}
