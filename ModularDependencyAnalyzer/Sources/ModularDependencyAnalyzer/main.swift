import Foundation

// MARK: - Main Entry Point

func main() {
    // Parse configuration
    let config = Configuration.parse()

    printBanner(config: config)

    // Verify paths exist
    guard verifyPaths(config: config) else {
        exit(1)
    }

    // Build module graph
    print("\nBuilding module dependency graph (\(config.mode.rawValue) mode)...")
    let moduleGraph = buildModuleGraph(config: config)

    let nonTestModules = moduleGraph.allModuleNames.filter { !isTestModule($0) }
    print("Found \(nonTestModules.count) modules: \(nonTestModules.sorted().joined(separator: ", "))")

    // If --graph flag, print module graph and exit
    if config.graphOnly {
        let reporter = Reporter(
            graphs: [],
            scanResults: ScanResults(
                nodes: [],
                roots: [],
                edges: [],
                requirementsByModule: [:],
                inputRequirementsByModule: [:],
                provisionsByModule: [:],
                providedInputsByModule: [:],
                testDependencyProviderConformancesByModule: [:],
                mockRegistrationImplementationsByModule: [:],
                importDependenciesByModule: [:],
                mockRegistrationsByModule: [:],
                mockProvidedInputTypesByModule: [:]
            ),
            moduleGraph: moduleGraph,
            diagnostics: [],
            orphanNodes: []
        )
        reporter.printModuleGraphOnly()
        exit(0)
    }

    // Initialize cache
    let cache = FileCache(projectRoot: config.projectRoot, mode: config.cacheMode)

    // Find all Swift files
    var allFiles = findSwiftFiles(at: config.projectRoot)
    if let appSourceDir = config.appSourceDirectory {
        allFiles.append(contentsOf: findSwiftFiles(at: appSourceDir))
    }
    print("Found \(allFiles.count) Swift files to analyze.")

    // Scan all files
    print("\nScanning files...")
    let scanner = Scanner(moduleGraph: moduleGraph, cache: cache)
    let scanResults = scanner.scanAll(files: allFiles)

    // Prune and save cache
    cache.pruneStaleEntries()
    cache.save()
    cache.printStats()

    // Check for cache-only failures
    if cache.isCacheOnly, cache.hasMisses {
        print("\nError: --cache-only specified but some files were not in cache.")
        print("       Run a full build first to populate the cache.")
        exit(1)
    }

    print("\nDiscovered \(scanResults.nodes.count) nodes, \(scanResults.roots.count) graph roots")

    // If --test-all flag, run all test reports and exit
    if config.testAll {
        let reporter = Reporter(
            graphs: [],
            scanResults: scanResults,
            moduleGraph: moduleGraph,
            diagnostics: [],
            orphanNodes: []
        )
        reporter.printTestAdoptionReport()
        reporter.printTestAlignmentReport()
        reporter.printTestRedundancyReport()
        exit(0)
    }

    // If --test-adoption flag, print adoption report and exit
    if config.testAdoption {
        let reporter = Reporter(
            graphs: [],
            scanResults: scanResults,
            moduleGraph: moduleGraph,
            diagnostics: [],
            orphanNodes: []
        )
        reporter.printTestAdoptionReport()
        exit(0)
    }

    // If --test-alignment flag, print alignment report and exit
    if config.testAlignment {
        let reporter = Reporter(
            graphs: [],
            scanResults: scanResults,
            moduleGraph: moduleGraph,
            diagnostics: [],
            orphanNodes: []
        )
        reporter.printTestAlignmentReport()
        exit(0)
    }

    // If --test-redundancy flag, print redundancy report and exit
    if config.testRedundancy {
        let reporter = Reporter(
            graphs: [],
            scanResults: scanResults,
            moduleGraph: moduleGraph,
            diagnostics: [],
            orphanNodes: []
        )
        reporter.printTestRedundancyReport()
        exit(0)
    }

    // Build graphs
    print("Building dependency graphs...")
    let graphBuilder = GraphBuilder(scanResults: scanResults, moduleGraph: moduleGraph)
    let buildResult = graphBuilder.build()

    print("Built \(buildResult.graphs.count) graph(s)")
    if !buildResult.orphanNodes.isEmpty {
        print("Found \(buildResult.orphanNodes.count) orphan node(s)")
    }

    // If --dependency-graph flag, print DI graphs and exit
    if config.dependencyGraphOnly {
        let reporter = Reporter(
            graphs: buildResult.graphs,
            scanResults: scanResults,
            moduleGraph: moduleGraph,
            diagnostics: [],
            orphanNodes: buildResult.orphanNodes
        )
        reporter.printDependencyGraphOnly()
        exit(0)
    }

    // If --find-dependency flag, run find and exit
    if let depName = config.findDependency {
        let analyzer = Analyzer(
            buildResult: buildResult,
            scanResults: scanResults,
            moduleGraph: moduleGraph
        )
        let results = analyzer.findDependency(depName)

        print("\n" + String(repeating: "=", count: 60))
        print("FIND DEPENDENCY: \(depName)")
        print(String(repeating: "=", count: 60))

        if results.isEmpty {
            print("\n  Dependency '\(depName)' is not registered or requested in any graph.")
        } else {
            for diagnostic in results {
                print("\n  \(diagnostic.message)")
                if let graph = diagnostic.graph {
                    print("     Graph: \(graph.displayName)")
                }
                if let location = diagnostic.location {
                    print("     Location: \(location.fileName):\(location.line)")
                }
                for line in diagnostic.context {
                    print("     \(line)")
                }
            }
        }

        print("")
        exit(0)
    }

    // Analyze graphs
    print("Analyzing graphs...")
    let analyzer = Analyzer(
        buildResult: buildResult,
        scanResults: scanResults,
        moduleGraph: moduleGraph,
        showValid: config.showValid
    )
    let diagnostics = analyzer.analyze()

    // Report results
    let reporter = Reporter(
        graphs: buildResult.graphs,
        scanResults: scanResults,
        moduleGraph: moduleGraph,
        diagnostics: diagnostics,
        orphanNodes: buildResult.orphanNodes
    )
    reporter.printFullReport()

    exit(reporter.exitCode)
}

// MARK: - Helper Functions

func printBanner(config: Configuration) {
    print("ModularDependencyAnalyzer")
    print(String(repeating: "-", count: 60))
    print("App Name:    \(config.appName)")
    print("Project:     \(config.projectRoot.path)")
    print("Modules:     \(config.modulesDirectory.path)")
    print("Mode:        \(config.mode.rawValue)")
    if let appSourceDir = config.appSourceDirectory {
        print("App Source:  \(appSourceDir.path)")
    }
    switch config.cacheMode {
    case .cacheOnly:
        print("Cache:       cache-only (fast mode)")
    case .noCache:
        print("Cache:       disabled")
    case .normal:
        break
    }
    print(String(repeating: "-", count: 60))
}

func verifyPaths(config: Configuration) -> Bool {
    var isDirectory: ObjCBool = false
    let projectExists = FileManager.default.fileExists(
        atPath: config.projectRoot.path,
        isDirectory: &isDirectory
    )

    guard projectExists, isDirectory.boolValue else {
        print("Error: Project root does not exist or is not a directory:")
        print("       \(config.projectRoot.path)")
        return false
    }

    if !FileManager.default.fileExists(atPath: config.modulesDirectory.path, isDirectory: &isDirectory) {
        print("Warning: Modules directory does not exist: \(config.modulesDirectory.path)")
        print("         Continuing with project root for file scanning...")
    }

    return true
}

func buildModuleGraph(config: Configuration) -> ModuleGraph {
    let moduleGraph = ModuleGraph()

    switch config.mode {
    case .distributed:
        let packageFiles = findPackageSwiftFiles(at: config.projectRoot)
        for packageFile in packageFiles {
            if let info = parseDistributedPackage(at: packageFile) {
                moduleGraph.addModule(info)
            }
        }

    case .monorepo:
        let packageSwiftURL = config.projectRoot.appendingPathComponent("Package.swift")
        if FileManager.default.fileExists(atPath: packageSwiftURL.path) {
            let modules = parseMonorepoPackage(at: packageSwiftURL)
            for module in modules {
                moduleGraph.addModule(module)
            }
        } else {
            print("Error: No Package.swift found at \(packageSwiftURL.path)")
            exit(1)
        }
    }

    moduleGraph.buildDependentsGraph()
    return moduleGraph
}

// MARK: - Entry Point

main()
