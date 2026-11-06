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
     Generic error alert title
     
     Localized string for key “alert.error.title” in table “Localizable.xcstrings”.
     */
    static var alertErrorTitle: LocalizedStringResource {
        LocalizedStringResource("alert.error.title", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Build-time smoke test for generated String Catalog symbols.
     
     Localized string for key “app.name.smoke” in table “Localizable.xcstrings”.
     */
    static var appNameSmoke: LocalizedStringResource {
        LocalizedStringResource("app.name.smoke", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Ping engine: failed to launch probe for host
     
     Localized string for key “engine.launchFailed” in table “Localizable.xcstrings”.
     */
    static func engineLaunchFailed(_ arg1: String, _ arg2: String) -> LocalizedStringResource {
        LocalizedStringResource("engine.launchFailed", defaultValue: "\(arg1)\(arg2)", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Ping engine: ping process exited with non-zero code
     
     Localized string for key “engine.processExited” in table “Localizable.xcstrings”.
     */
    static func engineProcessExited(_ arg1: Int) -> LocalizedStringResource {
        LocalizedStringResource("engine.processExited", defaultValue: "\(arg1, specifier: "%lld")", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Export column: average latency
     
     Localized string for key “export.column.averageLatency” in table “Localizable.xcstrings”.
     */
    static var exportColumnAverageLatency: LocalizedStringResource {
        LocalizedStringResource("export.column.averageLatency", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Export column: latest latency
     
     Localized string for key “export.column.lastLatency” in table “Localizable.xcstrings”.
     */
    static var exportColumnLastLatency: LocalizedStringResource {
        LocalizedStringResource("export.column.lastLatency", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Export column: last response time
     
     Localized string for key “export.column.lastResponse” in table “Localizable.xcstrings”.
     */
    static var exportColumnLastResponse: LocalizedStringResource {
        LocalizedStringResource("export.column.lastResponse", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Export column: loss rate
     
     Localized string for key “export.column.lossRate” in table “Localizable.xcstrings”.
     */
    static var exportColumnLossRate: LocalizedStringResource {
        LocalizedStringResource("export.column.lossRate", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Export column: maximum latency
     
     Localized string for key “export.column.maxLatency” in table “Localizable.xcstrings”.
     */
    static var exportColumnMaxLatency: LocalizedStringResource {
        LocalizedStringResource("export.column.maxLatency", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Export column: minimum latency
     
     Localized string for key “export.column.minLatency” in table “Localizable.xcstrings”.
     */
    static var exportColumnMinLatency: LocalizedStringResource {
        LocalizedStringResource("export.column.minLatency", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Export column: note
     
     Localized string for key “export.column.note” in table “Localizable.xcstrings”.
     */
    static var exportColumnNote: LocalizedStringResource {
        LocalizedStringResource("export.column.note", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Export column: status
     
     Localized string for key “export.column.status” in table “Localizable.xcstrings”.
     */
    static var exportColumnStatus: LocalizedStringResource {
        LocalizedStringResource("export.column.status", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Export column: host
     
     Localized string for key “export.column.target” in table “Localizable.xcstrings”.
     */
    static var exportColumnTarget: LocalizedStringResource {
        LocalizedStringResource("export.column.target", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Markdown export timestamp label
     
     Localized string for key “export.markdown.exportedAt” in table “Localizable.xcstrings”.
     */
    static var exportMarkdownExportedAt: LocalizedStringResource {
        LocalizedStringResource("export.markdown.exportedAt", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Markdown export title
     
     Localized string for key “export.markdown.title” in table “Localizable.xcstrings”.
     */
    static var exportMarkdownTitle: LocalizedStringResource {
        LocalizedStringResource("export.markdown.title", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Export summary line
     
     Localized string for key “export.summary” in table “Localizable.xcstrings”.
     */
    static func exportSummary(_ arg1: Int, _ arg2: Int, _ arg3: Int, _ arg4: Int) -> LocalizedStringResource {
        LocalizedStringResource("export.summary", defaultValue: "\(arg1, specifier: "%lld")\(arg2, specifier: "%lld")\(arg3, specifier: "%lld")\(arg4, specifier: "%lld")", table: "Localizable", bundle: l10nBundleDescription)
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
     Ping process: system ping executable not found
     
     Localized string for key “ping.error.executableNotFound” in table “Localizable.xcstrings”.
     */
    static func pingErrorExecutableNotFound(_ arg1: String) -> LocalizedStringResource {
        LocalizedStringResource("ping.error.executableNotFound", defaultValue: "\(arg1)", table: "Localizable", bundle: l10nBundleDescription)
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
     Target status: alive
     
     Localized string for key “status.alive” in table “Localizable.xcstrings”.
     */
    static var statusAlive: LocalizedStringResource {
        LocalizedStringResource("status.alive", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Target status: disabled
     
     Localized string for key “status.disabled” in table “Localizable.xcstrings”.
     */
    static var statusDisabled: LocalizedStringResource {
        LocalizedStringResource("status.disabled", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Target status: error
     
     Localized string for key “status.error” in table “Localizable.xcstrings”.
     */
    static var statusError: LocalizedStringResource {
        LocalizedStringResource("status.error", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Target status: idle
     
     Localized string for key “status.idle” in table “Localizable.xcstrings”.
     */
    static var statusIdle: LocalizedStringResource {
        LocalizedStringResource("status.idle", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Target status: queued
     
     Localized string for key “status.pending” in table “Localizable.xcstrings”.
     */
    static var statusPending: LocalizedStringResource {
        LocalizedStringResource("status.pending", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Target status: probing
     
     Localized string for key “status.running” in table “Localizable.xcstrings”.
     */
    static var statusRunning: LocalizedStringResource {
        LocalizedStringResource("status.running", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Target status: timeout
     
     Localized string for key “status.timeout” in table “Localizable.xcstrings”.
     */
    static var statusTimeout: LocalizedStringResource {
        LocalizedStringResource("status.timeout", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Target status: unreachable
     
     Localized string for key “status.unreachable” in table “Localizable.xcstrings”.
     */
    static var statusUnreachable: LocalizedStringResource {
        LocalizedStringResource("status.unreachable", table: "Localizable", bundle: l10nBundleDescription)
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
