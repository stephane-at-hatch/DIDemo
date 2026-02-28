// swift-tools-version: 5.10
// ⚠️ Generated file — do not edit by hand
import PackageDescription

let swiftSettings: [PackageDescription.SwiftSetting] = [
    .enableUpcomingFeature("StrictConcurrency")
]
let package = Package(
    name: "BoxOfficeScreen",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "BoxOfficeScreen", targets: ["BoxOfficeScreen"]),
        .library(name: "BoxOfficeScreenViews", targets: ["BoxOfficeScreenViews"])
    ],
    dependencies: [
        .package(path: "../../Utilities/ModularDependencyContainer"),
        .package(path: "../../Utilities/ModularNavigation"),
        .package(path: "../../Clients/MovieDomain"),
        .package(path: "../../Clients/ImageLoader"),
        .package(path: "../DetailScreen"),
        .package(path: "../../Components/ShareComponent"),
        .package(path: "../../Utilities/UIComponents")
    ],
    targets: [
        .target(
            name: "BoxOfficeScreen",
            dependencies: [
                .product(name: "ModularDependencyContainer", package: "ModularDependencyContainer"),
                .product(name: "ModularNavigation", package: "ModularNavigation"),
                "BoxOfficeScreenViews",
                .product(name: "MovieDomainInterface", package: "MovieDomain"),
                .product(name: "ImageLoaderInterface", package: "ImageLoader"),
                .product(name: "DetailScreen", package: "DetailScreen"),
                .product(name: "ShareComponent", package: "ShareComponent")
            ],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "BoxOfficeScreenViews",
            dependencies: [
                .product(name: "UIComponents", package: "UIComponents"),
                .product(name: "MovieDomainInterface", package: "MovieDomain"),
                .product(name: "ImageLoaderInterface", package: "ImageLoader")
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "BoxOfficeScreenTests",
            dependencies: [
                "BoxOfficeScreen"
            ]
        )
    ]
)