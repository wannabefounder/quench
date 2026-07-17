import Foundation
import QuenchEngine
import UserNotifications

final class HydrationNotificationService {
    private let center: UNUserNotificationCenter
    private let defaults: UserDefaults

    init(center: UNUserNotificationCenter = .current(), defaults: UserDefaults = .standard) {
        self.center = center
        self.defaults = defaults
    }

    /// UserNotifications requires a real application bundle and throws an Objective-C exception
    /// when initialized from SwiftPM's raw executable. Keep terminal development launches safe.
    static func makeIfAvailable(defaults: UserDefaults = .standard) -> HydrationNotificationService? {
        guard Bundle.main.bundleURL.pathExtension == "app", Bundle.main.bundleIdentifier != nil else {
            return nil
        }
        return HydrationNotificationService(center: .current(), defaults: defaults)
    }

    func requestPermission() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert])) ?? false
    }

    func consider(userMl: Int, aiMl: Double, now: Date = Date(), calendar: Calendar = .current) async {
        let state = savedState()
        guard HydrationNudgePolicy.shouldSend(now: now, userMl: Double(userMl), aiMl: aiMl,
                                              state: state, calendar: calendar) else { return }
        let lead = max(0, Int(aiMl) - userMl)
        let content = UNMutableNotificationContent()
        content.title = "Your AI is \(lead) mL ahead"
        content.body = "A glass of water puts you back in the race."
        content.interruptionLevel = .passive
        do {
            try await center.add(UNNotificationRequest(
                identifier: "quench-hydration-\(UUID().uuidString)", content: content, trigger: nil
            ))
            saveSent(now: now, calendar: calendar, previous: state)
        } catch {
            // Notification failures are intentionally silent; the menu-bar race remains primary.
        }
    }

    private func savedState() -> HydrationNudgeState? {
        guard let day = defaults.string(forKey: "hydrationNudgeDay") else { return nil }
        let timestamp = defaults.double(forKey: "hydrationNudgeLastSent")
        return HydrationNudgeState(
            day: day, sentCount: defaults.integer(forKey: "hydrationNudgeCount"),
            lastSent: timestamp > 0 ? Date(timeIntervalSince1970: timestamp) : nil
        )
    }

    private func saveSent(now: Date, calendar: Calendar, previous: HydrationNudgeState?) {
        let day = RaceEngine.dayKey(for: now, calendar: calendar)
        let count = previous?.day == day ? (previous?.sentCount ?? 0) + 1 : 1
        defaults.set(day, forKey: "hydrationNudgeDay")
        defaults.set(count, forKey: "hydrationNudgeCount")
        defaults.set(now.timeIntervalSince1970, forKey: "hydrationNudgeLastSent")
    }
}
