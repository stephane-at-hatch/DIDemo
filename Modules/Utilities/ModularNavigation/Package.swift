// swift-tools-version: 5.10
// ⚠️ Generated file — do not edit by hand
import PackageDescription

let swiftSettings: [PackageDescription.SwiftSetting] = [
    .enableUpcomingFeature("StrictConcurrency")
]
let package = Package(
    name: "ModularNavigation",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "ModularNavigation", targets: ["ModularNavigation"])
    ],
    targets: [
        .target(
            name: "ModularNavigation",
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "ModularNavigationTests",
            dependencies: [
                "ModularNavigation"
            ]
        )
    ]
)