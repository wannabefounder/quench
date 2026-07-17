import AppKit
import SwiftUI
import QuenchEngine

private enum WrappedCardFormat: String, CaseIterable, Hashable {
    case square = "Square"
    case story = "Story"

    var size: CGSize { self == .square ? CGSize(width: 540, height: 540) : CGSize(width: 360, height: 640) }
}

struct WrappedSettingsView: View {
    @ObservedObject var store: RaceStore
    @State private var period: WrappedPeriod = .week
    @State private var format: WrappedCardFormat = .square
    @State private var exportURL: URL?

    private var summary: WrappedSummary { store.wrappedSummary(for: period) }
    private var exportKey: String {
        "\(period.rawValue)-\(format.rawValue)-\(summary.trackedDays)-\(summary.userMl)-\(Int(summary.aiMl))"
    }

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Picker("Period", selection: $period) {
                    ForEach(WrappedPeriod.allCases, id: \.self) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                Picker("Format", selection: $format) {
                    ForEach(WrappedCardFormat.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .frame(width: 150)
            }

            if summary.trackedDays == 0 {
                ContentUnavailableView(
                    "Nothing to wrap yet", systemImage: "sparkles.rectangle.stack",
                    description: Text("Your private daily race summaries will become shareable here.")
                )
                .frame(maxHeight: .infinity)
            } else {
                WrappedCardView(summary: summary)
                    .aspectRatio(format.size.width / format.size.height, contentMode: .fit)
                    .frame(maxHeight: 330)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .shadow(color: .blue.opacity(0.18), radius: 18, y: 8)

                HStack {
                    Label("Generated locally • contains totals only", systemImage: "lock.fill")
                        .font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    if let exportURL {
                        ShareLink(item: exportURL) {
                            Label("Share image", systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(.borderedProminent)
                    } else {
                        ProgressView().controlSize(.small)
                    }
                }
            }
        }
        .padding(20)
        .task(id: exportKey) {
            guard summary.trackedDays > 0 else { exportURL = nil; return }
            exportURL = WrappedExportService.render(summary: summary, format: format)
        }
    }
}

struct WrappedCardView: View {
    let summary: WrappedSummary

    var body: some View {
        GeometryReader { geometry in
            let unit = geometry.size.width / 540
            ZStack {
                LinearGradient(colors: [Color(red: 0.03, green: 0.12, blue: 0.24),
                                        Color(red: 0.02, green: 0.42, blue: 0.58)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                Circle().fill(.cyan.opacity(0.18)).frame(width: 360 * unit)
                    .offset(x: 180 * unit, y: -190 * unit)
                Circle().fill(.blue.opacity(0.2)).frame(width: 280 * unit)
                    .offset(x: -210 * unit, y: 220 * unit)

                VStack(alignment: .leading, spacing: 18 * unit) {
                    HStack {
                        Label("QUENCH", systemImage: "drop.fill")
                            .font(.system(size: 18 * unit, weight: .bold, design: .rounded))
                        Spacer()
                        Text("\(summary.period.title.uppercased()) WRAPPED")
                            .font(.system(size: 13 * unit, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(.white.opacity(0.9))

                    Spacer()
                    Text("Your AI drank")
                        .font(.system(size: 24 * unit, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.72))
                    Text(volume(summary.aiMl))
                        .font(.system(size: 72 * unit, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .minimumScaleFactor(0.6)
                    Text(comparison)
                        .font(.system(size: 20 * unit, weight: .semibold, design: .rounded))
                        .foregroundStyle(.cyan)

                    Spacer()
                    HStack(spacing: 28 * unit) {
                        metric("YOU DRANK", volume(Double(summary.userMl)))
                        metric("DAYS WON", "\(summary.userWinDays)/\(summary.trackedDays)")
                        metric("STREAK", "\(summary.streak.winDays) days")
                    }
                    Text("Estimates use Quench's open Scope 1+2 methodology. No conversation content.")
                        .font(.system(size: 11 * unit, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.55))
                }
                .padding(34 * unit)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(summary.period.title) AI Water Wrapped. AI used \(volume(summary.aiMl)). You drank \(volume(Double(summary.userMl))). You won \(summary.userWinDays) of \(summary.trackedDays) tracked days.")
    }

    private func metric(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label).font(.caption2.weight(.bold)).foregroundStyle(.white.opacity(0.55))
            Text(value).font(.headline.weight(.bold)).foregroundStyle(.white)
        }
    }
    private func volume(_ ml: Double) -> String {
        ml >= 1000 ? String(format: "%.1f L", ml / 1000) : "\(Int(ml.rounded())) mL"
    }
    private var comparison: String {
        if summary.aiMl >= 65_000 { return "≈ \(Int((summary.aiMl / 65_000).rounded())) showers" }
        return "≈ \(max(1, Int((summary.aiMl / 750).rounded()))) reusable bottles"
    }
}

@MainActor
private enum WrappedExportService {
    static func render(summary: WrappedSummary, format: WrappedCardFormat) -> URL? {
        let size = format.size
        let renderer = ImageRenderer(content: WrappedCardView(summary: summary)
            .frame(width: size.width, height: size.height))
        renderer.proposedSize = ProposedViewSize(size)
        renderer.scale = 2
        guard let image = renderer.nsImage,
              let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let png = bitmap.representation(using: .png, properties: [:]) else { return nil }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("quench-\(summary.period.title.lowercased())-wrapped-\(format.rawValue.lowercased()).png")
        do { try png.write(to: url, options: .atomic); return url }
        catch { return nil }
    }
}
