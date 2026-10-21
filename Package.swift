// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "dockpin",
    platforms: [.macOS(.v13)],
    targets: [
        // Pure geometry: which screen edges to guard. No AppKit, fully testable.
        .target(name: "DockpinCore"),
        .executableTarget(
            name: "dockpin",
            dependencies: ["DockpinCore"]
        ),
        .testTarget(
            name: "DockpinCoreTests",
            dependencies: ["DockpinCore"]
        ),
    ]
)
