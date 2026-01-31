//
//  PackageGraph.swift
//  MovieFinderPackageGen
//
//  Created by Stephane Magne on 2026-01-25.
//

import PackageGeneratorCore

let graph: [ModuleNode] = [
    // MARK: Root

    ModuleNode(
        module: .root,
        dependencies: [
            // Utilities
            .modularDependencyContainer,

            // Clients
            .tmdbClient,
            .imageLoader,

            // Domains
            .movieDomain,
            .watchlistDomain,

            // Coordinators
            .appCoordinator
        ]
    ),

    // MARK: Coordinators

    ModuleNode(
        module: .appCoordinator,
        dependencies: [
            .tabCoordinator
        ]
    ),
    ModuleNode(
        module: .tabCoordinator,
        dependencies: [
            .boxOfficeScreen,
            .discoverScreen,
            .watchlistScreen,
            .modularNavigation
        ]
    ),

    // MARK: Screens

    ModuleNode(
        module: .boxOfficeScreen,
        dependencies: [
            .main: [
                .target(.interface, module: .movieDomain),
                .target(.interface, module: .imageLoader),
                .module(.detailScreen)
            ],
            .views: [
                .target(.interface, module: .movieDomain),
                .target(.interface, module: .imageLoader),
                .module(.sharedUI)
            ]
        ]
    ),
    ModuleNode(
        module: .discoverScreen,
        dependencies: [
            .main: [
                .target(.interface, module: .movieDomain),
                .target(.interface, module: .imageLoader),
                .module(.detailScreen)
            ],
            .views: [
                .target(.interface, module: .movieDomain),
                .target(.interface, module: .imageLoader),
                .module(.sharedUI)
            ]
        ]
    ),
    ModuleNode(
        module: .detailScreen,
        dependencies: [
            .main: [
                .target(.interface, module: .movieDomain),
                .target(.interface, module: .watchlistDomain),
                .target(.interface, module: .imageLoader)
            ],
            .views: [
                .target(.interface, module: .movieDomain),
                .target(.interface, module: .watchlistDomain),
                .target(.interface, module: .imageLoader),
                .module(.sharedUI)
            ]
        ]
    ),
    ModuleNode(
        module: .watchlistScreen,
        dependencies: [
            .main: [
                .target(.interface, module: .watchlistDomain),
                .target(.interface, module: .imageLoader),
                .module(.detailScreen)
            ],
            .views: [
                .target(.interface, module: .watchlistDomain),
                .target(.interface, module: .imageLoader),
                .module(.sharedUI)
            ]
        ]
    ),

    // MARK: Domains

    ModuleNode(
        module: .movieDomain,
        dependencies: [
            .main: [
                .target(.interface, module: .tmdbClient)
            ]
        ]
    ),
    ModuleNode(
        module: .watchlistDomain
        // No external dependencies - uses SwiftData directly
    ),

    // MARK: Clients

    ModuleNode(
        module: .tmdbClient
    ),
    ModuleNode(
        module: .imageLoader
    ),

    // MARK: Macros

    ModuleNode(
        module: .copyableMacro
    ),
    ModuleNode(
        module: .dependencyRequirementsMacro
    ),

    // MARK: Utilities

    ModuleNode(
        module: .modularDependencyContainer,
        dependencies: [
            .dependencyRequirementsMacro
        ],
        exports: [
            .dependencyRequirementsMacro
        ]
    ),
    ModuleNode(
        module: .modularNavigation
    ),
    ModuleNode(
        module: .sharedUI,
        dependencies: [
            .target(.interface, module: .imageLoader)
        ]
    ),
    ModuleNode(
        module: .uiComponents,
        dependencies: [
            .copyableMacro
        ],
        exports: [
            .copyableMacro
        ]
    )
]
