// swift-tools-version: 5.10
// ⚠️ Generated file — do not edit by hand
import PackageDescription

let swiftSettings: [PackageDescription.SwiftSetting] = [
    .enableUpcomingFeature("StrictConcurrency")
]
let package = Package(
    name: "TMDBClient",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "TMDBClient", targets: ["TMDBClient"]),
        .library(name: "TMDBClientInterface", targets: ["TMDBClientInterface"])
    ],
    targets: [
        .target(
            name: "TMDBClient",
            dependencies: [
                "TMDBClientInterface"
            ],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "TMDBClientInterface",
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "TMDBClientTests",
            dependencies: [
                "TMDBClient"
            ]
        )
    ]
)