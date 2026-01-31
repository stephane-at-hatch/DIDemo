// swift-tools-version: 5.10
// ⚠️ Generated file — do not edit by hand
import PackageDescription

let package = Package(
    name: "Modules",
    platforms: [.iOS(.v17)],
    dependencies: [
        // Utilities
        .package(path: "Utilities/ModularDependencyContainer"),

        // Clients
        .package(path: "Clients/Logger"),
        .package(path: "Clients/TestClient"),

        // Coordinators
        .package(path: "Coordinators/AppCoordinator")
    ],
    targets: [
        // ⚠️ NOT FOR PRODUCTION USE
        // This target exists only for workspace visibility and code search.
        // The main app should import modules directly, not through this target.
        //
        // When adding a new module:
        // 1. Add the package to `dependencies` above
        // 2. Add the product to this target's `dependencies` below
        .target(
            name: "ModulesTestTarget",
            dependencies: [
                // Utilities
                .product(name: "ModularDependencyContainer", package: "ModularDependencyContainer"),

                // Clients
                .product(name: "Logger", package: "Logger"),
                .product(name: "TestClient", package: "TestClient"),

                // Coordinators
                .product(name: "AppCoordinator", package: "AppCoordinator")
            ],
            path: "_"
        )
    ]
)