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
