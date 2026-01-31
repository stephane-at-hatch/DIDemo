// swift-tools-version: 5.10
// ⚠️ Generated file — do not edit by hand
import PackageDescription

let swiftSettings: [PackageDescription.SwiftSetting] = [
    .enableUpcomingFeature("StrictConcurrency")
]
let package = Package(
    name: "ScreenB",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "ScreenB", targets: ["ScreenB"]),
        .library(name: "ScreenBViews", targets: ["ScreenBViews"])
    ],
    dependencies: [
        .package(path: "../../Utilities/ModularDependencyContainer"),
        .package(path: "../../Utilities/ModularNavigation"),
        .package(path: "../../Clients/Logger"),
        .package(path: "../../Clients/TestClient"),
        .package(path: "../../Utilities/UIComponents")
    ],
    targets: [
        .target(
            name: "ScreenB",
            dependencies: [
                .product(name: "ModularDependencyContainer", package: "ModularDependencyContainer"),
                .product(name: "ModularNavigation", package: "ModularNavigation"),
                "ScreenBViews",
                .product(name: "Logger", package: "Logger"),
                .product(name: "TestClientInterface", package: "TestClient")
            ],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "ScreenBViews",
            dependencies: [
                .product(name: "UIComponents", package: "UIComponents"),
                .product(name: "LoggerInterface", package: "Logger"),
                .product(name: "TestClientInterface", package: "TestClient")
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "ScreenBTests",
            dependencies: [
                "ScreenB",
                "ScreenBViews"
            ]
        )
    ]
)