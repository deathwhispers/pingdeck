import XCTest
import AppKit
@testable import PingDeck

final class NotchGeometryTests: XCTestCase {
    func testPhysicalNotchCalculation() {
        let screenFrame = CGRect(x: 0, y: 0, width: 1728, height: 1117)
        let safeAreaTopInset: CGFloat = 34
        let auxiliaryTopLeft = CGRect(x: 0, y: 1083, width: 778, height: 34)
        let auxiliaryTopRight = CGRect(x: 950, y: 1083, width: 778, height: 34)

        let geometry = NotchGeometry.calculate(
            screenFrame: screenFrame,
            safeAreaTopInset: safeAreaTopInset,
            auxiliaryTopLeft: auxiliaryTopLeft,
            auxiliaryTopRight: auxiliaryTopRight,
            expandedHeight: 200,
            expandedWidth: 380
        )

        XCTAssertTrue(geometry.hasPhysicalNotch)
        XCTAssertEqual(geometry.notchRect.origin.x, 778)
        XCTAssertEqual(geometry.notchRect.origin.y, 1083)
        XCTAssertEqual(geometry.notchRect.width, 172)
        XCTAssertEqual(geometry.notchRect.height, 34)

        XCTAssertEqual(geometry.collapsedPanelFrame, geometry.notchRect)
        XCTAssertEqual(geometry.expandedSize, CGSize(width: 380, height: 200))
        XCTAssertEqual(geometry.expandedPanelFrame.width, 380)
        XCTAssertEqual(geometry.expandedPanelFrame.height, 200)
        XCTAssertEqual(geometry.expandedPanelFrame.minY, 917)
        XCTAssertEqual(geometry.expandedPanelFrame.minX, 674)

        // 验证水平居中对齐
        XCTAssertEqual(geometry.expandedPanelFrame.midX, geometry.collapsedPanelFrame.midX)
        XCTAssertEqual(geometry.expandedPanelFrame.maxY, screenFrame.maxY)
        XCTAssertEqual(geometry.collapsedPanelFrame.maxY, screenFrame.maxY)
    }

    func testNonNotchScreenFallback() {
        let screenFrame = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        let safeAreaTopInset: CGFloat = 0
        let auxiliaryTopLeft: CGRect? = nil
        let auxiliaryTopRight: CGRect? = nil

        let geometry = NotchGeometry.calculate(
            screenFrame: screenFrame,
            safeAreaTopInset: safeAreaTopInset,
            auxiliaryTopLeft: auxiliaryTopLeft,
            auxiliaryTopRight: auxiliaryTopRight,
            expandedHeight: 200,
            expandedWidth: 380
        )

        XCTAssertFalse(geometry.hasPhysicalNotch)
        XCTAssertEqual(geometry.notchRect.origin.x, 880)
        XCTAssertEqual(geometry.notchRect.origin.y, 1048)
        XCTAssertEqual(geometry.notchRect.width, 160)
        XCTAssertEqual(geometry.notchRect.height, 32)

        XCTAssertEqual(geometry.collapsedPanelFrame, geometry.notchRect)
        XCTAssertEqual(geometry.expandedSize, CGSize(width: 380, height: 200))
        XCTAssertEqual(geometry.expandedPanelFrame.width, 380)
        XCTAssertEqual(geometry.expandedPanelFrame.height, 200)
        XCTAssertEqual(geometry.expandedPanelFrame.minY, 880)
        XCTAssertEqual(geometry.expandedPanelFrame.minX, 770)

        // 验证屏幕与折叠态完全居中
        XCTAssertEqual(geometry.expandedPanelFrame.midX, screenFrame.midX)
        XCTAssertEqual(geometry.collapsedPanelFrame.midX, screenFrame.midX)
        XCTAssertEqual(geometry.expandedPanelFrame.maxY, screenFrame.maxY)
        XCTAssertEqual(geometry.collapsedPanelFrame.maxY, screenFrame.maxY)
    }

    func testFallbackWhenSafeAreaTopInsetIsZero() {
        let screenFrame = CGRect(x: 0, y: 0, width: 2560, height: 1440)
        let safeAreaTopInset: CGFloat = 0
        let auxiliaryTopLeft = CGRect(x: 0, y: 1400, width: 1000, height: 40)
        let auxiliaryTopRight = CGRect(x: 1200, y: 1400, width: 1000, height: 40)

        let geometry = NotchGeometry.calculate(
            screenFrame: screenFrame,
            safeAreaTopInset: safeAreaTopInset,
            auxiliaryTopLeft: auxiliaryTopLeft,
            auxiliaryTopRight: auxiliaryTopRight
        )

        XCTAssertFalse(geometry.hasPhysicalNotch)
        XCTAssertEqual(geometry.notchRect.width, 160)
        XCTAssertEqual(geometry.notchRect.height, 32)
        XCTAssertEqual(geometry.notchRect.midX, screenFrame.midX)
    }

    func testFallbackWhenOneAuxiliaryAreaIsMissing() {
        let screenFrame = CGRect(x: 0, y: 0, width: 2560, height: 1440)
        let safeAreaTopInset: CGFloat = 34
        let auxiliaryTopLeft = CGRect(x: 0, y: 1406, width: 1000, height: 34)

        let geometry = NotchGeometry.calculate(
            screenFrame: screenFrame,
            safeAreaTopInset: safeAreaTopInset,
            auxiliaryTopLeft: auxiliaryTopLeft,
            auxiliaryTopRight: nil
        )

        XCTAssertFalse(geometry.hasPhysicalNotch)
        XCTAssertEqual(geometry.notchRect.width, 160)
        XCTAssertEqual(geometry.notchRect.height, 32)
        XCTAssertEqual(geometry.notchRect.midX, screenFrame.midX)
    }

    func testExpandedDimensionsClampedToNotchDimensions() {
        let screenFrame = CGRect(x: 0, y: 0, width: 1728, height: 1117)
        let safeAreaTopInset: CGFloat = 44
        let auxiliaryTopLeft = CGRect(x: 0, y: 1073, width: 700, height: 44)
        let auxiliaryTopRight = CGRect(x: 950, y: 1073, width: 700, height: 44)

        // notchWidth = 250, notchHeight = 44
        let geometry = NotchGeometry.calculate(
            screenFrame: screenFrame,
            safeAreaTopInset: safeAreaTopInset,
            auxiliaryTopLeft: auxiliaryTopLeft,
            auxiliaryTopRight: auxiliaryTopRight,
            expandedHeight: 30, // 小于 notchHeight 44
            expandedWidth: 200  // 小于 notchWidth 250
        )

        XCTAssertEqual(geometry.expandedSize.width, 250)
        XCTAssertEqual(geometry.expandedSize.height, 44)
        XCTAssertEqual(geometry.expandedPanelFrame.width, 250)
        XCTAssertEqual(geometry.expandedPanelFrame.height, 44)
        XCTAssertEqual(geometry.expandedPanelFrame.midX, geometry.collapsedPanelFrame.midX)
    }

    func testCalculateForNSScreen() {
        guard let screen = NSScreen.main else { return }
        let geometry = NotchGeometry.calculate(for: screen)

        XCTAssertGreaterThan(geometry.notchRect.width, 0)
        XCTAssertGreaterThan(geometry.notchRect.height, 0)
        XCTAssertEqual(geometry.collapsedPanelFrame, geometry.notchRect)
        XCTAssertEqual(geometry.expandedPanelFrame.midX, geometry.collapsedPanelFrame.midX)
        XCTAssertEqual(geometry.expandedPanelFrame.maxY, screen.frame.maxY)
        XCTAssertEqual(geometry.collapsedPanelFrame.maxY, screen.frame.maxY)
    }

    func testPhysicalNotchWithShowEarsTrue() {
        let screenFrame = CGRect(x: 0, y: 0, width: 1728, height: 1117)
        let safeAreaTopInset: CGFloat = 34
        let auxiliaryTopLeft = CGRect(x: 0, y: 1083, width: 778, height: 34)
        let auxiliaryTopRight = CGRect(x: 950, y: 1083, width: 778, height: 34)

        let geometry = NotchGeometry.calculate(
            screenFrame: screenFrame,
            safeAreaTopInset: safeAreaTopInset,
            auxiliaryTopLeft: auxiliaryTopLeft,
            auxiliaryTopRight: auxiliaryTopRight,
            expandedHeight: 200,
            expandedWidth: 380,
            showEars: true
        )

        XCTAssertTrue(geometry.hasPhysicalNotch)
        XCTAssertEqual(geometry.collapsedPanelFrame.width, 380)
        XCTAssertEqual(geometry.collapsedPanelFrame.height, 34)
        XCTAssertEqual(geometry.collapsedPanelFrame.midX, geometry.expandedPanelFrame.midX)
        XCTAssertEqual(geometry.collapsedPanelFrame.maxY, screenFrame.maxY)
    }
}
