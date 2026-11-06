import XCTest
@testable import PingDeck

final class LocalizationInfrastructureTests: XCTestCase {
    func testGeneratedStringSymbolResolves() {
        XCTAssertEqual(String(localized: L10n.appNameSmoke), "PingDeck")
    }
}
