import XCTest
@testable import QuenchEngine

final class NativeHostManifestTests: XCTestCase {
    private let validID = "abcdefghijklmnopabcdefghijklmnop"

    func testExtensionIDAllowsOnlyChromeAlphabet() {
        XCTAssertTrue(NativeHostManifestBuilder.isValidExtensionID(validID))
        XCTAssertFalse(NativeHostManifestBuilder.isValidExtensionID("short"))
        XCTAssertFalse(NativeHostManifestBuilder.isValidExtensionID(
            "abcdefghijklmnopabcdefghijklmnoq"))
        XCTAssertFalse(NativeHostManifestBuilder.isValidExtensionID(
            "../../../../tmp/bridge-injection"))
    }

    func testManifestContainsOnlyLocalBridgeContract() throws {
        let data = try NativeHostManifestBuilder.data(
            extensionID: validID,
            bridgePath: "/Applications/Quench.app/Contents/Helpers/QuenchBrowserBridge"
        )
        let manifest = try JSONDecoder().decode(NativeHostManifest.self, from: data)
        XCTAssertEqual(manifest.name, "app.quench.browser_bridge")
        XCTAssertEqual(manifest.type, "stdio")
        XCTAssertEqual(manifest.allowed_origins, ["chrome-extension://\(validID)/"])
        XCTAssertEqual(manifest.path,
                       "/Applications/Quench.app/Contents/Helpers/QuenchBrowserBridge")
    }

    func testRoundTripsExtensionIDAndRejectsRelativeBridge() throws {
        let data = try NativeHostManifestBuilder.data(
            extensionID: validID, bridgePath: "/tmp/QuenchBrowserBridge")
        XCTAssertEqual(NativeHostManifestBuilder.extensionID(from: data), validID)
        XCTAssertThrowsError(try NativeHostManifestBuilder.data(
            extensionID: validID, bridgePath: "relative/bridge"))
    }
}
