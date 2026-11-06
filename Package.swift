// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PingDeck",
    defaultLocalization: "en",
    platforms: [.macOS("14.4")],
    products: [
        .executable(name: "PingDeck", targets: ["PingDeck"]),
        .library(name: "PingCore", targets: ["PingCore"]),
    ],
    targets: [
        // 与界面无关的核心逻辑：模型、ping 解析、并发引擎、配置与导出
        .target(name: "PingCore"),
        // SwiftUI 界面层
        .executableTarget(
            name: "PingDeck",
            dependencies: ["PingCore"],
            resources: [.process("Resources")]
        ),
        .testTarget(name: "PingCoreTests", dependencies: ["PingCore"]),
        // 界面层逻辑（选择、清空、导入模式）
        .testTarget(name: "PingDeckTests", dependencies: ["PingDeck", "PingCore"], path: "Tests/PingDeckTests"),
    ]
)
