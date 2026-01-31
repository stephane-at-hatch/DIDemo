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
        .package(path: "../TabCoordinator")
    ],
    targets: [
        .target(
            name: "AppCoordinator",
            dependencies: [
                .product(name: "ModularDependencyContainer", package: "ModularDependencyContainer"),
                .product(name: "TabCoordinator", package: "TabCoordinator")
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