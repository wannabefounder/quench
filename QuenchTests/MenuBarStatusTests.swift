import XCTest
@testable import QuenchEngine

final class MenuBarStatusTests: XCTestCase {
    func testCompactStatsStayReadable() {
        XCTAssertEqual(MenuBarStatus.stats(userMl: 750, aiMl: 18.4), "AI 18 mL · You 750 mL")
        XCTAssertEqual(MenuBarStatus.stats(userMl: 1_250, aiMl: 12_540), "AI 13 L · You 1.3 L")
    }

    func testAIEventExplainsTheChange() {
        XCTAssertEqual(MenuBarStatus.aiDrank(deltaMl: 2.4), "AI just drank 2 mL")
        XCTAssertEqual(MenuBarStatus.aiDrank(deltaMl: 1_250), "AI just drank 1.3 L")
    }

    func testNegativeValuesNeverLeakIntoStatus() {
        XCTAssertEqual(MenuBarStatus.compactMilliliters(-20), "0 mL")
    }
}
