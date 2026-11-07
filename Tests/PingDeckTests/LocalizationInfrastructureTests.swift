import XCTest
@testable import PingDeck

final class LocalizationInfrastructureTests: XCTestCase {
    /// 生成符号必须指向 Localizable 表；运行时查找由 Catalog 覆盖率测试和
    /// 实际 App 启动验证覆盖，避免测试进程的资源路径/语言影响结果。
    func testGeneratedStringSymbolPointsAtCatalog() {
        XCTAssertEqual(L10n.appNameSmoke.table, "Localizable")
    }
}
