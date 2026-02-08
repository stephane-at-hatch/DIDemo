// swift-tools-version: 5.10
// ⚠️ Generated file — do not edit by hand
import PackageDescription

let swiftSettings: [PackageDescription.SwiftSetting] = [
    .enableUpcomingFeature("StrictConcurrency")
]
let package = Package(
    name: "DiscoverScreen",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "DiscoverScreen", targets: ["DiscoverScreen"]),
        .library(name: "DiscoverScreenViews", targets: ["DiscoverScreenViews"])
    ],
    dependencies: [
        .package(path: "../../Utilities/ModularDependencyContainer"),
        .package(path: "../../Utilities/ModularNavigation"),
        .package(path: "../../Clients/MovieDomain"),
        .package(path: "../../Clients/ImageLoader"),
        .package(path: "../DetailScreen"),
        .package(path: "../../Utilities/UIComponents")
    ],
    targets: [
        .target(
            name: "DiscoverScreen",
            dependencies: [
                .product(name: "ModularDependencyContainer", package: "ModularDependencyContainer"),
                .product(name: "ModularNavigation", package: "ModularNavigation"),
                "DiscoverScreenViews",
                .product(name: "MovieDomainInterface", package: "MovieDomain"),
                .product(name: "ImageLoaderInterface", package: "ImageLoader"),
                .product(name: "DetailScreen", package: "DetailScreen")
            ],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "DiscoverScreenViews",
            dependencies: [
                .product(name: "UIComponents", package: "UIComponents"),
                .product(name: "MovieDomainInterface", package: "MovieDomain"),
                .product(name: "ImageLoaderInterface", package: "ImageLoader")
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "DiscoverScreenTests",
            dependencies: [
                "DiscoverScreen"
            ]
        )
    ]
)