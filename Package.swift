// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "proj-info",
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", .upToNextMinor(from: "1.2.1"))
    ],
    targets: [
        .executableTarget(
            name: "proj-info",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        )
    ]
)
