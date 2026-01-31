// swift-tools-version: 5.10
// ⚠️ Generated file — do not edit by hand
import PackageDescription

let swiftSettings: [PackageDescription.SwiftSetting] = [
    .enableUpcomingFeature("StrictConcurrency")
]
let package = Package(
    name: "MovieDomain",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "MovieDomain", targets: ["MovieDomain"]),
        .library(name: "MovieDomainInterface", targets: ["MovieDomainInterface"])
    ],
    dependencies: [
        .package(path: "../TMDBClient")
    ],
    targets: [
        .target(
            name: "MovieDomain",
            dependencies: [
                "MovieDomainInterface",
                .product(name: "TMDBClientInterface", package: "TMDBClient")
            ],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "MovieDomainInterface",
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "MovieDomainTests",
            dependencies: [
                "MovieDomain"
            ]
        )
    ]
)