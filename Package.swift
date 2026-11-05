// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BatchPing",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "BatchPing", targets: ["BatchPing"]),
        .library(name: "PingCore", targets: ["PingCore"]),
    ],
    targets: [
        // 与界面无关的核心逻辑：模型、ping 解析、并发引擎、配置与导出
        .target(name: "PingCore"),
        // SwiftUI 界面层
        .executableTarget(name: "BatchPing", dependencies: ["PingCore"]),
        .testTarget(name: "PingCoreTests", dependencies: ["PingCore"]),
    ]
)
