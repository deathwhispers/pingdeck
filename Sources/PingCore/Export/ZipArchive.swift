import Foundation

/// 最小 zip 写入器
///
/// 只实现 stored（不压缩）模式：xlsx 只是一个装了 XML 的 zip 包，
/// 不压缩同样合法，Excel / Numbers 都能正常打开。这样可以避免引入压缩库依赖。
struct ZipArchive {
    struct Entry {
        let name: String
        let data: Data
    }

    private var entries: [Entry] = []

    mutating func addFile(name: String, data: Data) {
        entries.append(Entry(name: name, data: data))
    }

    func build() -> Data {
        var output = Data()
        var central = Data()
        var count: UInt16 = 0

        for entry in entries {
            let name = Data(entry.name.utf8)
            let checksum = CRC32.checksum(entry.data)
            let offset = UInt32(output.count)

            // 本地文件头
            output.appendLittleEndian(UInt32(0x04034B50))
            output.appendLittleEndian(UInt16(20)) // 解压所需版本
            output.appendLittleEndian(UInt16(0))  // 通用标志位
            output.appendLittleEndian(UInt16(0))  // 压缩方式：stored
            output.appendLittleEndian(UInt16(0))  // 修改时间
            output.appendLittleEndian(UInt16(0))  // 修改日期
            output.appendLittleEndian(checksum)
            output.appendLittleEndian(UInt32(entry.data.count)) // 压缩后大小
            output.appendLittleEndian(UInt32(entry.data.count)) // 原始大小
            output.appendLittleEndian(UInt16(name.count))
            output.appendLittleEndian(UInt16(0))  // 扩展字段长度
            output.append(name)
            output.append(entry.data)

            // 中央目录条目
            central.appendLittleEndian(UInt32(0x02014B50))
            central.appendLittleEndian(UInt16(20)) // 生成版本
            central.appendLittleEndian(UInt16(20)) // 解压所需版本
            central.appendLittleEndian(UInt16(0))  // 通用标志位
            central.appendLittleEndian(UInt16(0))  // 压缩方式：stored
            central.appendLittleEndian(UInt16(0))  // 修改时间
            central.appendLittleEndian(UInt16(0))  // 修改日期
            central.appendLittleEndian(checksum)
            central.appendLittleEndian(UInt32(entry.data.count))
            central.appendLittleEndian(UInt32(entry.data.count))
            central.appendLittleEndian(UInt16(name.count))
            central.appendLittleEndian(UInt16(0))  // 扩展字段长度
            central.appendLittleEndian(UInt16(0))  // 文件注释长度
            central.appendLittleEndian(UInt16(0))  // 起始磁盘号
            central.appendLittleEndian(UInt16(0))  // 内部属性
            central.appendLittleEndian(UInt32(0))  // 外部属性
            central.appendLittleEndian(offset)
            central.append(name)

            count += 1
        }

        let centralOffset = UInt32(output.count)
        output.append(central)

        // 中央目录结束记录
        output.appendLittleEndian(UInt32(0x06054B50))
        output.appendLittleEndian(UInt16(0))  // 当前磁盘号
        output.appendLittleEndian(UInt16(0))  // 中央目录起始磁盘号
        output.appendLittleEndian(count)
        output.appendLittleEndian(count)
        output.appendLittleEndian(UInt32(central.count))
        output.appendLittleEndian(centralOffset)
        output.appendLittleEndian(UInt16(0))  // 注释长度
        return output
    }
}

/// CRC32 校验和（zip 规范使用）
enum CRC32 {
    private static let table: [UInt32] = (0..<256).map { index -> UInt32 in
        var value = UInt32(index)
        for _ in 0..<8 {
            value = (value & 1) == 1 ? (0xEDB88320 ^ (value >> 1)) : (value >> 1)
        }
        return value
    }

    static func checksum(_ data: Data) -> UInt32 {
        var crc: UInt32 = 0xFFFFFFFF
        for byte in data {
            crc = table[Int((crc ^ UInt32(byte)) & 0xFF)] ^ (crc >> 8)
        }
        return crc ^ 0xFFFFFFFF
    }
}

extension Data {
    /// 追加小端序整数（zip 格式要求小端）
    mutating func appendLittleEndian(_ value: UInt16) {
        append(UInt8(value & 0xFF))
        append(UInt8((value >> 8) & 0xFF))
    }

    mutating func appendLittleEndian(_ value: UInt32) {
        append(UInt8(value & 0xFF))
        append(UInt8((value >> 8) & 0xFF))
        append(UInt8((value >> 16) & 0xFF))
        append(UInt8((value >> 24) & 0xFF))
    }
}
