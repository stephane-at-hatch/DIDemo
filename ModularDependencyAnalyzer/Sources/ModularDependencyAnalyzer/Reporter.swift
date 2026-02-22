import Foundation

// MARK: - Reporter

/// Formats and outputs analysis results
class Reporter {
    private let graphs: [DependencyGraph]
    private let scanResults: ScanResults
    private let moduleGraph: ModuleGraph
    private let diagnostics: [Diagnostic]
    private let orphanNodes: [DiscoveredNode]

    init(
        graphs: [DependencyGraph],
        scanResults: ScanResults,
        moduleGraph: ModuleGraph,
        diagnostics: [Diagnostic],
        orphanNodes: [DiscoveredNode]
    ) {
        self.graphs = graphs
        self.scanResults = scanResults
        self.moduleGraph = moduleGraph
        self.diagnostics = diagnostics
        self.orphanNodes = orphanNodes
    }

    // MARK: - Main Output Methods

    /// Prints full analysis report
    func printFullReport() {
        printModuleGraph()
        printDiscoveredGraphs()
        printRequirements()
        printInputRequirements()
        printProvisions()
        printProvidedInputs()
        printAnalysisResults()
        printSummary()
    }

    /// Prints only the module dependency graph
    func printModuleGraphOnly() {
        printModuleGraph()
    }

    /// Prints only the dependency injection graphs
    func printDependencyGraphOnly() {
        printDiscoveredGraphs()
    }

    // MARK: - Section Printers

    private func printModuleGraph() {
        printHeader("MODULE DEPENDENCY GRAPH")

        let modules = moduleGraph.allModuleNames.filter { !isTestModule($0) }.sorted()

        for moduleName in modules {
            let deps = moduleGraph.directDependencies(of: moduleName)
            if deps.isEmpty {
                print("\n  \(moduleName): (no dependencies)")
            } else {
                print("\n  \(moduleName):")
                for dep in deps.sorted() {
                    print("    -> \(dep)")
                }
            }
        }
        print("")
    }

    private func printDiscoveredGraphs() {
        printHeader("DISCOVERED DEPENDENCY GRAPHS")

        if graphs.isEmpty {
            print("\n  (No dependency graphs discovered)")
            print("  Tip: Create a graph root with DependencyBuilder<GraphRoot>()")
            return
        }

        for graph in graphs {
            print("\n  Graph: \(graph.origin.displayName)")
            print("    Origin: \(graph.origin.fileName):\(graph.origin.line)")
            print("    Root: \(graph.rootType)")
            print("    Nodes: \(graph.nodes.sorted().joined(separator: ", "))")

            if !graph.edges.isEmpty {
                print("    Edges:")
                for edge in graph.edges.sorted(by: { $0.fromType < $1.fromType }) {
                    print("      \(edge.fromType) -> \(edge.toType)")
                }
            }
        }

        if !orphanNodes.isEmpty {
            print("\n  Orphan Nodes (not in any graph):")
            for node in orphanNodes.sorted(by: { $0.typeName < $1.typeName }) {
                print("    ⚠️  \(node.typeName) in \(node.moduleName)")
            }
        }

        print("")
    }

    private func printRequirements() {
        printHeader("DEPENDENCY REQUIREMENTS")

        let modules = scanResults.requirementsByModule.keys
            .filter { !isTestModule($0) }
            .sorted()

        if modules.isEmpty {
            print("\n  (No dependency requirements declared)")
        } else {
            for module in modules {
                print("\n  \(module):")
                for dep in scanResults.requirementsByModule[module] ?? [] {
                    print("    - \(formatDependencyShort(dep))")
                }
            }
        }
        print("")
    }

    private func printInputRequirements() {
        printHeader("INPUT REQUIREMENTS")

        let modules = scanResults.inputRequirementsByModule
            .filter { !$0.value.isEmpty && !isTestModule($0.key) }
            .keys
            .sorted()

        if modules.isEmpty {
            print("\n  (No input requirements declared)")
        } else {
            for module in modules {
                print("\n  \(module):")
                for input in scanResults.inputRequirementsByModule[module] ?? [] {
                    print("    - \(input.type)")
                }
            }
        }
        print("")
    }

    private func printProvisions() {
        printHeader("PROVISIONS")

        let modules = scanResults.provisionsByModule.keys
            .filter { !isTestModule($0) }
            .sorted()

        if modules.isEmpty {
            print("\n  (No provisions found)")
        } else {
            for module in modules {
                print("\n  \(module):")
                let deps = scanResults.provisionsByModule[module] ?? []
                // Group by source file, preserving order within each group
                var fileOrder: [String] = []
                var depsByFile: [String: [Dependency]] = [:]
                for dep in deps {
                    let fileName = dep.location.map { URL(fileURLWithPath: $0.filePath).lastPathComponent } ?? "(unknown)"
                    if depsByFile[fileName] == nil {
                        fileOrder.append(fileName)
                    }
                    depsByFile[fileName, default: []].append(dep)
                }
                for fileName in fileOrder {
                    print("    \(fileName)")
                    for dep in depsByFile[fileName] ?? [] {
                        print("      - \(formatDependencyShort(dep))")
                    }
                }
            }
        }
        print("")
    }

    private func printProvidedInputs() {
        printHeader("PROVIDED INPUTS")

        let modules = scanResults.providedInputsByModule
            .filter { !$0.value.isEmpty && !isTestModule($0.key) }
            .keys
            .sorted()

        if modules.isEmpty {
            print("\n  (No provideInput calls found)")
        } else {
            for module in modules {
                print("\n  \(module):")
                let inputs = scanResults.providedInputsByModule[module] ?? []
                var fileOrder: [String] = []
                var inputsByFile: [String: [ProvidedInput]] = [:]
                for input in inputs {
                    let fileName = URL(fileURLWithPath: input.location.filePath).lastPathComponent
                    if inputsByFile[fileName] == nil {
                        fileOrder.append(fileName)
                    }
                    inputsByFile[fileName, default: []].append(input)
                }
                for fileName in fileOrder {
                    print("    \(fileName)")
                    for input in inputsByFile[fileName] ?? [] {
                        print("      - \(input.type)")
                    }
                }
            }
        }
        print("")
    }

    private func printAnalysisResults() {
        printHeader("ANALYSIS RESULTS")

        let errors = diagnostics.filter { $0.severity == .error }
        let warnings = diagnostics.filter { $0.severity == .warning }
        let infos = diagnostics.filter { $0.severity == .info }

        // Print errors first
        if errors.isEmpty {
            print("\n  ✅ All dependencies are satisfied.")
        } else {
            for diagnostic in errors {
                printDiagnostic(diagnostic)
            }
        }

        // Print warnings
        for diagnostic in warnings {
            printDiagnostic(diagnostic)
        }

        // Print info
        for diagnostic in infos {
            printDiagnostic(diagnostic)
        }

        print("")
    }

    private func printDiagnostic(_ diagnostic: Diagnostic) {
        let icon = switch diagnostic.severity {
        case .error: "❌"
        case .warning: "⚠️"
        case .info: "ℹ️"
        }

        print("\n  \(icon) \(diagnostic.message)")

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

    private func printSummary() {
        printHeader("SUMMARY")

        let errors = diagnostics.filter { $0.severity == .error }
        let warnings = diagnostics.filter { $0.severity == .warning }

        print("\n  Graphs discovered: \(graphs.count)")
        print("  Nodes discovered: \(scanResults.nodes.count)")
        print("  Orphan nodes: \(orphanNodes.count)")

        let totalIssues = errors.count + warnings.count
        if totalIssues == 0 {
            print("\n  ✅ All checks passed!")
        } else {
            print("\n  Found \(totalIssues) issue(s):")
            if !errors.isEmpty {
                let label = errors.count == 1 ? "error" : "errors"
                print("    - \(errors.count) \(label)")
            }
            if !warnings.isEmpty {
                let label = warnings.count == 1 ? "warning" : "warnings"
                print("    - \(warnings.count) \(label)")
            }
        }

        print("")
    }

    // MARK: - Test Adoption Report

    /// Prints a report showing TestDependencyProvider adoption status across all modules
    func printTestAdoptionReport() {
        printHeader("TEST ADOPTION REPORT")

        // Only consider modules that have DependencyRequirements nodes (i.e., participate in DI)
        let diModules = Set(scanResults.nodes.map { $0.moduleName })
            .filter { !isTestModule($0) }
            .sorted()

        if diModules.isEmpty {
            print("\n  (No modules with DependencyRequirements found)")
            print("")
            return
        }

        var adoptedCount = 0
        var mockRegCount = 0
        var notAdoptedModules: [(module: String, types: [String])] = []
        var conformedNoMock: [(module: String, types: [String])] = []
        var fullyAdopted: [(module: String, types: [String])] = []

        for moduleName in diModules {
            // Find DI node types in this module
            let nodeTypes = scanResults.nodes
                .filter { $0.moduleName == moduleName }
                .map { $0.typeName }

            let conformances = Set(scanResults.testDependencyProviderConformancesByModule[moduleName] ?? [])
            let implementations = Set(scanResults.mockRegistrationImplementationsByModule[moduleName] ?? [])

            let hasConformance = !conformances.isEmpty
            let hasImplementation = !implementations.isEmpty

            if hasConformance, hasImplementation {
                adoptedCount += 1
                mockRegCount += 1
                fullyAdopted.append((module: moduleName, types: nodeTypes))
            } else if hasConformance {
                adoptedCount += 1
                conformedNoMock.append((module: moduleName, types: nodeTypes))
            } else {
                notAdoptedModules.append((module: moduleName, types: nodeTypes))
            }
        }

        let total = diModules.count

        // Summary line
        print("\n  Adoption: \(adoptedCount)/\(total) modules conform to TestDependencyProvider")
        print("  Mock coverage: \(mockRegCount)/\(total) modules have mockRegistration implemented")

        // Fully adopted
        if !fullyAdopted.isEmpty {
            print("\n  ✅ Fully adopted (conformance + mockRegistration):")
            for entry in fullyAdopted {
                print("    \(entry.module): \(entry.types.joined(separator: ", "))")
            }
        }

        // Conformed but no mockRegistration
        if !conformedNoMock.isEmpty {
            print("\n  ⚠️  Conforms to TestDependencyProvider but mockRegistration not implemented:")
            for entry in conformedNoMock {
                print("    \(entry.module): \(entry.types.joined(separator: ", "))")
            }
        }

        // Not adopted
        if !notAdoptedModules.isEmpty {
            print("\n  ℹ️  Not yet adopted (DependencyRequirements only):")
            for entry in notAdoptedModules {
                print("    \(entry.module): \(entry.types.joined(separator: ", "))")
            }
        }

        print("")
    }

    // MARK: - Test Alignment Report

    /// Prints a report comparing importDependencies calls against buildChild calls in +Live files.
    func printTestAlignmentReport() {
        printHeader("TEST ALIGNMENT REPORT")

        // Only consider modules that have DI nodes
        let diNodes = scanResults.nodes
            .filter { !isTestModule($0.moduleName) }
            .sorted(by: { $0.moduleName < $1.moduleName })

        if diNodes.isEmpty {
            print("\n  (No modules with DependencyRequirements found)")
            print("")
            return
        }

        var misalignedCount = 0

        for node in diNodes {
            let typeName = node.typeName
            let moduleName = node.moduleName

            let productionChildren = findProductionChildren(typeName: typeName, moduleName: moduleName)
            let testImports = Set((scanResults.importDependenciesByModule[moduleName] ?? []).map { $0.importedType })

            let missing = productionChildren.subtracting(testImports)
            let extra = testImports.subtracting(productionChildren)
            let isAligned = missing.isEmpty && extra.isEmpty

            if isAligned {
                let childCount = productionChildren.count
                let importCount = testImports.count
                if childCount == 0, importCount == 0 {
                    print("    ✅ \(moduleName): aligned (leaf module, no children)")
                } else {
                    print("    ✅ \(moduleName): aligned (production builds \(childCount), testing imports \(importCount))")
                }
            } else {
                misalignedCount += 1
                let prodCount = productionChildren.count
                let testCount = testImports.count
                print("    ⚠️  \(moduleName): misaligned (production builds \(prodCount), testing imports \(testCount))")
                for type in missing.sorted() {
                    print("         └ testing should import \(type)")
                }
                for type in extra.sorted() {
                    print("         └ testing imports \(type) but production doesn't build it")
                }
            }
        }

        // Summary
        let total = diNodes.count
        if misalignedCount == 0 {
            print("\n  ✅ All \(total) modules aligned.")
        } else {
            print("\n  \(misalignedCount) of \(total) modules misaligned.")
        }

        print("")
    }

    /// Finds production buildChild targets from +Live.swift files for a given DI node
    private func findProductionChildren(typeName: String, moduleName: String) -> Set<String> {
        var children = Set<String>()

        // Check standalone edges (from discoveredEdges)
        for edge in scanResults.edges {
            guard edge.fromType == typeName || edge.fromType == moduleName else { continue }
            guard edge.location.filePath.contains("+Live") else { continue }
            children.insert(edge.toType)
        }

        // Check root initial edges (from discoveredRoots)
        for root in scanResults.roots {
            for edge in root.initialEdges {
                guard edge.fromType == typeName || edge.fromType == moduleName else { continue }
                guard edge.location.filePath.contains("+Live") else { continue }
                children.insert(edge.toType)
            }
        }

        return children
    }

    // MARK: - Test Redundancy Report

    /// Prints a report flagging explicit mock registrations that are already covered by importDependencies.
    func printTestRedundancyReport() {
        printHeader("TEST REDUNDANCY REPORT")

        // Only consider modules that have DI nodes
        let diNodes = scanResults.nodes
            .filter { !isTestModule($0.moduleName) }
            .sorted(by: { $0.moduleName < $1.moduleName })

        if diNodes.isEmpty {
            print("\n  (No modules with DependencyRequirements found)")
            print("")
            return
        }

        // Build a map from DI type name to its module name for lookups
        let typeToModule: [String: String] = Dictionary(
            scanResults.nodes.map { ($0.typeName, $0.moduleName) },
            uniquingKeysWith: { first, _ in first }
        )

        var totalRedundant = 0
        var modulesWithRedundancy = 0

        for node in diNodes {
            let moduleName = node.moduleName

            // Get this module's explicit mock registrations (non-local only)
            let explicitRegs = (scanResults.mockRegistrationsByModule[moduleName] ?? [])
                .filter { !$0.isLocal }

            guard !explicitRegs.isEmpty else {
                // No explicit registrations to check
                print("    ✅ \(moduleName): no explicit mock registrations")
                continue
            }

            // Get the types covered by this module's importDependencies calls (recursively)
            let imports = (scanResults.importDependenciesByModule[moduleName] ?? []).map { $0.importedType }

            guard !imports.isEmpty else {
                let regCount = explicitRegs.count
                print("    ✅ \(moduleName): \(regCount) explicit registration\(regCount == 1 ? "" : "s"), no imports")
                continue
            }

            // Recursively collect all (type, key) pairs covered by imports
            var coveredTypes = Set<DependencyKey>()
            var visited = Set<String>() // prevent cycles

            func collectCovered(importedType: String) {
                guard !visited.contains(importedType) else { return }
                visited.insert(importedType)

                // Find the module this type belongs to
                guard let importedModule = typeToModule[importedType] else { return }

                // Add the imported module's non-local, non-input requirements as covered
                let reqs = scanResults.requirementsByModule[importedModule] ?? []
                for req in reqs where !req.isLocal {
                    coveredTypes.insert(DependencyKey(type: req.type, key: req.key))
                }

                // Recurse into the imported module's own imports
                let childImports = (scanResults.importDependenciesByModule[importedModule] ?? []).map { $0.importedType }
                for childImport in childImports {
                    collectCovered(importedType: childImport)
                }
            }

            for importedType in imports {
                collectCovered(importedType: importedType)
            }

            // Find redundant registrations
            var redundant: [(reg: Dependency, coveredBy: String)] = []
            for reg in explicitRegs {
                let regKey = DependencyKey(type: reg.type, key: reg.key)
                if coveredTypes.contains(regKey) {
                    // Find which import covers it (for the report)
                    let source = findCoveringImport(
                        type: reg.type,
                        key: reg.key,
                        imports: imports,
                        typeToModule: typeToModule
                    )
                    redundant.append((reg: reg, coveredBy: source))
                }
            }

            if redundant.isEmpty {
                let regCount = explicitRegs.count
                let importCount = imports.count
                print("    ✅ \(moduleName): \(regCount) explicit, \(importCount) import\(importCount == 1 ? "" : "s"), no redundancy")
            } else {
                modulesWithRedundancy += 1
                totalRedundant += redundant.count
                let regCount = explicitRegs.count
                print("    ⚠️  \(moduleName): \(redundant.count) of \(regCount) explicit registration\(regCount == 1 ? "" : "s") redundant")
                for item in redundant.sorted(by: { $0.reg.type < $1.reg.type }) {
                    let keyStr = item.reg.key.map { " (key: \($0))" } ?? ""
                    print("         └ \(item.reg.type)\(keyStr) — covered by import of \(item.coveredBy)")
                }
            }
        }

        // Summary
        let total = diNodes.count
        if totalRedundant == 0 {
            print("\n  ✅ No redundant mock registrations found across \(total) modules.")
        } else {
            print("\n  \(totalRedundant) redundant registration\(totalRedundant == 1 ? "" : "s") across \(modulesWithRedundancy) module\(modulesWithRedundancy == 1 ? "" : "s").")
            print("  These can be safely removed — they are already covered by importDependencies.")
        }

        print("")
    }

    /// Finds the most direct import that covers a given (type, key) pair.
    private func findCoveringImport(
        type: String,
        key: String?,
        imports: [String],
        typeToModule: [String: String]
    ) -> String {
        // Check direct imports first
        for importedType in imports {
            guard let importedModule = typeToModule[importedType] else { continue }
            let reqs = scanResults.requirementsByModule[importedModule] ?? []
            let matches = reqs.contains { $0.type == type && $0.key == key && !$0.isLocal }
            if matches {
                return importedType
            }
        }

        // Check transitive imports
        for importedType in imports {
            guard let importedModule = typeToModule[importedType] else { continue }
            let childImports = (scanResults.importDependenciesByModule[importedModule] ?? []).map { $0.importedType }
            if !childImports.isEmpty {
                let result = findCoveringImport(type: type, key: key, imports: childImports, typeToModule: typeToModule)
                if result != "unknown" {
                    return "\(importedType) → \(result)"
                }
            }
        }

        return "unknown"
    }

    // MARK: - Helpers

    private func printHeader(_ title: String) {
        print("\n" + String(repeating: "=", count: 60))
        print(title)
        print(String(repeating: "=", count: 60))
    }

    /// Returns exit code based on diagnostics
    var exitCode: Int32 {
        diagnostics.contains { $0.severity == .error } ? 1 : 0
    }
}
