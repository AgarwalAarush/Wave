// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "WaveCore",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "WaveCore",
            targets: ["WaveCore"]
        ),
    ],
    targets: [
        .target(
            name: "WaveCore",
            path: "Wave",
            exclude: [
                "AppDelegate.swift",
                "Assets.xcassets",
                "ContentView.swift",
                "HotKeyManager.swift",
                "SettingsView.swift",
                "Theme.swift",
                "Wave.entitlements",
                "WaveApp.swift",
                "WavePanel.swift",
            ]
        ),
        .testTarget(
            name: "WaveCoreTests",
            dependencies: ["WaveCore"],
            path: "Tests/WaveCoreTests"
        ),
    ]
)
