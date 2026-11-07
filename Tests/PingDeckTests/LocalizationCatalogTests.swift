import XCTest

final class LocalizationCatalogTests: XCTestCase {
    private struct Catalog: Decodable {
        struct Entry: Decodable {
            struct Localization: Decodable {
                struct StringUnit: Decodable { let value: String }
                let stringUnit: StringUnit?
            }
            let comment: String?
            let localizations: [String: Localization]?
        }
        let sourceLanguage: String
        let strings: [String: Entry]
    }

    private let languages = ["en", "zh-Hans", "ja"]

    private func catalogURL() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Sources/PingDeck/Resources/Localizable.xcstrings")
    }

    private func formatSpecifiers(in value: String) -> [String] {
        let pattern = #"%([0-9]+\$)?[-+0-9.l]*([@df])"#
        let regex = try! NSRegularExpression(pattern: pattern)
        let range = NSRange(value.startIndex..., in: value)
        return regex.matches(in: value, range: range).compactMap { match in
            guard let typeRange = Range(match.range(at: 2), in: value) else { return nil }
            return String(value[typeRange])
        }.sorted()
    }

    func testEveryKeyHasAllLanguagesAndMatchingPlaceholders() throws {
        let data = try Data(contentsOf: catalogURL())
        let catalog = try JSONDecoder().decode(Catalog.self, from: data)

        XCTAssertEqual(catalog.sourceLanguage, "zh-Hans")
        XCTAssertFalse(catalog.strings.isEmpty)

        for (key, entry) in catalog.strings {
            XCTAssertFalse(entry.comment?.isEmpty ?? true, "\(key) 缺少 comment")

            var values: [String] = []
            for language in languages {
                let value = entry.localizations?[language]?.stringUnit?.value
                XCTAssertFalse(value?.isEmpty ?? true, "\(key) 缺少 \(language) 文案")
                if let value { values.append(value) }
            }

            let expected = values.first.map(formatSpecifiers(in:)) ?? []
            for value in values.dropFirst() {
                XCTAssertEqual(
                    formatSpecifiers(in: value),
                    expected,
                    "\(key) 的格式占位符不一致：\(value)"
                )
            }
        }
    }
}
