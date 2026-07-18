import XCTest
@testable import QuenchEngine

final class HydrationVesselTests: XCTestCase {
    func testPracticalDefaultsRemainInsideEditableBounds() {
        for vessel in HydrationVessel.allCases {
            XCTAssertTrue(vessel.allowedMl.contains(vessel.defaultMl))
        }
        XCTAssertEqual(HydrationVessel.officeCup.defaultMl, 180)
        XCTAssertEqual(HydrationVessel.bottleSip.defaultMl, 100)
    }

    func testCustomAmountsAreClampedPerVessel() {
        XCTAssertEqual(HydrationVessel.sip.clamped(0), 25)
        XCTAssertEqual(HydrationVessel.sip.clamped(900), 500)
        XCTAssertEqual(HydrationVessel.glass.clamped(20), 100)
        XCTAssertEqual(HydrationVessel.glass.clamped(900), 500)
        XCTAssertEqual(HydrationVessel.officeCup.clamped(175), 175)
    }
}
