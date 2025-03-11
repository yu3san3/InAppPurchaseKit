// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "InAppPurchaseKit",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15),
        .watchOS(.v8),
        .visionOS(.v1),
    ],
    products: [
        .library(
            name: "InAppPurchaseKit",
            targets: ["InAppPurchaseKit"]
        ),
    ],
    targets: [
        .target(
            name: "InAppPurchaseKit"
        ),
        .testTarget(
            name: "InAppPurchaseKitTests",
            dependencies: ["InAppPurchaseKit"]
        ),
    ]
)
