//
//  main.swift
//  MovieFinderPackageGen
//
//  Created by Stephane Magne on 2026-01-25.
//

import Foundation
import PackageGeneratorCore

// MARK: - Configuration

let configuration = PackageConfiguration(
    swiftToolsVersion: "5.10",
    supportedPlatforms: [
        .iOS(majorVersion: 17)
    ],
    swiftSettings: [
        ".enableUpcomingFeature(\"StrictConcurrency\")"
    ],
    moduleDirectoryConfiguration: ModuleDirectoryConfiguration(
        directoryForType: [
            .screen: "Modules/Screens",
            .utility: "Modules/Utilities",
            .coordinator: "Modules/Coordinators",
            .client: "Modules/Clients",
            .macro: "Modules/Macros"
        ]
    ),
    globalDependencies: [
        .type(.coordinator, target: .main): [
            .module(.modularDependencyContainer)
        ],
        .type(.screen, target: .main): [
            .module(.modularDependencyContainer),
            .module(.modularNavigation)
        ],
        .type(.screen, target: .views): [
            .module(.uiComponents)
        ]
    ]
)

// MARK: - Generate!

// NOTE: You must set the working directory to ${SRCROOT} in the scheme.
//       Go to Options -> Working Directory -> Use Custom Working Directory
let projectRoot = FileManager.default.currentDirectoryPath
print("📍 Project root: \(projectRoot)")
print("📍 Generating packages...\n")

let generator = PackageGenerator(
    graph: graph,
    configuration: configuration,
    rootPath: projectRoot
)

do {
    try generator.generate()
} catch {
    print("\n❌ Generation failed: \(error)")
    exit(1)
}

// MARK: - Generate Dependency Graphs

print("\n📊 Generating dependency graphs...")

let graphRenderer = GraphRenderer(graph: graph, configuration: configuration)

// Target-level graph (detailed)
let detailedDOT = graphRenderer.renderDOT()
let detailedPath = "\(projectRoot)/dependency-graph-detailed.dot"
try detailedDOT.write(toFile: detailedPath, atomically: true, encoding: .utf8)
print("  ✅ dependency-graph-detailed.dot")

// Module-level graph (simplified)
let moduleDOT = graphRenderer.renderModuleLevelDOT()
let modulePath = "\(projectRoot)/dependency-graph-modules.dot"
try moduleDOT.write(toFile: modulePath, atomically: true, encoding: .utf8)
print("  ✅ dependency-graph-modules.dot")

print("\n💡 To render graphs, run:")
print("   dot -Tsvg \(detailedPath) -o \(projectRoot)/dependency-graph-detailed.svg")
print("   dot -Tsvg \(modulePath) -o \(projectRoot)/dependency-graph-modules.svg")
