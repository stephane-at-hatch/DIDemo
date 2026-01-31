// swift-tools-version: 5.10
// ⚠️ Generated file — do not edit by hand
import PackageDescription

let swiftSettings: [PackageDescription.SwiftSetting] = [
    .enableUpcomingFeature("StrictConcurrency")
]
let package = Package(
    name: "TestClient",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "TestClient", targets: ["TestClient"]),
        .library(name: "TestClientInterface", targets: ["TestClientInterface"])
    ],
    targets: [
        .target(
            name: "TestClient",
            dependencies: [
                "TestClientInterface"
            ],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "TestClientInterface",
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "TestClientTests",
            dependencies: [
                "TestClient",
                "TestClientInterface"
            ]
        )
    ]
)