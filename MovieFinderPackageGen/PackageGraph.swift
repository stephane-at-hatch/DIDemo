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
            .movieDomain,
            .tabCoordinator,
            .tmdbClient
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
                .target(.interface, module: .imageLoader)
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
                .target(.interface, module: .imageLoader)
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
                .target(.interface, module: .imageLoader)
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
                .target(.interface, module: .imageLoader)
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
        module: .uiComponents,
        dependencies: [
            .target(.main, module: .copyableMacro),
            .target(.interface, module: .imageLoader)
        ],
        exports: [
            .copyableMacro
        ]
    )
]
