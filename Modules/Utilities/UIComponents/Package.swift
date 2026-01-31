// swift-tools-version: 5.10
// ⚠️ Generated file — do not edit by hand
import PackageDescription

let swiftSettings: [PackageDescription.SwiftSetting] = [
    .enableUpcomingFeature("StrictConcurrency")
]
let package = Package(
    name: "UIComponents",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "UIComponents", targets: ["UIComponents"])
    ],
    dependencies: [
        .package(path: "../../Macros/CopyableMacro")
    ],
    targets: [
        .target(
            name: "UIComponents",
            dependencies: [
                .product(name: "CopyableMacro", package: "CopyableMacro")
            ],
            swiftSettings: swiftSettings
        )
    ]
)