// swift-tools-version: 5.10
// ⚠️ Generated file — do not edit by hand
import PackageDescription

let swiftSettings: [PackageDescription.SwiftSetting] = [
    .enableUpcomingFeature("StrictConcurrency")
]
let package = Package(
    name: "ScreenA",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "ScreenA", targets: ["ScreenA"]),
        .library(name: "ScreenAViews", targets: ["ScreenAViews"])
    ],
    dependencies: [
        .package(path: "../../Utilities/ModularDependencyContainer"),
        .package(path: "../../Utilities/ModularNavigation"),
        .package(path: "../ScreenB"),
        .package(path: "../../Clients/Logger"),
        .package(path: "../../Clients/TestClient"),
        .package(path: "../../Utilities/UIComponents")
    ],
    targets: [
        .target(
            name: "ScreenA",
            dependencies: [
                .product(name: "ModularDependencyContainer", package: "ModularDependencyContainer"),
                .product(name: "ModularNavigation", package: "ModularNavigation"),
                "ScreenAViews",
                .product(name: "ScreenB", package: "ScreenB"),
                .product(name: "Logger", package: "Logger"),
                .product(name: "TestClientInterface", package: "TestClient")
            ],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "ScreenAViews",
            dependencies: [
                .product(name: "UIComponents", package: "UIComponents"),
                .product(name: "TestClientInterface", package: "TestClient")
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "ScreenATests",
            dependencies: [
                "ScreenA",
                "ScreenAViews"
            ]
        )
    ]
)