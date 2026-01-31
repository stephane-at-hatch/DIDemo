// swift-tools-version: 5.10
// ⚠️ Generated file — do not edit by hand
import PackageDescription

let swiftSettings: [PackageDescription.SwiftSetting] = [
    .enableUpcomingFeature("StrictConcurrency")
]
let package = Package(
    name: "TabCoordinator",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "TabCoordinator", targets: ["TabCoordinator"])
    ],
    dependencies: [
        .package(path: "../../Utilities/ModularDependencyContainer"),
        .package(path: "../../Screens/ScreenA"),
        .package(path: "../../Screens/ScreenC"),
        .package(path: "../../Screens/ScreenD"),
        .package(path: "../../Utilities/ModularNavigation")
    ],
    targets: [
        .target(
            name: "TabCoordinator",
            dependencies: [
                .product(name: "ModularDependencyContainer", package: "ModularDependencyContainer"),
                .product(name: "ScreenA", package: "ScreenA"),
                .product(name: "ScreenC", package: "ScreenC"),
                .product(name: "ScreenD", package: "ScreenD"),
                .product(name: "ModularNavigation", package: "ModularNavigation")
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "TabCoordinatorTests",
            dependencies: [
                "TabCoordinator"
            ]
        )
    ]
)