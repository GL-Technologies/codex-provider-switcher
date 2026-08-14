// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CodexProviderSwitcherCore",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "CodexProviderCore", targets: ["CodexProviderCore"])
    ],
    targets: [
        .target(
            name: "CodexProviderCore",
            path: "Codex Provider Switcher/Core"
        ),
        .testTarget(
            name: "CodexProviderCoreTests",
            dependencies: ["CodexProviderCore"],
            path: "Tests/CodexProviderCoreTests"
        )
    ]
)
