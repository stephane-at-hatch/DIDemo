// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "ModularDependencyAnalyzer",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "ModularDependencyAnalyzer", targets: ["ModularDependencyAnalyzer"])
    ],
    dependencies: [
        .package(
            // SwiftSyntax
            // https://github.com/swiftlang/swift-syntax/releases
            url: "https://github.com/swiftlang/swift-syntax.git", "509.0.0"..<"602.0.0"
        )
    ],
    targets: [
        .executableTarget(
            name: "ModularDependencyAnalyzer",
            dependencies: [
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax")
            ]
        )
    ]
)
