// swift-tools-version: 5.10
// ⚠️ Generated file — do not edit by hand
import PackageDescription

let swiftSettings: [PackageDescription.SwiftSetting] = [
    .enableUpcomingFeature("StrictConcurrency")
]
let package = Package(
    name: "ImageLoader",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "ImageLoader", targets: ["ImageLoader"]),
        .library(name: "ImageLoaderInterface", targets: ["ImageLoaderInterface"])
    ],
    targets: [
        .target(
            name: "ImageLoader",
            dependencies: [
                "ImageLoaderInterface"
            ],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "ImageLoaderInterface",
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "ImageLoaderTests",
            dependencies: [
                "ImageLoader"
            ]
        )
    ]
)