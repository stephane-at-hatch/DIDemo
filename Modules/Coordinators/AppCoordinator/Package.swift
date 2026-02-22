// swift-tools-version: 5.10
// ⚠️ Generated file — do not edit by hand
import PackageDescription

let swiftSettings: [PackageDescription.SwiftSetting] = [
    .enableUpcomingFeature("StrictConcurrency")
]
let package = Package(
    name: "AppCoordinator",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "AppCoordinator", targets: ["AppCoordinator"])
    ],
    dependencies: [
        .package(path: "../../Utilities/ModularDependencyContainer"),
        .package(path: "../../Clients/MovieDomain"),
        .package(path: "../TabCoordinator"),
        .package(path: "../../Clients/TMDBClient"),
        .package(path: "../../Clients/WatchlistDomain")
    ],
    targets: [
        .target(
            name: "AppCoordinator",
            dependencies: [
                .product(name: "ModularDependencyContainer", package: "ModularDependencyContainer"),
                .product(name: "MovieDomain", package: "MovieDomain"),
                .product(name: "TabCoordinator", package: "TabCoordinator"),
                .product(name: "TMDBClient", package: "TMDBClient"),
                .product(name: "WatchlistDomain", package: "WatchlistDomain")
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "AppCoordinatorTests",
            dependencies: [
                "AppCoordinator"
            ]
        )
    ]
)