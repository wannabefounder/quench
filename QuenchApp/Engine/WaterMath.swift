import Foundation
#if canImport(Glibc)
import Glibc
#elseif canImport(Darwin)
import Darwin
#endif

// Pure water math. No SwiftUI, no DB. Mirrors the EcoLogits methodology:
// facility energy -> water via WCF = E x [WUE_onsite / PUE + WUE_offsite] over three scopes.
// All coefficients come from coefficients.json (Coefficients); nothing hardcoded here.

/// One normalized usage event, decoupled from the GRDB record so the Engine stays pure.
public struct UsageSample: Equatable {
    public var model: String?
    public var inputTokens: Int?
    public var outputTokens: Int?
    public var messageCount: Int?
    public var minutesActive: Double?
    public init(model: String? = nil, inputTokens: Int? = nil, outputTokens: Int? = nil,
                messageCount: Int? = nil, minutesActive: Double? = nil) {
        self.model = model; self.inputTokens = inputTokens; self.outputTokens = outputTokens
        self.messageCount = messageCount; self.minutesActive = minutesActive
    }
}

/// conservative = on-site cooling only (Scope 1). standard = + electricity generation (Scope 2).
/// full = + embodied/lifecycle share (Scope 3). These are the honest range, not one "true" number.
public enum WaterMode: String, CaseIterable { case conservative, standard, full }

// MARK: - Coefficients (decoded from coefficients.json)

public struct Coefficients: Decodable {
    public struct EnergyCoef: Decodable {
        public let fixed_wh: Double, input: Double, output: Double
        public init(fixed_wh: Double, input: Double, output: Double) {
            self.fixed_wh = fixed_wh; self.input = input; self.output = output
        }
    }
    public struct ParamFallback: Decodable {
        public let alpha: Double, beta: Double, gamma: Double, batch: Double, system_overhead: Double
        public let model_active_params_b: [String: Double]
    }
    public struct Energy: Decodable {
        public let wh_per_1k_tokens: [String: EnergyCoef]
        public let param_fallback: ParamFallback
    }
    public struct Provider: Decodable { public let wue_onsite: Double, pue: Double }
    public struct Region: Decodable { public let wue_offsite: Double; public let label: String? }
    public struct Water: Decodable {
        public let default_provider: String, default_region: String, default_mode: String
        public let embodied_fraction: Double
        public let providers: [String: Provider]
        public let regions: [String: Region]
    }
    public struct MsgFallback: Decodable { public let avg_input_tokens: Double, avg_output_tokens: Double }
    public struct MinFallback: Decodable { public let messages_per_minute: Double }

    public let version: String
    public let energy: Energy
    public let water: Water
    public let message_fallback: MsgFallback
    public let minutes_fallback: MinFallback

    public static func load(from data: Data) throws -> Coefficients {
        try JSONDecoder().decode(Coefficients.self, from: data)
    }

    /// Minimal built-in fallback so the app never crashes if the bundled JSON is missing.
    public static let fallback: Coefficients = {
        let json = """
        {"version":"fallback",
         "energy":{"wh_per_1k_tokens":{"default":{"fixed_wh":0.08,"input":0.05,"output":0.90}},
          "param_fallback":{"alpha":1.17e-6,"beta":-1.12e-2,"gamma":4.05e-5,"batch":64,
            "system_overhead":12,"model_active_params_b":{}}},
         "water":{"default_provider":"default","default_region":"global","default_mode":"standard",
          "embodied_fraction":0.12,
          "providers":{"default":{"wue_onsite":0.40,"pue":1.20}},
          "regions":{"global":{"wue_offsite":3.00,"label":"Global average"}}},
         "message_fallback":{"avg_input_tokens":300,"avg_output_tokens":350},
         "minutes_fallback":{"messages_per_minute":0.8}}
        """
        return try! load(from: Data(json.utf8))
    }()
}

// MARK: - Water math (pure)

public enum WaterMath {

    /// Map any raw model string to a coefficient key by substring (order matters).
    public static func modelKey(_ raw: String?) -> String {
        guard let m = raw?.lowercased(), !m.isEmpty else { return "default" }
        if m.contains("4o-mini") || m.contains("4o mini") { return "gpt-4o-mini" }
        if m.contains("nano") { return "gpt-4.1-nano" }
        if m.contains("o3") || m.contains("o4") || m.contains("reasoning") || m.contains("thinking") { return "o3" }
        if m.contains("gpt-5") { return "gpt-5" }
        if m.contains("gpt-4") || m.contains("gpt") || m.contains("chatgpt") { return "gpt-4o" }
        if m.contains("opus") { return "claude-opus" }
        if m.contains("haiku") { return "claude-haiku" }
        if m.contains("sonnet") || m.contains("claude") { return "claude-sonnet" }
        if m.contains("gemini") || m.contains("bard") { return "gemini" }
        if m.contains("deepseek") || m.contains("r1") { return "deepseek-r1" }
        if m.contains("llama") || m.contains("405") { return "llama-405b" }
        if m.contains("qwen") || m.contains("gemma") || m.contains("phi") || m.contains("mistral") || m.contains("small") { return "small-open-model" }
        return "default"
    }

    public static func providerKey(forModel key: String) -> String {
        switch key {
        case "gpt-4o", "gpt-4o-mini", "gpt-4.1-nano", "gpt-5", "o3": return "openai"
        case "claude-sonnet", "claude-opus", "claude-haiku": return "anthropic"
        case "gemini": return "google"
        case "deepseek-r1": return "deepseek"
        case "llama-405b": return "meta"
        default: return "default"
        }
    }

    /// EcoLogits GPU energy model, used only for models absent from the table.
    static func paramEnergyPer1k(_ pActiveB: Double, _ pf: Coefficients.ParamFallback) -> Double {
        let fE = pf.alpha * exp(pf.beta * pf.batch) * pActiveB + pf.gamma // Wh / output token
        return fE * pf.system_overhead * 1000.0                          // Wh / 1k output tokens
    }

    static func energyCoef(_ key: String, _ coef: Coefficients) -> Coefficients.EnergyCoef {
        if let c = coef.energy.wh_per_1k_tokens[key] { return c }
        if let p = coef.energy.param_fallback.model_active_params_b[key] {
            let out = paramEnergyPer1k(p, coef.energy.param_fallback)
            return .init(fixed_wh: 0.08, input: out * 0.05, output: out)
        }
        return coef.energy.wh_per_1k_tokens["default"] ?? .init(fixed_wh: 0.08, input: 0.05, output: 0.90)
    }

    /// Facility-level energy (Wh) for one event. PUE is already baked into the coefficients.
    public static func energyWh(_ s: UsageSample, coef: Coefficients) -> Double {
        let c = energyCoef(modelKey(s.model), coef)
        if s.inputTokens != nil || s.outputTokens != nil {
            let inT = Double(s.inputTokens ?? 0), outT = Double(s.outputTokens ?? 0)
            return c.fixed_wh + inT / 1000.0 * c.input + outT / 1000.0 * c.output
        }
        let mf = coef.message_fallback
        let perMsg = c.fixed_wh + mf.avg_input_tokens / 1000.0 * c.input + mf.avg_output_tokens / 1000.0 * c.output
        if let mc = s.messageCount { return Double(mc) * perMsg }
        if let mins = s.minutesActive { return mins * coef.minutes_fallback.messages_per_minute * perMsg }
        return 0
    }

    /// Water (mL) for one event. Our energy coefficients are facility-level (PUE included), while
    /// EcoLogits applies on-site WUE to server energy and off-site WUE to facility energy:
    /// WCF = E_facility x [WUE_onsite / PUE + WUE_offsite].
    public static func waterMl(_ s: UsageSample, mode: WaterMode = .standard,
                               region: String? = nil, coef: Coefficients) -> Double {
        let e = energyWh(s, coef: coef)
        if e <= 0 { return 0 }
        let key = modelKey(s.model)
        let prov = coef.water.providers[providerKey(forModel: key)]
            ?? coef.water.providers["default"] ?? .init(wue_onsite: 0.40, pue: 1.20)
        let regionKey = region ?? coef.water.default_region
        let reg = coef.water.regions[regionKey] ?? coef.water.regions[coef.water.default_region]
            ?? .init(wue_offsite: 3.0, label: nil)
        let eKwh = e / 1000.0
        let onsite = eKwh / max(prov.pue, 1.0) * prov.wue_onsite
        let offsite = eKwh * reg.wue_offsite
        let liters: Double
        switch mode {
        case .conservative: liters = onsite
        case .standard:     liters = onsite + offsite
        case .full:         liters = (onsite + offsite) * (1.0 + coef.water.embodied_fraction)
        }
        return liters * 1000.0 // L -> mL
    }

    /// (low, mid, high) = (conservative, standard, full) for the honest range shown in-app.
    public static func waterRange(_ s: UsageSample, region: String? = nil,
                                  coef: Coefficients) -> (low: Double, mid: Double, high: Double) {
        (waterMl(s, mode: .conservative, region: region, coef: coef),
         waterMl(s, mode: .standard, region: region, coef: coef),
         waterMl(s, mode: .full, region: region, coef: coef))
    }

    /// Total water (mL) across many events — what RaceEngine uses for the day.
    public static func totalWaterMl(_ samples: [UsageSample], mode: WaterMode = .standard,
                                    region: String? = nil, coef: Coefficients) -> Double {
        samples.reduce(0) { $0 + waterMl($1, mode: mode, region: region, coef: coef) }
    }
}
