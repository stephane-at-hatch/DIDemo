// swift-tools-version: 5.10
// ⚠️ Generated file — do not edit by hand
import PackageDescription

let swiftSettings: [PackageDescription.SwiftSetting] = [
    .enableUpcomingFeature("StrictConcurrency")
]
let package = Package(
    name: "DetailScreen",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "DetailScreen", targets: ["DetailScreen"]),
        .library(name: "DetailScreenViews", targets: ["DetailScreenViews"])
    ],
    dependencies: [
        .package(path: "../../Utilities/ModularDependencyContainer"),
        .package(path: "../../Utilities/ModularNavigation"),
        .package(path: "../../Clients/MovieDomain"),
        .package(path: "../../Clients/WatchlistDomain"),
        .package(path: "../../Clients/ImageLoader"),
        .package(path: "../../Utilities/UIComponents"),
        .package(path: "../../Clients/TMDBClient")
    ],
    targets: [
        .target(
            name: "DetailScreen",
            dependencies: [
                .product(name: "ModularDependencyContainer", package: "ModularDependencyContainer"),
                .product(name: "ModularNavigation", package: "ModularNavigation"),
                "DetailScreenViews",
                .product(name: "MovieDomainInterface", package: "MovieDomain"),
                .product(name: "WatchlistDomainInterface", package: "WatchlistDomain"),
                .product(name: "ImageLoaderInterface", package: "ImageLoader")
            ],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "DetailScreenViews",
            dependencies: [
                .product(name: "UIComponents", package: "UIComponents"),
                .product(name: "MovieDomainInterface", package: "MovieDomain"),
                .product(name: "WatchlistDomainInterface", package: "WatchlistDomain"),
                .product(name: "TMDBClientInterface", package: "TMDBClient"),
                .product(name: "ImageLoaderInterface", package: "ImageLoader")
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "DetailScreenTests",
            dependencies: [
                "DetailScreen"
            ]
        )
    ]
)