// 将浅色/深色应用图标处理成带透明通道的 1024x1024 PNG
//
// 源图是带黑色背景的圆角方形，直接使用会在 Dock / README 中出现黑边。
// 这里检测图标主体的范围，用圆角矩形裁剪并输出透明背景。
//
// 用法：swift scripts/prepare-icon.swift <light.png> <dark.png> <输出目录>
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let arguments = CommandLine.arguments
guard arguments.count >= 4 else {
    FileHandle.standardError.write(Data("用法：prepare-icon.swift <light.png> <dark.png> <输出目录>\n".utf8))
    exit(1)
}

let lightPath = arguments[1]
let darkPath = arguments[2]
let outputDir = URL(fileURLWithPath: arguments[3], isDirectory: true)
let canvas = 1024
/// macOS 图标圆角半径约为边长的 22.37%
let cornerRadiusRatio: CGFloat = 0.2237
/// 判定为图标主体的亮度阈值（0-255）
let brightnessThreshold: UInt8 = 12

func loadImage(_ path: String) -> CGImage? {
    guard let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: path) as CFURL, nil) else {
        return nil
    }
    return CGImageSourceCreateImageAtIndex(source, 0, nil)
}

/// 返回图标主体的边长（取宽高中较小者并去掉边缘）
func bodySide(of image: CGImage) -> Int? {
    guard let context = CGContext(
        data: nil,
        width: canvas,
        height: canvas,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { return nil }

    context.interpolationQuality = .high
    context.draw(image, in: CGRect(x: 0, y: 0, width: canvas, height: canvas))
    guard let data = context.data else { return nil }

    let bytesPerRow = context.bytesPerRow
    let pixels = data.bindMemory(to: UInt8.self, capacity: bytesPerRow * canvas)
    var minX = canvas
    var minY = canvas
    var maxX = 0
    var maxY = 0

    for y in 0..<canvas {
        for x in 0..<canvas {
            let offset = y * bytesPerRow + x * 4
            let brightness = max(pixels[offset], max(pixels[offset + 1], pixels[offset + 2]))
            guard brightness > brightnessThreshold else { continue }
            minX = min(minX, x)
            maxX = max(maxX, x)
            minY = min(minY, y)
            maxY = max(maxY, y)
        }
    }

    guard maxX > minX, maxY > minY else { return nil }
    // 去掉 2px 抗锯齿/阴影边缘，避免残留黑边
    return min(maxX - minX, maxY - minY) - 4
}

func maskedImage(_ image: CGImage, side: Int) -> CGImage? {
    guard let context = CGContext(
        data: nil,
        width: canvas,
        height: canvas,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { return nil }

    let rect = CGRect(
        x: CGFloat(canvas - side) / 2,
        y: CGFloat(canvas - side) / 2,
        width: CGFloat(side),
        height: CGFloat(side)
    )
    let path = CGPath(
        roundedRect: rect,
        cornerWidth: rect.width * cornerRadiusRatio,
        cornerHeight: rect.height * cornerRadiusRatio,
        transform: nil
    )

    context.interpolationQuality = .high
    context.addPath(path)
    context.clip()
    context.draw(image, in: CGRect(x: 0, y: 0, width: canvas, height: canvas))
    return context.makeImage()
}

func writePNG(_ image: CGImage, to url: URL) throws {
    guard let destination = CGImageDestinationCreateWithURL(
        url as CFURL,
        UTType.png.identifier as CFString,
        1,
        nil
    ) else {
        throw CocoaError(.fileWriteUnknown)
    }
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else {
        throw CocoaError(.fileWriteUnknown)
    }
}

try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

for (name, path) in [("icon-light-1024.png", lightPath), ("icon-dark-1024.png", darkPath)] {
    guard let image = loadImage(path) else {
        FileHandle.standardError.write(Data("无法读取图标：\(path)\n".utf8))
        exit(1)
    }
    guard let side = bodySide(of: image), side > 0 else {
        FileHandle.standardError.write(Data("无法识别图标主体：\(path)\n".utf8))
        exit(1)
    }
    guard let masked = maskedImage(image, side: side) else {
        FileHandle.standardError.write(Data("无法生成透明图标：\(path)\n".utf8))
        exit(1)
    }
    let output = outputDir.appendingPathComponent(name)
    try writePNG(masked, to: output)
    print("已生成：\(output.path)")
}
