// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "VoodooBuilderApp",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "VoodooHDA-Builder", targets: ["VoodooBuilderApp"])
    ],
    targets: [
        .executableTarget(
            name: "VoodooBuilderApp",
            path: "Sources"
        )
    ]
)