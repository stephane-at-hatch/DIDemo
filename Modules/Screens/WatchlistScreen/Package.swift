// swift-tools-version: 5.10
// ⚠️ Generated file — do not edit by hand
import PackageDescription

let swiftSettings: [PackageDescription.SwiftSetting] = [
    .enableUpcomingFeature("StrictConcurrency")
]
let package = Package(
    name: "WatchlistScreen",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "WatchlistScreen", targets: ["WatchlistScreen"]),
        .library(name: "WatchlistScreenViews", targets: ["WatchlistScreenViews"])
    ],
    dependencies: [
        .package(path: "../../Utilities/ModularDependencyContainer"),
        .package(path: "../../Utilities/ModularNavigation"),
        .package(path: "../../Clients/WatchlistDomain"),
        .package(path: "../../Clients/TMDBClient"),
        .package(path: "../../Clients/ImageLoader"),
        .package(path: "../DetailScreen"),
        .package(path: "../../Clients/ShareClient"),
        .package(path: "../../Components/ShareComponent"),
        .package(path: "../../Utilities/UIComponents")
    ],
    targets: [
        .target(
            name: "WatchlistScreen",
            dependencies: [
                .product(name: "ModularDependencyContainer", package: "ModularDependencyContainer"),
                .product(name: "ModularNavigation", package: "ModularNavigation"),
                "WatchlistScreenViews",
                .product(name: "WatchlistDomainInterface", package: "WatchlistDomain"),
                .product(name: "TMDBClientInterface", package: "TMDBClient"),
                .product(name: "ImageLoaderInterface", package: "ImageLoader"),
                .product(name: "DetailScreen", package: "DetailScreen"),
                .product(name: "ShareClientInterface", package: "ShareClient"),
                .product(name: "ShareClient", package: "ShareClient"),
                .product(name: "ShareComponent", package: "ShareComponent")
            ],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "WatchlistScreenViews",
            dependencies: [
                .product(name: "UIComponents", package: "UIComponents"),
                .product(name: "WatchlistDomainInterface", package: "WatchlistDomain"),
                .product(name: "ImageLoaderInterface", package: "ImageLoader")
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "WatchlistScreenTests",
            dependencies: [
                "WatchlistScreen"
            ]
        )
    ]
)