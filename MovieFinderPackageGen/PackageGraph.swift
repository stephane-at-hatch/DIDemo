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
            .modularDependencyContainer,
            .logger,
            .testClient,
            .appCoordinator
        ]
    ),

    // MARK: Components + Coordinators + Screens

    ModuleNode(
        module: .appCoordinator,
        dependencies: [
            .tabCoordinator
        ]
    ),
    ModuleNode(
        module: .tabCoordinator,
        dependencies: [
            .screenA,
            .screenC,
            .screenD,
            .modularNavigation
        ]
    ),
    ModuleNode(
        module: .screenA,
        dependencies: [
            .main: [
                .module(.screenB),
                .module(.logger),
                .target(.interface, module: .testClient)
            ],
            .views: [
                .target(.interface, module: .testClient)
            ]
        ]
    ),
    ModuleNode(
        module: .screenB,
        dependencies: [
            .main: [
                .module(.logger),
                .target(.interface, module: .testClient)
            ],
            .views: [
                .target(.interface, module: .logger),
                .target(.interface, module: .testClient)
            ]
        ]
    ),
    ModuleNode(
        module: .screenC
    ),
    ModuleNode(
        module: .screenD
    ),

    // MARK: Clients

    ModuleNode(
        module: .logger,
    ),
    ModuleNode(
        module: .testClient,
    ),

    // MARK: Macros

    ModuleNode(
        module: .copyableMacro,
    ),
    ModuleNode(
        module: .dependencyRequirementsMacro,
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
            .copyableMacro
        ],
        exports: [
            .copyableMacro
        ]
    )
]
