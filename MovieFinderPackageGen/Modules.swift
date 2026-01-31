//
//  Modules.swift
//  MovieFinderPackageGen
//
//  Created by Stephane Magne on 2026-01-25.
//

import PackageGeneratorCore

extension Module {
    // MARK: Root

    static var root: Module {
        Module.root()
    }

    // MARK: Clients

    static var imageLoader: Module {
        Module(
            name: "ImageLoader",
            type: .client
        )
    }

    static var tmdbClient: Module {
        Module(
            name: "TMDBClient",
            type: .client
        )
    }

    // MARK: Coordinators

    static var appCoordinator: Module {
        Module(
            name: "AppCoordinator",
            type: .coordinator,
            targets: [.main]
        )
    }

    static var tabCoordinator: Module {
        Module(
            name: "TabCoordinator",
            type: .coordinator,
            targets: [.main]
        )
    }

    // MARK: Domains

    static var movieDomain: Module {
        Module(
            name: "MovieDomain",
            type: .client
        )
    }

    static var watchlistDomain: Module {
        Module(
            name: "WatchlistDomain",
            type: .client
        )
    }

    // MARK: Macros

    static var copyableMacro: Module {
        Module(
            name: "CopyableMacro",
            type: .macro,
            hasTests: false
        )
    }

    static var dependencyRequirementsMacro: Module {
        Module(
            name: "DependencyRequirementsMacro",
            type: .macro,
            hasTests: false
        )
    }

    // MARK: Screens

    static var boxOfficeScreen: Module {
        Module(
            name: "BoxOfficeScreen",
            type: .screen
        )
    }

    static var detailScreen: Module {
        Module(
            name: "DetailScreen",
            type: .screen
        )
    }

    static var discoverScreen: Module {
        Module(
            name: "DiscoverScreen",
            type: .screen
        )
    }

    static var watchlistScreen: Module {
        Module(
            name: "WatchlistScreen",
            type: .screen
        )
    }

    // MARK: Utilities

    static var modularDependencyContainer: Module {
        Module(
            name: "ModularDependencyContainer",
            type: .utility
        )
    }

    static var modularNavigation: Module {
        Module(
            name: "ModularNavigation",
            type: .utility
        )
    }

    static var sharedUI: Module {
        Module(
            name: "SharedUI",
            type: .utility,
            hasTests: false
        )
    }

    static var uiComponents: Module {
        Module(
            name: "UIComponents",
            type: .utility,
            hasTests: false
        )
    }
}
