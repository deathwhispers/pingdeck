import Foundation

/// 单次探测样本，仅用于界面展示，不持久化。
public struct PingSample: Identifiable, Sendable, Equatable {
    public enum Outcome: String, Sendable, Equatable {
        case reply
        case timeout
        case unreachable
        case failure
    }

    public let id: UUID
    public let timestamp: Date
    public let seq: Int?
    public let outcome: Outcome
    public let latencyMs: Double?
    public let peerAddress: String?
    public let ttl: Int?
    public let message: String

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        seq: Int? = nil,
        outcome: Outcome,
        latencyMs: Double? = nil,
        peerAddress: String? = nil,
        ttl: Int? = nil,
        message: String = ""
    ) {
        self.id = id
        self.timestamp = timestamp
        self.seq = seq
        self.outcome = outcome
        self.latencyMs = latencyMs
        self.peerAddress = peerAddress
        self.ttl = ttl
        self.message = message
    }
}
