// swift-tools-version: 5.10
// ⚠️ Generated file — do not edit by hand
import PackageDescription
import CompilerPluginSupport

let swiftSettings: [PackageDescription.SwiftSetting] = [
    .enableUpcomingFeature("StrictConcurrency")
]
let package = Package(
    name: "CopyableMacro",
    platforms: [.macOS(.v10_15), .iOS(.v17)],
    products: [
        .library(name: "CopyableMacro", targets: ["CopyableMacro"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0")
    ],
    targets: [
        .target(
            name: "CopyableMacro",
            dependencies: [
                "CopyableMacroImplementation"
            ],
            swiftSettings: swiftSettings
        ),
        .macro(
            name: "CopyableMacroImplementation",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        )
    ]
)