// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RIOImageKit",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
        .watchOS(.v11),
        .visionOS(.v2),
        .tvOS(.v18)
    ],
    products: [
        .library(
            name: "RIOImageKit",
            targets: ["RIOImageKit"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "RIOImageKit",
            dependencies: [],
            path: "Sources/RIOImageKit",
            swiftSettings: [
                .enableUpcomingFeature("ExistentialAny")
            ]
        ),
        .testTarget(
            name: "RIOImageKitTests",
            dependencies: ["RIOImageKit"],
            path: "Tests/RIOImageKitTests",
            swiftSettings: [
                .enableUpcomingFeature("ExistentialAny")
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
