// swift-tools-version: 5.10
// ⚠️ Generated file — do not edit by hand
import PackageDescription

let swiftSettings: [PackageDescription.SwiftSetting] = [
    .enableUpcomingFeature("StrictConcurrency")
]
let package = Package(
    name: "Logger",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "Logger", targets: ["Logger"]),
        .library(name: "LoggerInterface", targets: ["LoggerInterface"])
    ],
    targets: [
        .target(
            name: "Logger",
            dependencies: [
                "LoggerInterface"
            ],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "LoggerInterface",
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "LoggerTests",
            dependencies: [
                "Logger",
                "LoggerInterface"
            ]
        )
    ]
)