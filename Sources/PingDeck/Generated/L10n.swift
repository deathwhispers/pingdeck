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
     Add target failure alert title
     
     Localized string for key “alert.addFailed.title” in table “Localizable.xcstrings”.
     */
    static var alertAddFailedTitle: LocalizedStringResource {
        LocalizedStringResource("alert.addFailed.title", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Alert banner dismiss button help
     
     Localized string for key “alert.dismiss.help” in table “Localizable.xcstrings”.
     */
    static var alertDismissHelp: LocalizedStringResource {
        LocalizedStringResource("alert.dismiss.help", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Generic error alert title
     
     Localized string for key “alert.error.title” in table “Localizable.xcstrings”.
     */
    static var alertErrorTitle: LocalizedStringResource {
        LocalizedStringResource("alert.error.title", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Export failure alert title
     
     Localized string for key “alert.exportFailed.title” in table “Localizable.xcstrings”.
     */
    static var alertExportFailedTitle: LocalizedStringResource {
        LocalizedStringResource("alert.exportFailed.title", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Language change alert message
     
     Localized string for key “alert.language.restart” in table “Localizable.xcstrings”.
     */
    static var alertLanguageRestart: LocalizedStringResource {
        LocalizedStringResource("alert.language.restart", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Language change alert title
     
     Localized string for key “alert.language.title” in table “Localizable.xcstrings”.
     */
    static var alertLanguageTitle: LocalizedStringResource {
        LocalizedStringResource("alert.language.title", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Add target alert message for expanded range
     
     Localized string for key “alert.targetsAdded.message” in table “Localizable.xcstrings”.
     */
    static var alertTargetsAddedMessage: LocalizedStringResource {
        LocalizedStringResource("alert.targetsAdded.message", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Add target alert title with expanded count
     
     Localized string for key “alert.targetsAdded.title” in table “Localizable.xcstrings”.
     */
    static func alertTargetsAddedTitle(_ arg1: Int) -> LocalizedStringResource {
        LocalizedStringResource("alert.targetsAdded.title", defaultValue: "\(arg1, specifier: "%lld")", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Build-time smoke test for generated String Catalog symbols.
     
     Localized string for key “app.name.smoke” in table “Localizable.xcstrings”.
     */
    static var appNameSmoke: LocalizedStringResource {
        LocalizedStringResource("app.name.smoke", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Generic cancel button
     
     Localized string for key “common.cancel” in table “Localizable.xcstrings”.
     */
    static var commonCancel: LocalizedStringResource {
        LocalizedStringResource("common.cancel", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Clear all targets confirmation button
     
     Localized string for key “confirm.clearAll.confirm” in table “Localizable.xcstrings”.
     */
    static var confirmClearAllConfirm: LocalizedStringResource {
        LocalizedStringResource("confirm.clearAll.confirm", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Clear all targets confirmation title
     
     Localized string for key “confirm.clearAll.title” in table “Localizable.xcstrings”.
     */
    static func confirmClearAllTitle(_ arg1: Int) -> LocalizedStringResource {
        LocalizedStringResource("confirm.clearAll.title", defaultValue: "\(arg1, specifier: "%lld")", table: "Localizable", bundle: l10nBundleDescription)
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
     Language option: follow system
     
     Localized string for key “language.system” in table “Localizable.xcstrings”.
     */
    static var languageSystem: LocalizedStringResource {
        LocalizedStringResource("language.system", table: "Localizable", bundle: l10nBundleDescription)
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
     Settings: language picker label
     
     Localized string for key “settings.language” in table “Localizable.xcstrings”.
     */
    static var settingsLanguage: LocalizedStringResource {
        LocalizedStringResource("settings.language", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Settings: language restart hint
     
     Localized string for key “settings.language.hint” in table “Localizable.xcstrings”.
     */
    static var settingsLanguageHint: LocalizedStringResource {
        LocalizedStringResource("settings.language.hint", table: "Localizable", bundle: l10nBundleDescription)
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
     Status bar alive count
     
     Localized string for key “statusBar.alive” in table “Localizable.xcstrings”.
     */
    static func statusBarAlive(_ arg1: Int) -> LocalizedStringResource {
        LocalizedStringResource("statusBar.alive", defaultValue: "\(arg1, specifier: "%lld")", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Status bar problem count
     
     Localized string for key “statusBar.problems” in table “Localizable.xcstrings”.
     */
    static func statusBarProblems(_ arg1: Int) -> LocalizedStringResource {
        LocalizedStringResource("statusBar.problems", defaultValue: "\(arg1, specifier: "%lld")", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Status bar queued count suffix
     
     Localized string for key “statusBar.queued” in table “Localizable.xcstrings”.
     */
    static func statusBarQueued(_ arg1: Int) -> LocalizedStringResource {
        LocalizedStringResource("statusBar.queued", defaultValue: "\(arg1, specifier: "%lld")", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Status bar running prefix
     
     Localized string for key “statusBar.running” in table “Localizable.xcstrings”.
     */
    static func statusBarRunning(_ arg1: String) -> LocalizedStringResource {
        LocalizedStringResource("statusBar.running", defaultValue: "\(arg1)", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Status bar selected count
     
     Localized string for key “statusBar.selected” in table “Localizable.xcstrings”.
     */
    static func statusBarSelected(_ arg1: Int) -> LocalizedStringResource {
        LocalizedStringResource("statusBar.selected", defaultValue: "\(arg1, specifier: "%lld")", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Status bar stopped prefix
     
     Localized string for key “statusBar.stopped” in table “Localizable.xcstrings”.
     */
    static func statusBarStopped(_ arg1: String) -> LocalizedStringResource {
        LocalizedStringResource("statusBar.stopped", defaultValue: "\(arg1)", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Status bar interval, timeout and concurrency summary
     
     Localized string for key “statusBar.summary” in table “Localizable.xcstrings”.
     */
    static func statusBarSummary(_ arg1: Float, _ arg2: Float, _ arg3: Int) -> LocalizedStringResource {
        LocalizedStringResource("statusBar.summary", defaultValue: "\(arg1, specifier: "%.1f")\(arg2, specifier: "%.1f")\(arg3, specifier: "%lld")", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Status bar target count
     
     Localized string for key “statusBar.targets” in table “Localizable.xcstrings”.
     */
    static func statusBarTargets(_ arg1: Int) -> LocalizedStringResource {
        LocalizedStringResource("statusBar.targets", defaultValue: "\(arg1, specifier: "%lld")", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Status bar total sent count
     
     Localized string for key “statusBar.totalSent” in table “Localizable.xcstrings”.
     */
    static func statusBarTotalSent(_ arg1: Int) -> LocalizedStringResource {
        LocalizedStringResource("statusBar.totalSent", defaultValue: "\(arg1, specifier: "%lld")", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Table column: average latency
     
     Localized string for key “table.column.average” in table “Localizable.xcstrings”.
     */
    static var tableColumnAverage: LocalizedStringResource {
        LocalizedStringResource("table.column.average", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Table column: enabled
     
     Localized string for key “table.column.enabled” in table “Localizable.xcstrings”.
     */
    static var tableColumnEnabled: LocalizedStringResource {
        LocalizedStringResource("table.column.enabled", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Table column: latest latency
     
     Localized string for key “table.column.last” in table “Localizable.xcstrings”.
     */
    static var tableColumnLast: LocalizedStringResource {
        LocalizedStringResource("table.column.last", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Table column: last response time
     
     Localized string for key “table.column.lastResponse” in table “Localizable.xcstrings”.
     */
    static var tableColumnLastResponse: LocalizedStringResource {
        LocalizedStringResource("table.column.lastResponse", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Table column: loss rate
     
     Localized string for key “table.column.loss” in table “Localizable.xcstrings”.
     */
    static var tableColumnLoss: LocalizedStringResource {
        LocalizedStringResource("table.column.loss", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Table column: maximum latency
     
     Localized string for key “table.column.max” in table “Localizable.xcstrings”.
     */
    static var tableColumnMax: LocalizedStringResource {
        LocalizedStringResource("table.column.max", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Table column: minimum latency
     
     Localized string for key “table.column.min” in table “Localizable.xcstrings”.
     */
    static var tableColumnMin: LocalizedStringResource {
        LocalizedStringResource("table.column.min", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Table column: status
     
     Localized string for key “table.column.status” in table “Localizable.xcstrings”.
     */
    static var tableColumnStatus: LocalizedStringResource {
        LocalizedStringResource("table.column.status", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Table column: target
     
     Localized string for key “table.column.target” in table “Localizable.xcstrings”.
     */
    static var tableColumnTarget: LocalizedStringResource {
        LocalizedStringResource("table.column.target", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Empty table hint
     
     Localized string for key “table.empty.message” in table “Localizable.xcstrings”.
     */
    static var tableEmptyMessage: LocalizedStringResource {
        LocalizedStringResource("table.empty.message", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Empty table title
     
     Localized string for key “table.empty.title” in table “Localizable.xcstrings”.
     */
    static var tableEmptyTitle: LocalizedStringResource {
        LocalizedStringResource("table.empty.title", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Table enabled toggle help when on
     
     Localized string for key “table.enabled.disable.help” in table “Localizable.xcstrings”.
     */
    static var tableEnabledDisableHelp: LocalizedStringResource {
        LocalizedStringResource("table.enabled.disable.help", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Table enabled toggle help when off
     
     Localized string for key “table.enabled.enable.help” in table “Localizable.xcstrings”.
     */
    static var tableEnabledEnableHelp: LocalizedStringResource {
        LocalizedStringResource("table.enabled.enable.help", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Toolbar add button
     
     Localized string for key “toolbar.add” in table “Localizable.xcstrings”.
     */
    static var toolbarAdd: LocalizedStringResource {
        LocalizedStringResource("toolbar.add", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Toolbar add button help
     
     Localized string for key “toolbar.add.help” in table “Localizable.xcstrings”.
     */
    static var toolbarAddHelp: LocalizedStringResource {
        LocalizedStringResource("toolbar.add.help", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Toolbar clear menu
     
     Localized string for key “toolbar.clear” in table “Localizable.xcstrings”.
     */
    static var toolbarClear: LocalizedStringResource {
        LocalizedStringResource("toolbar.clear", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Toolbar clear all targets menu item
     
     Localized string for key “toolbar.clear.all” in table “Localizable.xcstrings”.
     */
    static var toolbarClearAll: LocalizedStringResource {
        LocalizedStringResource("toolbar.clear.all", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Toolbar clear menu help
     
     Localized string for key “toolbar.clear.help” in table “Localizable.xcstrings”.
     */
    static var toolbarClearHelp: LocalizedStringResource {
        LocalizedStringResource("toolbar.clear.help", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Toolbar clear results menu item
     
     Localized string for key “toolbar.clear.results” in table “Localizable.xcstrings”.
     */
    static var toolbarClearResults: LocalizedStringResource {
        LocalizedStringResource("toolbar.clear.results", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Toolbar columns menu
     
     Localized string for key “toolbar.columns” in table “Localizable.xcstrings”.
     */
    static var toolbarColumns: LocalizedStringResource {
        LocalizedStringResource("toolbar.columns", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Toolbar columns menu help
     
     Localized string for key “toolbar.columns.help” in table “Localizable.xcstrings”.
     */
    static var toolbarColumnsHelp: LocalizedStringResource {
        LocalizedStringResource("toolbar.columns.help", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Toolbar columns menu: show all
     
     Localized string for key “toolbar.columns.showAll” in table “Localizable.xcstrings”.
     */
    static var toolbarColumnsShowAll: LocalizedStringResource {
        LocalizedStringResource("toolbar.columns.showAll", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Toolbar delete button
     
     Localized string for key “toolbar.delete” in table “Localizable.xcstrings”.
     */
    static var toolbarDelete: LocalizedStringResource {
        LocalizedStringResource("toolbar.delete", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Toolbar delete button with selected count
     
     Localized string for key “toolbar.delete.count” in table “Localizable.xcstrings”.
     */
    static func toolbarDeleteCount(_ arg1: Int) -> LocalizedStringResource {
        LocalizedStringResource("toolbar.delete.count", defaultValue: "\(arg1, specifier: "%lld")", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Toolbar delete button help
     
     Localized string for key “toolbar.delete.help” in table “Localizable.xcstrings”.
     */
    static var toolbarDeleteHelp: LocalizedStringResource {
        LocalizedStringResource("toolbar.delete.help", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Toolbar edit button help
     
     Localized string for key “toolbar.edit.help” in table “Localizable.xcstrings”.
     */
    static var toolbarEditHelp: LocalizedStringResource {
        LocalizedStringResource("toolbar.edit.help", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Toolbar export menu
     
     Localized string for key “toolbar.export” in table “Localizable.xcstrings”.
     */
    static var toolbarExport: LocalizedStringResource {
        LocalizedStringResource("toolbar.export", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Toolbar export all items
     
     Localized string for key “toolbar.export.all” in table “Localizable.xcstrings”.
     */
    static func toolbarExportAll(_ arg1: Int) -> LocalizedStringResource {
        LocalizedStringResource("toolbar.export.all", defaultValue: "\(arg1, specifier: "%lld")", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Toolbar export menu help
     
     Localized string for key “toolbar.export.help” in table “Localizable.xcstrings”.
     */
    static var toolbarExportHelp: LocalizedStringResource {
        LocalizedStringResource("toolbar.export.help", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Toolbar export selected items
     
     Localized string for key “toolbar.export.selected” in table “Localizable.xcstrings”.
     */
    static func toolbarExportSelected(_ arg1: Int) -> LocalizedStringResource {
        LocalizedStringResource("toolbar.export.selected", defaultValue: "\(arg1, specifier: "%lld")", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Toolbar bulk import button
     
     Localized string for key “toolbar.import” in table “Localizable.xcstrings”.
     */
    static var toolbarImport: LocalizedStringResource {
        LocalizedStringResource("toolbar.import", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Toolbar bulk import button help
     
     Localized string for key “toolbar.import.help” in table “Localizable.xcstrings”.
     */
    static var toolbarImportHelp: LocalizedStringResource {
        LocalizedStringResource("toolbar.import.help", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Toolbar refresh button help
     
     Localized string for key “toolbar.refresh.help” in table “Localizable.xcstrings”.
     */
    static var toolbarRefreshHelp: LocalizedStringResource {
        LocalizedStringResource("toolbar.refresh.help", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Toolbar settings button help
     
     Localized string for key “toolbar.settings” in table “Localizable.xcstrings”.
     */
    static var toolbarSettings: LocalizedStringResource {
        LocalizedStringResource("toolbar.settings", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Toolbar start button
     
     Localized string for key “toolbar.start” in table “Localizable.xcstrings”.
     */
    static var toolbarStart: LocalizedStringResource {
        LocalizedStringResource("toolbar.start", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Toolbar start button help
     
     Localized string for key “toolbar.start.help” in table “Localizable.xcstrings”.
     */
    static var toolbarStartHelp: LocalizedStringResource {
        LocalizedStringResource("toolbar.start.help", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Toolbar stop button
     
     Localized string for key “toolbar.stop” in table “Localizable.xcstrings”.
     */
    static var toolbarStop: LocalizedStringResource {
        LocalizedStringResource("toolbar.stop", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Toolbar stop button help
     
     Localized string for key “toolbar.stop.help” in table “Localizable.xcstrings”.
     */
    static var toolbarStopHelp: LocalizedStringResource {
        LocalizedStringResource("toolbar.stop.help", table: "Localizable", bundle: l10nBundleDescription)
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
