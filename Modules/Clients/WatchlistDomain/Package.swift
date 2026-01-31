// swift-tools-version: 5.10
// ⚠️ Generated file — do not edit by hand
import PackageDescription

let swiftSettings: [PackageDescription.SwiftSetting] = [
    .enableUpcomingFeature("StrictConcurrency")
]
let package = Package(
    name: "WatchlistDomain",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "WatchlistDomain", targets: ["WatchlistDomain"]),
        .library(name: "WatchlistDomainInterface", targets: ["WatchlistDomainInterface"])
    ],
    targets: [
        .target(
            name: "WatchlistDomain",
            dependencies: [
                "WatchlistDomainInterface"
            ],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "WatchlistDomainInterface",
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "WatchlistDomainTests",
            dependencies: [
                "WatchlistDomain"
            ]
        )
    ]
)