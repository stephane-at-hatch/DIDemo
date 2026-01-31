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

    static var logger: Module {
        Module(
            name: "Logger",
            type: .client
        )
    }

    static var testClient: Module {
        Module(
            name: "TestClient",
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

    static var screenA: Module {
        Module(
            name: "ScreenA",
            type: .screen
        )
    }

    static var screenB: Module {
        Module(
            name: "ScreenB",
            type: .screen
        )
    }

    static var screenC: Module {
        Module(
            name: "ScreenC",
            type: .screen
        )
    }

    static var screenD: Module {
        Module(
            name: "ScreenD",
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

    static var uiComponents: Module {
        Module(
            name: "UIComponents",
            type: .utility,
            hasTests: false
        )
    }
}
