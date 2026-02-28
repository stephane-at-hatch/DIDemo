// swift-tools-version: 5.10
// ⚠️ Generated file — do not edit by hand
import PackageDescription

let swiftSettings: [PackageDescription.SwiftSetting] = [
    .enableUpcomingFeature("StrictConcurrency")
]
let package = Package(
    name: "ShareClient",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "ShareClient", targets: ["ShareClient"]),
        .library(name: "ShareClientInterface", targets: ["ShareClientInterface"])
    ],
    targets: [
        .target(
            name: "ShareClient",
            dependencies: [
                "ShareClientInterface"
            ],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "ShareClientInterface",
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "ShareClientTests",
            dependencies: [
                "ShareClient"
            ]
        )
    ]
)