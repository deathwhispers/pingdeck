import XCTest
@testable import PingCore

final class TargetValidatorTests: XCTestCase {
    func testRejectsEmpty() {
        XCTAssertEqual(TargetValidator.validate("   "), .empty)
    }

    func testRejectsProtocolPrefix() {
        XCTAssertEqual(TargetValidator.validate("http://example.com"), .protocolPrefix)
    }

    func testRejectsPath() {
        XCTAssertEqual(TargetValidator.validate("example.com/path"), .path)
    }

    func testRejectsWhitespace() {
        XCTAssertEqual(TargetValidator.validate("example com"), .whitespace)
    }

    func testRejectsInvalidCharacters() {
        XCTAssertEqual(TargetValidator.validate("example!.com"), .invalidCharacters)
    }

    func testAcceptsHostnameAndIPv6() {
        XCTAssertNil(TargetValidator.validate("example.com"))
        XCTAssertNil(TargetValidator.validate("2001:db8::1"))
    }
}
