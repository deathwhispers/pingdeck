// Auto-generated from Sources/PingDeck/Resources/Localizable.xcstrings.
// Run scripts/generate-localization-symbols.sh after changing the catalog.
// Do not edit manually.

import Foundation

private nonisolated let l10nBundle = Foundation.Bundle.module
private nonisolated let l10nBundleDescription = LocalizedStringResource.BundleDescription.atURL(l10nBundle.bundleURL)

enum L10n {
    /**
     Add target alert fallback message
     
     Localized string for key “alert.addFailed.defaultMessage” in table “Localizable.xcstrings”.
     */
    static var alertAddFailedDefaultMessage: LocalizedStringResource {
        LocalizedStringResource("alert.addFailed.defaultMessage", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Build-time smoke test for generated String Catalog symbols.
     
     Localized string for key “app.name.smoke” in table “Localizable.xcstrings”.
     */
    static var appNameSmoke: LocalizedStringResource {
        LocalizedStringResource("app.name.smoke", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Bulk import: duplicate target
     
     Localized string for key “import.rejected.duplicate” in table “Localizable.xcstrings”.
     */
    static var importRejectedDuplicate: LocalizedStringResource {
        LocalizedStringResource("import.rejected.duplicate", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Bulk import: rejected line with line number, text and reason
     
     Localized string for key “import.rejected.line” in table “Localizable.xcstrings”.
     */
    static func importRejectedLine(_ arg1: Int, _ arg2: String, _ arg3: String) -> LocalizedStringResource {
        LocalizedStringResource("import.rejected.line", defaultValue: "\(arg1, specifier: "%lld")\(arg2)\(arg3)", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     IP range parsing: CIDR host bits set
     
     Localized string for key “range.cidrNotNetworkAddress” in table “Localizable.xcstrings”.
     */
    static var rangeCidrNotNetworkAddress: LocalizedStringResource {
        LocalizedStringResource("range.cidrNotNetworkAddress", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     IP range parsing: end address before start
     
     Localized string for key “range.endBeforeStart” in table “Localizable.xcstrings”.
     */
    static var rangeEndBeforeStart: LocalizedStringResource {
        LocalizedStringResource("range.endBeforeStart", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     IP range parsing: IPv6 CIDR unsupported
     
     Localized string for key “range.ipv6Unsupported” in table “Localizable.xcstrings”.
     */
    static var rangeIpv6Unsupported: LocalizedStringResource {
        LocalizedStringResource("range.ipv6Unsupported", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     IP range parsing: malformed explicit range
     
     Localized string for key “range.malformed” in table “Localizable.xcstrings”.
     */
    static var rangeMalformed: LocalizedStringResource {
        LocalizedStringResource("range.malformed", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     IP range parsing: malformed CIDR
     
     Localized string for key “range.malformedCIDR” in table “Localizable.xcstrings”.
     */
    static var rangeMalformedCIDR: LocalizedStringResource {
        LocalizedStringResource("range.malformedCIDR", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     IP range parsing: range exceeds max addresses
     
     Localized string for key “range.tooLarge” in table “Localizable.xcstrings”.
     */
    static func rangeTooLarge(_ arg1: Int) -> LocalizedStringResource {
        LocalizedStringResource("range.tooLarge", defaultValue: "\(arg1, specifier: "%lld")", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Target validation: empty input
     
     Localized string for key “validation.empty” in table “Localizable.xcstrings”.
     */
    static var validationEmpty: LocalizedStringResource {
        LocalizedStringResource("validation.empty", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Target validation: invalid characters
     
     Localized string for key “validation.invalidCharacters” in table “Localizable.xcstrings”.
     */
    static var validationInvalidCharacters: LocalizedStringResource {
        LocalizedStringResource("validation.invalidCharacters", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Target validation: path in host
     
     Localized string for key “validation.path” in table “Localizable.xcstrings”.
     */
    static var validationPath: LocalizedStringResource {
        LocalizedStringResource("validation.path", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Target validation: protocol prefix
     
     Localized string for key “validation.protocolPrefix” in table “Localizable.xcstrings”.
     */
    static var validationProtocolPrefix: LocalizedStringResource {
        LocalizedStringResource("validation.protocolPrefix", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Target validation: whitespace in host
     
     Localized string for key “validation.whitespace” in table “Localizable.xcstrings”.
     */
    static var validationWhitespace: LocalizedStringResource {
        LocalizedStringResource("validation.whitespace", table: "Localizable", bundle: l10nBundleDescription)
    }
}
