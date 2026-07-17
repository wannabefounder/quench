import XCTest
@testable import QuenchEngine

final class SourceHealthTests: XCTestCase {
    func testNotFoundWhenNoLogsExist() {
        XCTAssertEqual(status(files: 0, events: 0, errors: 0).state, .notFound)
    }

    func testDisabledTakesPriority() {
        let source = LocalSourceStatus(source: "fixture", displayName: "Fixture", fileCount: 2,
                                       eventCount: 5, errorCount: 1, lastEvent: nil,
                                       isEnabled: false)
        XCTAssertEqual(source.state, .disabled)
    }

    func testWatchingWhenLogsExistWithoutUsageYet() {
        XCTAssertEqual(status(files: 2, events: 0, errors: 0).state, .watching)
    }

    func testTrackingWhenUsageWasIngested() {
        XCTAssertEqual(status(files: 1, events: 5, errors: 0).state, .tracking)
    }

    func testErrorsTakePriorityOverOtherStates() {
        XCTAssertEqual(status(files: 2, events: 5, errors: 1).state, .needsAttention)
    }

    private func status(files: Int, events: Int, errors: Int) -> LocalSourceStatus {
        LocalSourceStatus(source: "fixture", displayName: "Fixture", fileCount: files,
                          eventCount: events, errorCount: errors, lastEvent: nil)
    }
}
