import Foundation

public enum PingError: LocalizedError {
    case executableNotFound(String)

    public var errorDescription: String? {
        switch self {
        case .executableNotFound(let path):
            return "找不到系统 ping 程序：\(path)"
        }
    }
}

/// 按行切分来自管道的字节流
final class LineBuffer {
    private var buffer = Data()

    func append(_ data: Data) -> [String] {
        buffer.append(data)
        var lines: [String] = []
        while let index = buffer.firstIndex(of: 0x0A) {
            let lineData = buffer.subdata(in: buffer.startIndex..<index)
            buffer.removeSubrange(buffer.startIndex...index)
            lines.append(String(decoding: lineData, as: UTF8.self))
        }
        return lines
    }

    /// 取出缓冲区中剩余的不完整行
    func flush() -> String? {
        guard !buffer.isEmpty else { return nil }
        let text = String(decoding: buffer, as: UTF8.self)
        buffer.removeAll()
        return text
    }
}

/// 单个目标的 ping 子进程封装：持续运行，由内核按间隔发包
public final class PingProcess {
    public struct Configuration: Sendable {
        public var interval: TimeInterval
        public var timeout: TimeInterval

        public init(interval: TimeInterval = 1.0, timeout: TimeInterval = 2.0) {
            self.interval = interval
            self.timeout = timeout
        }
    }

    private let host: String
    private let configuration: Configuration
    private let lock = NSLock()
    private let stdoutBuffer = LineBuffer()
    private let stderrBuffer = LineBuffer()
    private var process: Process?
    private var stopped = false

    /// 每解析出一条有效事件回调一次
    public var onEvent: ((PingEvent) -> Void)?
    /// 进程退出时回调（参数为退出码）
    public var onExit: ((Int32) -> Void)?

    public init(host: String, configuration: Configuration) {
        self.host = host
        self.configuration = configuration
    }

    /// macOS 的 ping 在 /sbin 与 /bin 下各有一份；IPv6 需要 ping6
    public static func executableURL(forIPv6: Bool) -> URL? {
        let candidates = forIPv6
            ? ["/sbin/ping6", "/bin/ping6"]
            : ["/sbin/ping", "/bin/ping"]
        for path in candidates where FileManager.default.isExecutableFile(atPath: path) {
            return URL(fileURLWithPath: path)
        }
        return nil
    }

    public func start() throws {
        let isIPv6 = host.contains(":")
        guard let executable = Self.executableURL(forIPv6: isIPv6) else {
            throw PingError.executableNotFound(isIPv6 ? "/sbin/ping6" : "/sbin/ping")
        }

        let process = Process()
        process.executableURL = executable
        // 只使用 macOS ping 必定支持的 -i 参数；超时判定由 icmp_seq 号推算，
        // 不依赖 -W/-t 这类在不同 BSD 版本间语义不一致的选项
        process.arguments = [
            "-i", String(format: "%.2f", configuration.interval),
            host,
        ]
        process.standardInput = FileHandle.nullDevice

        let outPipe = Pipe()
        let errPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError = errPipe

        outPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            self?.consume(handle.availableData, isStandardError: false)
        }
        errPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            self?.consume(handle.availableData, isStandardError: true)
        }

        process.terminationHandler = { [weak self] finished in
            self?.onExit?(finished.terminationStatus)
        }

        try process.run()
        lock.lock()
        self.process = process
        lock.unlock()
    }

    public func stop() {
        lock.lock()
        stopped = true
        let running = process
        lock.unlock()
        if let running, running.isRunning {
            running.terminate()
        }
    }

    private func consume(_ data: Data, isStandardError: Bool) {
        lock.lock()
        let isStopped = stopped
        lock.unlock()
        guard !isStopped else { return }

        var lines: [String] = []
        lock.lock()
        if data.isEmpty {
            let rest = isStandardError ? stderrBuffer.flush() : stdoutBuffer.flush()
            if let rest, !rest.isEmpty { lines.append(rest) }
        } else {
            lines = isStandardError ? stderrBuffer.append(data) : stdoutBuffer.append(data)
        }
        lock.unlock()

        for line in lines {
            emit(PingLineParser.parse(line))
        }
    }

    private func emit(_ event: PingEvent) {
        if case .info(let text) = event, text.isEmpty { return }
        onEvent?(event)
    }
}
