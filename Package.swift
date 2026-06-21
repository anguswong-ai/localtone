// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "LocalTone",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "LocalToneCore",
            targets: ["LocalToneCore"]
        ),
        .executable(
            name: "LocalTone",
            targets: ["LocalTone"]
        )
    ],
    targets: [
        .target(
            name: "LocalToneCore"
        ),
        .executableTarget(
            name: "LocalTone",
            dependencies: ["LocalToneCore"]
        ),
        .testTarget(
            name: "LocalToneCoreTests",
            dependencies: ["LocalToneCore"]
        )
    ]
)
