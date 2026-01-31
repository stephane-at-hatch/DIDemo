// swift-tools-version: 5.10
// ⚠️ Generated file — do not edit by hand
import PackageDescription

let swiftSettings: [PackageDescription.SwiftSetting] = [
    .enableUpcomingFeature("StrictConcurrency")
]
let package = Package(
    name: "ScreenD",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "ScreenD", targets: ["ScreenD"]),
        .library(name: "ScreenDViews", targets: ["ScreenDViews"])
    ],
    dependencies: [
        .package(path: "../../Utilities/ModularDependencyContainer"),
        .package(path: "../../Utilities/ModularNavigation"),
        .package(path: "../../Utilities/UIComponents")
    ],
    targets: [
        .target(
            name: "ScreenD",
            dependencies: [
                .product(name: "ModularDependencyContainer", package: "ModularDependencyContainer"),
                .product(name: "ModularNavigation", package: "ModularNavigation"),
                "ScreenDViews"
            ],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "ScreenDViews",
            dependencies: [
                .product(name: "UIComponents", package: "UIComponents")
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "ScreenDTests",
            dependencies: [
                "ScreenD",
                "ScreenDViews"
            ]
        )
    ]
)