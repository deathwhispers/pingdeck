import XCTest

final class LocalizationCatalogStructureTests: XCTestCase {
    private struct Catalog: Decodable {
        struct Entry: Decodable {
            struct Localization: Decodable {
                struct StringUnit: Decodable { let value: String }
                let stringUnit: StringUnit?
            }
            let comment: String?
            let extractionState: String?
            let localizations: [String: Localization]?
        }
        let sourceLanguage: String
        let strings: [String: Entry]
    }

    private func catalogURL() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Sources/PingDeck/Resources/Localizable.xcstrings")
    }

    func testEveryKeyHasChineseSourceAndComment() throws {
        let data = try Data(contentsOf: catalogURL())
        let catalog = try JSONDecoder().decode(Catalog.self, from: data)

        XCTAssertEqual(catalog.sourceLanguage, "zh-Hans")
        XCTAssertFalse(catalog.strings.isEmpty)

        for (key, entry) in catalog.strings {
            XCTAssertEqual(entry.extractionState, "manual", "\(key) 必须标记为 manual")
            XCTAssertFalse(entry.comment?.isEmpty ?? true, "\(key) 缺少 comment")
            let value = entry.localizations?["zh-Hans"]?.stringUnit?.value
            XCTAssertFalse(value?.isEmpty ?? true, "\(key) 缺少 zh-Hans 文案")
        }
    }
}
