// swift-tools-version: 5.10
// ⚠️ Generated file — do not edit by hand
import PackageDescription

let swiftSettings: [PackageDescription.SwiftSetting] = [
    .enableUpcomingFeature("StrictConcurrency")
]
let package = Package(
    name: "SharedUI",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "SharedUI", targets: ["SharedUI"])
    ],
    dependencies: [
        .package(path: "../../Clients/ImageLoader")
    ],
    targets: [
        .target(
            name: "SharedUI",
            dependencies: [
                .product(name: "ImageLoaderInterface", package: "ImageLoader")
            ],
            swiftSettings: swiftSettings
        )
    ]
)