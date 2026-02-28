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
        .package(path: "Clients/ImageLoader"),
        .package(path: "Clients/MovieDomain"),
        .package(path: "Clients/ShareClient"),
        .package(path: "Clients/TMDBClient"),
        .package(path: "Clients/WatchlistDomain"),

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
                .product(name: "ImageLoader", package: "ImageLoader"),
                .product(name: "MovieDomain", package: "MovieDomain"),
                .product(name: "ShareClient", package: "ShareClient"),
                .product(name: "TMDBClient", package: "TMDBClient"),
                .product(name: "WatchlistDomain", package: "WatchlistDomain"),

                // Coordinators
                .product(name: "AppCoordinator", package: "AppCoordinator")
            ],
            path: "_"
        )
    ]
)