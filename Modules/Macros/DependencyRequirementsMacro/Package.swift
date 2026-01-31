// swift-tools-version: 5.10
// ⚠️ Generated file — do not edit by hand
import PackageDescription
import CompilerPluginSupport

let swiftSettings: [PackageDescription.SwiftSetting] = [
    .enableUpcomingFeature("StrictConcurrency")
]
let package = Package(
    name: "DependencyRequirementsMacro",
    platforms: [.macOS(.v10_15), .iOS(.v17)],
    products: [
        .library(name: "DependencyRequirementsMacro", targets: ["DependencyRequirementsMacro"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0")
    ],
    targets: [
        .target(
            name: "DependencyRequirementsMacro",
            dependencies: [
                "DependencyRequirementsMacroImplementation"
            ],
            swiftSettings: swiftSettings
        ),
        .macro(
            name: "DependencyRequirementsMacroImplementation",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        )
    ]
)