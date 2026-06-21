// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "ClashGlass",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(name: "ClashGlass", targets: ["ClashGlass"])
    ],
    targets: [
        .target(
            name: "ClashGlassCore",
            path: "Sources/ClashGlassCore"
        ),
        .executableTarget(
            name: "ClashGlass",
            dependencies: ["ClashGlassCore"],
            path: "Sources/ClashGlass"
        ),
        .testTarget(
            name: "ClashGlassTests",
            dependencies: ["ClashGlassCore"],
            path: "Tests/ClashGlassTests"
        )
    ]
)
