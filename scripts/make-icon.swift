// Draws the dockpin icon: a Dock bar held down by a pin.
//   swift scripts/make-icon.swift Resources   → Resources/AppIcon.icns + docs-ready PNG
import AppKit

let outDir = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "Resources")

func draw(size: CGFloat) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size),
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let s = size / 1024  // design on a 1024 grid

    // Squircle background, inset like Apple's template (824 of 1024).
    let bg = NSBezierPath(roundedRect: NSRect(x: 100 * s, y: 100 * s, width: 824 * s, height: 824 * s),
                          xRadius: 185 * s, yRadius: 185 * s)
    NSGradient(colors: [NSColor(srgbRed: 0.18, green: 0.24, blue: 0.52, alpha: 1),
                        NSColor(srgbRed: 0.33, green: 0.47, blue: 0.93, alpha: 1)])!
        .draw(in: bg, angle: 90)

    // The Dock: a frosted bar with three app tiles.
    let bar = NSRect(x: 196 * s, y: 236 * s, width: 632 * s, height: 150 * s)
    NSColor(white: 1, alpha: 0.92).setFill()
    NSBezierPath(roundedRect: bar, xRadius: 48 * s, yRadius: 48 * s).fill()
    let tileColors: [NSColor] = [
        NSColor(srgbRed: 0.98, green: 0.62, blue: 0.20, alpha: 1),
        NSColor(srgbRed: 0.28, green: 0.78, blue: 0.47, alpha: 1),
        NSColor(srgbRed: 0.36, green: 0.55, blue: 0.98, alpha: 1),
    ]
    for (i, color) in tileColors.enumerated() {
        color.setFill()
        let x = 256 * s + CGFloat(i) * 180 * s
        NSBezierPath(roundedRect: NSRect(x: x, y: 271 * s, width: 80 * s, height: 80 * s),
                     xRadius: 20 * s, yRadius: 20 * s).fill()
    }

    // The pin, needle stuck into the bar's right end.
    let needle = NSBezierPath()
    needle.move(to: NSPoint(x: 764 * s, y: 312 * s))
    needle.line(to: NSPoint(x: 742 * s, y: 560 * s))
    needle.line(to: NSPoint(x: 778 * s, y: 562 * s))
    needle.close()
    NSColor(white: 0.85, alpha: 1).setFill()
    needle.fill()
    let head = NSRect(x: 655 * s, y: 520 * s, width: 210 * s, height: 210 * s)
    NSGradient(colors: [NSColor(srgbRed: 0.80, green: 0.10, blue: 0.16, alpha: 1),
                        NSColor(srgbRed: 1.00, green: 0.33, blue: 0.33, alpha: 1)])!
        .draw(in: NSBezierPath(ovalIn: head), relativeCenterPosition: NSPoint(x: -0.3, y: 0.4))
    NSColor(white: 1, alpha: 0.55).setFill()
    NSBezierPath(ovalIn: NSRect(x: 705 * s, y: 640 * s, width: 56 * s, height: 44 * s)).fill()

    NSGraphicsContext.restoreGraphicsState()
    return rep
}

let iconset = FileManager.default.temporaryDirectory.appendingPathComponent("AppIcon.iconset")
try? FileManager.default.removeItem(at: iconset)
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
for base in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let name = scale == 1 ? "icon_\(base)x\(base).png" : "icon_\(base)x\(base)@2x.png"
        let png = draw(size: CGFloat(base * scale)).representation(using: .png, properties: [:])!
        try png.write(to: iconset.appendingPathComponent(name))
    }
}
try draw(size: 512).representation(using: .png, properties: [:])!
    .write(to: outDir.appendingPathComponent("dockpin-512.png"))

let iconutil = Process()
iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
iconutil.arguments = ["-c", "icns", iconset.path, "-o", outDir.appendingPathComponent("AppIcon.icns").path]
try iconutil.run()
iconutil.waitUntilExit()
print("wrote \(outDir.path)/AppIcon.icns")
