import XCTest
@testable import QuenchEngine

final class ActivityProxyPolicyTests: XCTestCase {
    func testRecognizesOnlySupportedDesktopApps() {
        XCTAssertEqual(ActivityProxyPolicy.model(forBundleIdentifier: "com.openai.chat"), "chatgpt")
        XCTAssertEqual(ActivityProxyPolicy.model(forBundleIdentifier: "com.anthropic.claudefordesktop"),
                       "claude-sonnet")
        XCTAssertNil(ActivityProxyPolicy.model(forBundleIdentifier: "com.apple.Safari"))
        XCTAssertNil(ActivityProxyPolicy.model(forBundleIdentifier: nil))
    }

    func testIgnoresFocusFlickerAndCapsSleepGap() {
        let start = Date(timeIntervalSince1970: 100)
        XCTAssertNil(ActivityProxyPolicy.billableMinutes(
            from: start, to: start.addingTimeInterval(14.9)))
        XCTAssertEqual(ActivityProxyPolicy.billableMinutes(
            from: start, to: start.addingTimeInterval(60)) ?? 0, 1, accuracy: 1e-9)
        XCTAssertEqual(ActivityProxyPolicy.billableMinutes(
            from: start, to: start.addingTimeInterval(3_600)) ?? 0, 2, accuracy: 1e-9)
    }
}
