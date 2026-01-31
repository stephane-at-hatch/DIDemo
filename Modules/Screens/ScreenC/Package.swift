// swift-tools-version: 5.10
// ⚠️ Generated file — do not edit by hand
import PackageDescription

let swiftSettings: [PackageDescription.SwiftSetting] = [
    .enableUpcomingFeature("StrictConcurrency")
]
let package = Package(
    name: "ScreenC",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "ScreenC", targets: ["ScreenC"]),
        .library(name: "ScreenCViews", targets: ["ScreenCViews"])
    ],
    dependencies: [
        .package(path: "../../Utilities/ModularDependencyContainer"),
        .package(path: "../../Utilities/ModularNavigation"),
        .package(path: "../../Utilities/UIComponents")
    ],
    targets: [
        .target(
            name: "ScreenC",
            dependencies: [
                .product(name: "ModularDependencyContainer", package: "ModularDependencyContainer"),
                .product(name: "ModularNavigation", package: "ModularNavigation"),
                "ScreenCViews"
            ],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "ScreenCViews",
            dependencies: [
                .product(name: "UIComponents", package: "UIComponents")
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "ScreenCTests",
            dependencies: [
                "ScreenC",
                "ScreenCViews"
            ]
        )
    ]
)