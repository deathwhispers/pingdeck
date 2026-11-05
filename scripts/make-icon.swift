// 生成 App 图标：纯 CoreGraphics 渲染 1024x1024 主图，再用 sips/iconutil 扩展成 .iconset
// 不依赖 AppKit 的 lockFocus，可在无窗口服务的 CI 环境运行
// 用法：swift scripts/make-icon.swift <输出 iconset 目录>
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let outputDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "./AppIcon.iconset"
let canvas = 1024

guard let context = CGContext(
    data: nil,
    width: canvas,
    height: canvas,
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: CGColorSpaceCreateDeviceRGB(),
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else {
    FileHandle.standardError.write(Data("无法创建绘图上下文\n".utf8))
    exit(1)
}

// 圆角方形底板
let inset: CGFloat = 92
let plate = CGRect(x: inset, y: inset, width: CGFloat(canvas) - inset * 2, height: CGFloat(canvas) - inset * 2)
let platePath = CGPath(roundedRect: plate, cornerWidth: 200, cornerHeight: 200, transform: nil)

context.saveGState()
context.addPath(platePath)
context.clip()
let gradient = CGGradient(
    colorsSpace: CGColorSpaceCreateDeviceRGB(),
    colors: [
        CGColor(red: 0.36, green: 0.30, blue: 0.93, alpha: 1),
        CGColor(red: 0.09, green: 0.55, blue: 0.92, alpha: 1),
        CGColor(red: 0.10, green: 0.78, blue: 0.80, alpha: 1),
    ] as CFArray,
    locations: [0, 0.55, 1]
)!
context.drawLinearGradient(
    gradient,
    start: CGPoint(x: 0, y: plate.maxY),
    end: CGPoint(x: 0, y: plate.minY),
    options: []
)
context.restoreGState()

// 信号弧线
let center = CGPoint(x: CGFloat(canvas) / 2, y: CGFloat(canvas) * 0.34)
context.setStrokeColor(CGColor(gray: 1, alpha: 1))
context.setLineWidth(62)
context.setLineCap(.round)
for radius in [300.0, 225.0, 150.0] {
    context.addArc(center: center, radius: CGFloat(radius), startAngle: .pi * 0.14, endAngle: .pi * 0.86, clockwise: false)
    context.strokePath()
}

// 中心点
context.setFillColor(CGColor(gray: 1, alpha: 1))
context.addEllipse(in: CGRect(x: center.x - 58, y: center.y - 58, width: 116, height: 116))
context.fillPath()

guard let image = context.makeImage() else {
    FileHandle.standardError.write(Data("渲染图标失败\n".utf8))
    exit(1)
}

let masterURL = URL(fileURLWithPath: "AppIcon-1024.png")
guard let destination = CGImageDestinationCreateWithURL(masterURL as CFURL, UTType.png.identifier as CFString, 1, nil) else {
    FileHandle.standardError.write(Data("无法创建 PNG 输出\n".utf8))
    exit(1)
}
CGImageDestinationAddImage(destination, image, nil)
guard CGImageDestinationFinalize(destination) else {
    FileHandle.standardError.write(Data("写入 PNG 失败\n".utf8))
    exit(1)
}

// 组装 .iconset
let fm = FileManager.default
try? fm.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

let variants: [(name: String, size: Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024),
]

for variant in variants {
    let dest = URL(fileURLWithPath: outputDir).appendingPathComponent(variant.name)
    if fm.fileExists(atPath: dest.path) { try? fm.removeItem(at: dest) }
    try? fm.copyItem(at: masterURL, to: dest)
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/usr/bin/sips")
    task.arguments = ["-z", String(variant.size), String(variant.size), dest.path, "--out", dest.path]
    try? task.run()
    task.waitUntilExit()
}

try? fm.removeItem(at: masterURL)
print("已生成 iconset：\(outputDir)")
