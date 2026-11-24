// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "jacksparrow",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "TimerCore"),
        .executableTarget(
            name: "jacksparrow",
            dependencies: ["TimerCore"],
            path: "Sources/jacksparrow",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(name: "TimerCoreTests", dependencies: ["TimerCore"]),
    ]
)
