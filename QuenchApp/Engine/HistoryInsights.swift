import Foundation

public struct ModelWaterTotal: Equatable {
    public let model: String
    public let waterMl: Double

    public init(model: String, waterMl: Double) {
        self.model = model
        self.waterMl = waterMl
    }
}

public enum HistoryInsights {
    /// Groups raw provider model names into the same auditable coefficient families used by the
    /// estimator, then identifies the model responsible for the most water in the period.
    public static func thirstiestModel(_ samples: [UsageSample], mode: WaterMode = .standard,
                                      region: String? = nil, coef: Coefficients) -> ModelWaterTotal? {
        var totals: [String: Double] = [:]
        for sample in samples {
            let model = WaterMath.modelKey(sample.model)
            totals[model, default: 0] += WaterMath.waterMl(
                sample, mode: mode, region: region, coef: coef
            )
        }
        guard let winner = totals.filter({ $0.value > 0 }).max(by: {
            $0.value == $1.value ? $0.key > $1.key : $0.value < $1.value
        }) else { return nil }
        return ModelWaterTotal(model: winner.key, waterMl: winner.value)
    }
}
