// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "InAppPurchaseKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .tvOS(.v17),
        .watchOS(.v10),
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
