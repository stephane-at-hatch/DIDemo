// swift-tools-version: 5.10
// ⚠️ Generated file — do not edit by hand
import PackageDescription

let swiftSettings: [PackageDescription.SwiftSetting] = [
    .enableUpcomingFeature("StrictConcurrency")
]
let package = Package(
    name: "ModularDependencyContainer",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "ModularDependencyContainer", targets: ["ModularDependencyContainer"])
    ],
    dependencies: [
        .package(path: "../../Macros/DependencyRequirementsMacro")
    ],
    targets: [
        .target(
            name: "ModularDependencyContainer",
            dependencies: [
                .product(name: "DependencyRequirementsMacro", package: "DependencyRequirementsMacro")
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "ModularDependencyContainerTests",
            dependencies: [
                "ModularDependencyContainer"
            ]
        )
    ]
)