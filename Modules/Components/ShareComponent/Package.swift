// swift-tools-version: 5.10
// ⚠️ Generated file — do not edit by hand
import PackageDescription

let swiftSettings: [PackageDescription.SwiftSetting] = [
    .enableUpcomingFeature("StrictConcurrency")
]
let package = Package(
    name: "ShareComponent",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "ShareComponent", targets: ["ShareComponent"]),
        .library(name: "ShareComponentViews", targets: ["ShareComponentViews"])
    ],
    dependencies: [
        .package(path: "../../Utilities/ModularDependencyContainer"),
        .package(path: "../../Clients/ShareClient")
    ],
    targets: [
        .target(
            name: "ShareComponent",
            dependencies: [
                .product(name: "ModularDependencyContainer", package: "ModularDependencyContainer"),
                "ShareComponentViews",
                .product(name: "ShareClient", package: "ShareClient")
            ],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "ShareComponentViews",
            dependencies: [
                .product(name: "ShareClient", package: "ShareClient")
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "ShareComponentTests",
            dependencies: [
                "ShareComponent"
            ]
        )
    ]
)