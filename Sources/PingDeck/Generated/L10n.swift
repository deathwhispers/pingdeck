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
     Concurrency adjustment message at limit
     
     Localized string for key “alert.concurrency.atLimit” in table “Localizable.xcstrings”.
     */
    static func alertConcurrencyAtLimit(_ arg1: Int, _ arg2: Int, _ arg3: Int, _ arg4: Int) -> LocalizedStringResource {
        LocalizedStringResource("alert.concurrency.atLimit", defaultValue: "\(arg1, specifier: "%lld")\(arg2, specifier: "%lld")\(arg3, specifier: "%lld")\(arg4, specifier: "%lld")", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Concurrency adjustment message below limit
     
     Localized string for key “alert.concurrency.belowLimit” in table “Localizable.xcstrings”.
     */
    static func alertConcurrencyBelowLimit(_ arg1: Int, _ arg2: Int, _ arg3: Int) -> LocalizedStringResource {
        LocalizedStringResource("alert.concurrency.belowLimit", defaultValue: "\(arg1, specifier: "%lld")\(arg2, specifier: "%lld")\(arg3, specifier: "%lld")", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Concurrency adjustment alert title
     
     Localized string for key “alert.concurrency.title” in table “Localizable.xcstrings”.
     */
    static var alertConcurrencyTitle: LocalizedStringResource {
        LocalizedStringResource("alert.concurrency.title", table: "Localizable", bundle: l10nBundleDescription)
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
     Bulk import completion message
     
     Localized string for key “alert.import.completed.message” in table “Localizable.xcstrings”.
     */
    static func alertImportCompletedMessage(_ arg1: Int) -> LocalizedStringResource {
        LocalizedStringResource("alert.import.completed.message", defaultValue: "\(arg1, specifier: "%lld")", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Bulk import completion skipped message
     
     Localized string for key “alert.import.completed.skipped” in table “Localizable.xcstrings”.
     */
    static func alertImportCompletedSkipped(_ arg1: Int) -> LocalizedStringResource {
        LocalizedStringResource("alert.import.completed.skipped", defaultValue: "\(arg1, specifier: "%lld")", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Bulk import completion alert title
     
     Localized string for key “alert.import.completed.title” in table “Localizable.xcstrings”.
     */
    static var alertImportCompletedTitle: LocalizedStringResource {
        LocalizedStringResource("alert.import.completed.title", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Save configuration failure alert title
     
     Localized string for key “alert.saveFailed.title” in table “Localizable.xcstrings”.
     */
    static var alertSaveFailedTitle: LocalizedStringResource {
        LocalizedStringResource("alert.saveFailed.title", table: "Localizable", bundle: l10nBundleDescription)
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
     Appearance option: dark
     
     Localized string for key “appearance.dark” in table “Localizable.xcstrings”.
     */
    static var appearanceDark: LocalizedStringResource {
        LocalizedStringResource("appearance.dark", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Appearance option: light
     
     Localized string for key “appearance.light” in table “Localizable.xcstrings”.
     */
    static var appearanceLight: LocalizedStringResource {
        LocalizedStringResource("appearance.light", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Appearance option: follow system
     
     Localized string for key “appearance.system” in table “Localizable.xcstrings”.
     */
    static var appearanceSystem: LocalizedStringResource {
        LocalizedStringResource("appearance.system", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Generic cancel button
     
     Localized string for key “common.cancel” in table “Localizable.xcstrings”.
     */
    static var commonCancel: LocalizedStringResource {
        LocalizedStringResource("common.cancel", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Generic done button
     
     Localized string for key “common.done” in table “Localizable.xcstrings”.
     */
    static var commonDone: LocalizedStringResource {
        LocalizedStringResource("common.done", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Generic off state
     
     Localized string for key “common.off” in table “Localizable.xcstrings”.
     */
    static var commonOff: LocalizedStringResource {
        LocalizedStringResource("common.off", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Generic save button
     
     Localized string for key “common.save” in table “Localizable.xcstrings”.
     */
    static var commonSave: LocalizedStringResource {
        LocalizedStringResource("common.save", table: "Localizable", bundle: l10nBundleDescription)
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
     Target editor enabled toggle
     
     Localized string for key “editor.enabled” in table “Localizable.xcstrings”.
     */
    static var editorEnabled: LocalizedStringResource {
        LocalizedStringResource("editor.enabled", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Target editor host label when ranges allowed
     
     Localized string for key “editor.host.label.range” in table “Localizable.xcstrings”.
     */
    static var editorHostLabelRange: LocalizedStringResource {
        LocalizedStringResource("editor.host.label.range", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Target editor host label when editing
     
     Localized string for key “editor.host.label.single” in table “Localizable.xcstrings”.
     */
    static var editorHostLabelSingle: LocalizedStringResource {
        LocalizedStringResource("editor.host.label.single", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Target editor host placeholder when ranges allowed
     
     Localized string for key “editor.host.placeholder.range” in table “Localizable.xcstrings”.
     */
    static var editorHostPlaceholderRange: LocalizedStringResource {
        LocalizedStringResource("editor.host.placeholder.range", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Target editor host placeholder when editing
     
     Localized string for key “editor.host.placeholder.single” in table “Localizable.xcstrings”.
     */
    static var editorHostPlaceholderSingle: LocalizedStringResource {
        LocalizedStringResource("editor.host.placeholder.single", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Target editor note label
     
     Localized string for key “editor.note” in table “Localizable.xcstrings”.
     */
    static var editorNote: LocalizedStringResource {
        LocalizedStringResource("editor.note", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Target editor note placeholder
     
     Localized string for key “editor.note.placeholder” in table “Localizable.xcstrings”.
     */
    static var editorNotePlaceholder: LocalizedStringResource {
        LocalizedStringResource("editor.note.placeholder", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Target editor range expansion preview
     
     Localized string for key “editor.preview.count” in table “Localizable.xcstrings”.
     */
    static func editorPreviewCount(_ arg1: Int) -> LocalizedStringResource {
        LocalizedStringResource("editor.preview.count", defaultValue: "\(arg1, specifier: "%lld")", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Target editor range input rejection in edit mode
     
     Localized string for key “editor.rangeNotAllowed” in table “Localizable.xcstrings”.
     */
    static var editorRangeNotAllowed: LocalizedStringResource {
        LocalizedStringResource("editor.rangeNotAllowed", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Target editor title when adding
     
     Localized string for key “editor.title.add” in table “Localizable.xcstrings”.
     */
    static var editorTitleAdd: LocalizedStringResource {
        LocalizedStringResource("editor.title.add", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Target editor title when editing
     
     Localized string for key “editor.title.edit” in table “Localizable.xcstrings”.
     */
    static var editorTitleEdit: LocalizedStringResource {
        LocalizedStringResource("editor.title.edit", table: "Localizable", bundle: l10nBundleDescription)
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
     Bulk import confirm button for append
     
     Localized string for key “import.confirm.append” in table “Localizable.xcstrings”.
     */
    static func importConfirmAppend(_ arg1: Int) -> LocalizedStringResource {
        LocalizedStringResource("import.confirm.append", defaultValue: "\(arg1, specifier: "%lld")", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Bulk import confirm button for replace
     
     Localized string for key “import.confirm.replace” in table “Localizable.xcstrings”.
     */
    static func importConfirmReplace(_ arg1: Int) -> LocalizedStringResource {
        LocalizedStringResource("import.confirm.replace", defaultValue: "\(arg1, specifier: "%lld")", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Bulk import help text
     
     Localized string for key “import.description” in table “Localizable.xcstrings”.
     */
    static var importDescription: LocalizedStringResource {
        LocalizedStringResource("import.description", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Bulk import example text
     
     Localized string for key “import.example” in table “Localizable.xcstrings”.
     */
    static var importExample: LocalizedStringResource {
        LocalizedStringResource("import.example", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Bulk import mode label
     
     Localized string for key “import.mode” in table “Localizable.xcstrings”.
     */
    static var importMode: LocalizedStringResource {
        LocalizedStringResource("import.mode", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Import mode: append
     
     Localized string for key “import.mode.append” in table “Localizable.xcstrings”.
     */
    static var importModeAppend: LocalizedStringResource {
        LocalizedStringResource("import.mode.append", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Bulk import append mode description
     
     Localized string for key “import.mode.append.description” in table “Localizable.xcstrings”.
     */
    static func importModeAppendDescription(_ arg1: Int) -> LocalizedStringResource {
        LocalizedStringResource("import.mode.append.description", defaultValue: "\(arg1, specifier: "%lld")", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Import mode: replace
     
     Localized string for key “import.mode.replace” in table “Localizable.xcstrings”.
     */
    static var importModeReplace: LocalizedStringResource {
        LocalizedStringResource("import.mode.replace", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Bulk import replace mode description when no existing targets
     
     Localized string for key “import.mode.replace.description.empty” in table “Localizable.xcstrings”.
     */
    static var importModeReplaceDescriptionEmpty: LocalizedStringResource {
        LocalizedStringResource("import.mode.replace.description.empty", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Bulk import replace mode description with existing targets
     
     Localized string for key “import.mode.replace.description.withCount” in table “Localizable.xcstrings”.
     */
    static func importModeReplaceDescriptionWithCount(_ arg1: Int) -> LocalizedStringResource {
        LocalizedStringResource("import.mode.replace.description.withCount", defaultValue: "\(arg1, specifier: "%lld")", table: "Localizable", bundle: l10nBundleDescription)
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
     Bulk import preview summary
     
     Localized string for key “import.summary” in table “Localizable.xcstrings”.
     */
    static func importSummary(_ arg1: Int, _ arg2: Int) -> LocalizedStringResource {
        LocalizedStringResource("import.summary", defaultValue: "\(arg1, specifier: "%lld")\(arg2, specifier: "%lld")", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Bulk import sheet title
     
     Localized string for key “import.title” in table “Localizable.xcstrings”.
     */
    static var importTitle: LocalizedStringResource {
        LocalizedStringResource("import.title", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Language option: follow system
     
     Localized string for key “language.system” in table “Localizable.xcstrings”.
     */
    static var languageSystem: LocalizedStringResource {
        LocalizedStringResource("language.system", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     App menu Settings item
     
     Localized string for key “menu.settings” in table “Localizable.xcstrings”.
     */
    static var menuSettings: LocalizedStringResource {
        LocalizedStringResource("menu.settings", table: "Localizable", bundle: l10nBundleDescription)
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
     Settings: appearance label
     
     Localized string for key “settings.appearance” in table “Localizable.xcstrings”.
     */
    static var settingsAppearance: LocalizedStringResource {
        LocalizedStringResource("settings.appearance", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Settings: appearance hint
     
     Localized string for key “settings.appearance.hint” in table “Localizable.xcstrings”.
     */
    static var settingsAppearanceHint: LocalizedStringResource {
        LocalizedStringResource("settings.appearance.hint", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Settings: probe interval label
     
     Localized string for key “settings.interval” in table “Localizable.xcstrings”.
     */
    static var settingsInterval: LocalizedStringResource {
        LocalizedStringResource("settings.interval", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Settings: interval hint
     
     Localized string for key “settings.interval.hint” in table “Localizable.xcstrings”.
     */
    static var settingsIntervalHint: LocalizedStringResource {
        LocalizedStringResource("settings.interval.hint", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Settings: language picker label
     
     Localized string for key “settings.language” in table “Localizable.xcstrings”.
     */
    static var settingsLanguage: LocalizedStringResource {
        LocalizedStringResource("settings.language", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Settings: language switch behavior hint
     
     Localized string for key “settings.language.hint” in table “Localizable.xcstrings”.
     */
    static var settingsLanguageHint: LocalizedStringResource {
        LocalizedStringResource("settings.language.hint", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Settings: max concurrency label
     
     Localized string for key “settings.maxConcurrent” in table “Localizable.xcstrings”.
     */
    static var settingsMaxConcurrent: LocalizedStringResource {
        LocalizedStringResource("settings.maxConcurrent", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Settings: max concurrency hint
     
     Localized string for key “settings.maxConcurrent.hint” in table “Localizable.xcstrings”.
     */
    static func settingsMaxConcurrentHint(_ arg1: Int) -> LocalizedStringResource {
        LocalizedStringResource("settings.maxConcurrent.hint", defaultValue: "\(arg1, specifier: "%lld")", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Settings: rotation interval label
     
     Localized string for key “settings.rotation” in table “Localizable.xcstrings”.
     */
    static var settingsRotation: LocalizedStringResource {
        LocalizedStringResource("settings.rotation", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Settings: rotation hint
     
     Localized string for key “settings.rotation.hint” in table “Localizable.xcstrings”.
     */
    static var settingsRotationHint: LocalizedStringResource {
        LocalizedStringResource("settings.rotation.hint", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Settings: packet timeout label
     
     Localized string for key “settings.timeout” in table “Localizable.xcstrings”.
     */
    static var settingsTimeout: LocalizedStringResource {
        LocalizedStringResource("settings.timeout", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Settings: timeout hint
     
     Localized string for key “settings.timeout.hint” in table “Localizable.xcstrings”.
     */
    static var settingsTimeoutHint: LocalizedStringResource {
        LocalizedStringResource("settings.timeout.hint", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Settings sheet title
     
     Localized string for key “settings.title” in table “Localizable.xcstrings”.
     */
    static var settingsTitle: LocalizedStringResource {
        LocalizedStringResource("settings.title", table: "Localizable", bundle: l10nBundleDescription)
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
     Duration with one decimal, e.g. 1.5 seconds
     
     Localized string for key “unit.seconds.decimal” in table “Localizable.xcstrings”.
     */
    static func unitSecondsDecimal(_ arg1: Float) -> LocalizedStringResource {
        LocalizedStringResource("unit.seconds.decimal", defaultValue: "\(arg1, specifier: "%.1f")", table: "Localizable", bundle: l10nBundleDescription)
    }

    /**
     Duration in whole seconds
     
     Localized string for key “unit.seconds.integer” in table “Localizable.xcstrings”.
     */
    static func unitSecondsInteger(_ arg1: Int) -> LocalizedStringResource {
        LocalizedStringResource("unit.seconds.integer", defaultValue: "\(arg1, specifier: "%lld")", table: "Localizable", bundle: l10nBundleDescription)
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
