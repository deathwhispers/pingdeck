import PingCore

extension TargetValidationIssue {
    var message: String {
        switch self {
        case .empty: return String(localized: L10n.validationEmpty)
        case .protocolPrefix: return String(localized: L10n.validationProtocolPrefix)
        case .path: return String(localized: L10n.validationPath)
        case .whitespace: return String(localized: L10n.validationWhitespace)
        case .invalidCharacters: return String(localized: L10n.validationInvalidCharacters)
        }
    }
}

extension IPv4RangeError {
    var message: String {
        switch self {
        case .ipv6Unsupported: return String(localized: L10n.rangeIpv6Unsupported)
        case .malformedCIDR: return String(localized: L10n.rangeMalformedCIDR)
        case .cidrNotNetworkAddress: return String(localized: L10n.rangeCidrNotNetworkAddress)
        case .rangeTooLarge(let limit): return String(localized: L10n.rangeTooLarge(limit))
        case .malformedRange: return String(localized: L10n.rangeMalformed)
        case .endBeforeStart: return String(localized: L10n.rangeEndBeforeStart)
        }
    }
}

extension BulkImportParser.RejectionReason {
    var message: String {
        switch self {
        case .duplicate: return String(localized: L10n.importRejectedDuplicate)
        case .invalidTarget(let issue): return issue.message
        case .invalidRange(let error): return error.message
        }
    }
}
