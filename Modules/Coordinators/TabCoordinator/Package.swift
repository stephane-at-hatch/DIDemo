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
        .package(path: "../../Screens/BoxOfficeScreen"),
        .package(path: "../../Screens/DiscoverScreen"),
        .package(path: "../../Screens/WatchlistScreen"),
        .package(path: "../../Utilities/ModularNavigation")
    ],
    targets: [
        .target(
            name: "TabCoordinator",
            dependencies: [
                .product(name: "ModularDependencyContainer", package: "ModularDependencyContainer"),
                .product(name: "BoxOfficeScreen", package: "BoxOfficeScreen"),
                .product(name: "DiscoverScreen", package: "DiscoverScreen"),
                .product(name: "WatchlistScreen", package: "WatchlistScreen"),
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