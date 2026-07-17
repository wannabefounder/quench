import XCTest
@testable import QuenchEngine

/// Tests load the REAL bundled coefficients.json — these numbers are the contract.
final class WaterMathTests: XCTestCase {

    static let coef: Coefficients = {
        let testDir = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        let root = testDir.deletingLastPathComponent()
        let url = root.appendingPathComponent("QuenchApp/Resources/coefficients.json")
        let data = try! Data(contentsOf: url)
        return try! Coefficients.load(from: data)
    }()
    var coef: Coefficients { Self.coef }

    // MARK: energy

    func testGPT4oShortQueryEnergyMatchesCalibration() {
        // 100 in / 300 out should land ~0.34 Wh (Altman 2025 / benchmark short-form anchor).
        let s = UsageSample(model: "gpt-4o", inputTokens: 100, outputTokens: 300)
        XCTAssertEqual(WaterMath.energyWh(s, coef: coef), 0.34, accuracy: 1e-6)
    }

    func testKnownTokensEnergy() {
        let s = UsageSample(model: "gpt-4o", inputTokens: 1000, outputTokens: 1000)
        // 0.08 + 0.05 + 0.85
        XCTAssertEqual(WaterMath.energyWh(s, coef: coef), 0.98, accuracy: 1e-6)
    }

    func testOutputOnlyTokens() {
        let s = UsageSample(model: "gpt-4o", inputTokens: nil, outputTokens: 500)
        XCTAssertEqual(WaterMath.energyWh(s, coef: coef), 0.08 + 0.425, accuracy: 1e-6)
    }

    func testMessageFallbackEnergy() {
        let s = UsageSample(model: "gpt-4o", messageCount: 2)
        let perMsg = 0.08 + 0.3 * 0.05 + 0.35 * 0.85 // 0.3925
        XCTAssertEqual(WaterMath.energyWh(s, coef: coef), 2 * perMsg, accuracy: 1e-6)
    }

    func testMinutesFallbackEnergy() {
        let s = UsageSample(model: "gpt-4o", minutesActive: 10)
        let perMsg = 0.08 + 0.3 * 0.05 + 0.35 * 0.85
        XCTAssertEqual(WaterMath.energyWh(s, coef: coef), 10 * 0.8 * perMsg, accuracy: 1e-6)
    }

    func testZeroValuesAreZero() {
        XCTAssertEqual(WaterMath.energyWh(UsageSample(), coef: coef), 0, accuracy: 1e-9)
        XCTAssertEqual(WaterMath.waterMl(UsageSample(), coef: coef), 0, accuracy: 1e-9)
    }

    func testUnknownModelUsesDefault() {
        let s = UsageSample(model: "totally-made-up", inputTokens: 1000, outputTokens: 1000)
        // default: 0.08 + 0.05 + 0.90
        XCTAssertEqual(WaterMath.energyWh(s, coef: coef), 1.03, accuracy: 1e-6)
    }

    func testReasoningModelCostsFarMoreThanGPT4o() {
        let o3 = UsageSample(model: "o3-mini", inputTokens: 100, outputTokens: 1000)
        let gpt = UsageSample(model: "gpt-4o", inputTokens: 100, outputTokens: 1000)
        XCTAssertGreaterThan(WaterMath.energyWh(o3, coef: coef),
                             WaterMath.energyWh(gpt, coef: coef) * 10)
    }

    // MARK: water modes

    func testWaterStandardGPT4o() {
        let s = UsageSample(model: "gpt-4o", inputTokens: 1000, outputTokens: 1000) // 0.98 Wh
        // Facility energy includes PUE, so on-site uses server energy: 0.30 / 1.20.
        XCTAssertEqual(WaterMath.waterMl(s, mode: .standard, coef: coef),
                       0.98 * (0.30 / 1.20 + 3.00), accuracy: 1e-6)
    }

    func testWaterConservativeIsOnSiteOnly() {
        let s = UsageSample(model: "gpt-4o", inputTokens: 1000, outputTokens: 1000)
        XCTAssertEqual(WaterMath.waterMl(s, mode: .conservative, coef: coef),
                       0.98 * 0.30 / 1.20, accuracy: 1e-6)
    }

    func testWaterFullAddsEmbodiedShare() {
        let s = UsageSample(model: "gpt-4o", inputTokens: 1000, outputTokens: 1000)
        let standard = 0.98 * (0.30 / 1.20 + 3.00)
        XCTAssertEqual(WaterMath.waterMl(s, mode: .full, coef: coef), standard * 1.12, accuracy: 1e-6)
    }

    func testModesAreOrderedLowMidHigh() {
        let s = UsageSample(model: "claude-sonnet", inputTokens: 500, outputTokens: 800)
        let r = WaterMath.waterRange(s, coef: coef)
        XCTAssertLessThan(r.low, r.mid)
        XCTAssertLessThan(r.mid, r.high)
    }

    // MARK: providers & regions

    func testAnthropicProviderOnSiteFactor() {
        let s = UsageSample(model: "claude-3-5-sonnet", inputTokens: 100, outputTokens: 300) // 1.155 Wh
        // anthropic WUE 0.55 applies to server energy; facility coefficient includes PUE 1.12.
        XCTAssertEqual(WaterMath.waterMl(s, mode: .conservative, coef: coef),
                       1.155 * 0.55 / 1.12, accuracy: 1e-6)
    }

    func testRegionChangesOffSiteWater() {
        let s = UsageSample(model: "gpt-4o", inputTokens: 1000, outputTokens: 1000)
        let china = WaterMath.waterMl(s, mode: .standard, region: "china", coef: coef)
        let eu = WaterMath.waterMl(s, mode: .standard, region: "eu", coef: coef)
        XCTAssertGreaterThan(china, eu)
        // china: facility Wh * (server-side WUE / PUE + grid WUE)
        XCTAssertEqual(china, 0.98 * (0.30 / 1.20 + 6.02), accuracy: 1e-6)
    }

    func testUnknownRegionFallsBackToDefault() {
        let s = UsageSample(model: "gpt-4o", inputTokens: 1000, outputTokens: 1000)
        let unknown = WaterMath.waterMl(s, mode: .standard, region: "atlantis", coef: coef)
        let global = WaterMath.waterMl(s, mode: .standard, region: "global", coef: coef)
        XCTAssertEqual(unknown, global, accuracy: 1e-9)
    }

    // MARK: model mapping

    func testModelKeyMapping() {
        XCTAssertEqual(WaterMath.modelKey("claude-sonnet-4-5"), "claude-sonnet")
        XCTAssertEqual(WaterMath.modelKey("gpt-4o-mini"), "gpt-4o-mini")
        XCTAssertEqual(WaterMath.modelKey("claude-3-opus-20240229"), "claude-opus")
        XCTAssertEqual(WaterMath.modelKey("o3"), "o3")
        XCTAssertEqual(WaterMath.modelKey("gemini-2.0-flash"), "gemini")
        XCTAssertEqual(WaterMath.modelKey(nil), "default")
        XCTAssertEqual(WaterMath.modelKey(""), "default")
    }

    func testProviderMapping() {
        XCTAssertEqual(WaterMath.providerKey(forModel: "gpt-4o"), "openai")
        XCTAssertEqual(WaterMath.providerKey(forModel: "claude-opus"), "anthropic")
        XCTAssertEqual(WaterMath.providerKey(forModel: "gemini"), "google")
        XCTAssertEqual(WaterMath.providerKey(forModel: "llama-405b"), "meta")
        XCTAssertEqual(WaterMath.providerKey(forModel: "default"), "default")
    }

    // MARK: param fallback (EcoLogits GPU formula)

    func testParamEnergyFormulaIsPositiveAndMonotonic() {
        let pf = coef.energy.param_fallback
        let small = WaterMath.paramEnergyPer1k(7, pf)
        let big = WaterMath.paramEnergyPer1k(405, pf)
        XCTAssertGreaterThan(small, 0)
        XCTAssertGreaterThan(big, small) // more active params -> more energy
        // 50B active ~ 0.829 Wh/1k output tokens (facility)
        XCTAssertEqual(WaterMath.paramEnergyPer1k(50, pf), 0.8288, accuracy: 1e-3)
    }

    // MARK: aggregate

    func testTotalWaterSumsEvents() {
        let a = UsageSample(model: "gpt-4o", inputTokens: 1000, outputTokens: 1000)
        let b = UsageSample(model: "claude-haiku", inputTokens: 200, outputTokens: 400)
        let total = WaterMath.totalWaterMl([a, b], coef: coef)
        let expected = WaterMath.waterMl(a, coef: coef) + WaterMath.waterMl(b, coef: coef)
        XCTAssertEqual(total, expected, accuracy: 1e-9)
        XCTAssertGreaterThan(total, 0)
    }

    func testRaceEngineAIWaterUsesStandardMode() {
        let a = UsageSample(model: "gpt-4o", inputTokens: 1000, outputTokens: 1000)
        XCTAssertEqual(RaceEngine.aiWaterMl([a], coef: coef),
                       WaterMath.waterMl(a, mode: .standard, coef: coef), accuracy: 1e-9)
    }
}
