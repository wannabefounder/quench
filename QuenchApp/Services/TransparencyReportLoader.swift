import Foundation
import QuenchEngine

enum TransparencyReportLoader {
    static func load() -> ProviderTransparencyReport? {
        let sourceTreeURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Resources/provider-transparency.json")
        let candidates = [Bundle.main.url(
            forResource: "provider-transparency", withExtension: "json"), sourceTreeURL]
        for url in candidates.compactMap({ $0 }) {
            guard let data = try? Data(contentsOf: url), data.count <= 500_000,
                  let report = try? ProviderTransparencyReport.load(from: data),
                  report.isValid else { continue }
            return report
        }
        return nil
    }
}
