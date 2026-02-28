import Foundation

// MARK: - Analyzer

/// Analyzes dependency graphs for missing dependencies and inputs
class Analyzer {
    private let graphs: [DependencyGraph]
    private let scanResults: ScanResults
    private let moduleGraph: ModuleGraph
    private let nodesByType: [String: DiscoveredNode]
    private let nodesByModule: [String: DiscoveredNode]
    private let orphanNodes: [DiscoveredNode]
    private let showValid: Bool

    init(
        buildResult: GraphBuildResult,
        scanResults: ScanResults,
        moduleGraph: ModuleGraph,
        showValid: Bool = false
    ) {
        self.graphs = buildResult.graphs
        self.nodesByType = buildResult.nodesByType
        self.nodesByModule = buildResult.nodesByModule
        self.orphanNodes = buildResult.orphanNodes
        self.scanResults = scanResults
        self.moduleGraph = moduleGraph
        self.showValid = showValid
    }
    
    /// Resolves module name for a file path, with same fallback logic as Scanner.
    /// Uses moduleGraph first, then falls back to extracting from Sources/ path structure.
    /// This handles app source files that aren't part of the Package.swift module graph.
    private func resolveModuleName(for path: String) -> String? {
        if let moduleName = moduleGraph.moduleForFile(at: path) {
            return moduleName
        }
        // Fallback: extract from Sources/ directory structure
        let components = path.components(separatedBy: "/")
        if let sourcesIndex = components.lastIndex(of: "Sources"),
           sourcesIndex + 1 < components.count {
            return components[sourcesIndex + 1]
        }
        return nil
    }
    
    /// Gets the module name for a node in a path, with fallback to graph origin module
    private func moduleForPathNode(_ nodeType: String, graph: DependencyGraph) -> String? {
        // First try nodesByType lookup
        if let node = nodesByType[nodeType] {
            return node.moduleName
        }
        // Fallback: if this is the root node and not a discovered node,
        // try multiple strategies to find where provisions are registered
        if nodeType == graph.rootType {
            // Try the module where the graph was instantiated
            if let originModule = resolveModuleName(for: graph.origin.filePath) {
                return originModule
            }
            // If not found in module graph, the root type name itself might be used
            // as a module key for provisions (common pattern for main app targets)
            return nodeType
        }
        return nil
    }
    
    /// Gets all possible module names to check for provisions for a path node
    /// Returns array of module names to try (for root nodes that might have provisions in multiple places)
    private func modulesForProvisions(_ nodeType: String, graph: DependencyGraph) -> [String] {
        var modules: [String] = []
        
        // Primary: discovered node's module
        if let node = nodesByType[nodeType] {
            modules.append(node.moduleName)
        }
        
        // For root nodes, check additional locations
        if nodeType == graph.rootType {
            // Module where graph was instantiated (uses path-based fallback
            // for app source files not in the Package.swift module graph)
            if let originModule = resolveModuleName(for: graph.origin.filePath) {
                if !modules.contains(originModule) {
                    modules.append(originModule)
                }
            }
            // Root type name as module key
            if !modules.contains(nodeType) {
                modules.append(nodeType)
            }
        }
        
        return modules
    }
    
    /// Runs all analysis and returns diagnostics
    func analyze() -> [Diagnostic] {
        var diagnostics: [Diagnostic] = []
        
        // Check for orphan nodes
        diagnostics.append(contentsOf: analyzeOrphanNodes())
        
        // Analyze each graph
        for graph in graphs {
            diagnostics.append(contentsOf: analyzeGraph(graph))
        }
        
        return diagnostics.sorted {
            let dep0 = $0.message.components(separatedBy: ": ").last ?? $0.message
            let dep1 = $1.message.components(separatedBy: ": ").last ?? $1.message
            return dep0 < dep1
        }
    }

    // MARK: - Orphan Analysis
    
    private func analyzeOrphanNodes() -> [Diagnostic] {
        orphanNodes.map { node in
            Diagnostic(
                severity: .warning,
                message: "Orphan node: \(node.typeName) in module \(node.moduleName) is not reachable from any graph root",
                location: node.location,
                graph: nil,
                context: ["Consider adding a buildChild call to include this in a dependency graph"]
            )
        }
    }
    
    // MARK: - Graph Analysis
    
    private func analyzeGraph(_ graph: DependencyGraph) -> [Diagnostic] {
        var diagnostics: [Diagnostic] = []
        
        // For each node in the graph, check its requirements
        for nodeType in graph.nodes {
            diagnostics.append(contentsOf: analyzeDependencies(for: nodeType, in: graph))
            diagnostics.append(contentsOf: analyzeInputRequirements(for: nodeType, in: graph))
        }
        
        return diagnostics
    }
    
    // MARK: - Dependency Analysis
    
    private func analyzeDependencies(for nodeType: String, in graph: DependencyGraph) -> [Diagnostic] {
        var diagnostics: [Diagnostic] = []
        
        // Get the module for this node
        guard let node = nodesByType[nodeType] else { return [] }
        let moduleName = node.moduleName
        
        // Get requirements for this module
        guard let requirements = scanResults.requirementsByModule[moduleName], !requirements.isEmpty else {
            return []
        }
        
        // Find all paths from root to this node
        let paths = graph.pathsTo(nodeType)
        guard !paths.isEmpty else {
            // Node is in the graph but no path found - shouldn't happen
            return [Diagnostic(
                severity: .error,
                message: "Internal error: No path found to \(nodeType) in graph \(graph.origin.displayName)",
                location: node.location,
                graph: graph.origin
            )]
        }
        
        // Check each requirement
        for requirement in requirements {
            let result = checkRequirement(requirement, forNode: nodeType, inModule: moduleName, paths: paths, graph: graph)
            if let diagnostic = result {
                diagnostics.append(diagnostic)
            }
        }
        
        return diagnostics
    }
    
    private func checkRequirement(
        _ requirement: Dependency,
        forNode nodeType: String,
        inModule moduleName: String,
        paths: [[String]],
        graph: DependencyGraph
    ) -> Diagnostic? {
        // Local dependencies must be provided within the same module
        if requirement.isLocal {
            return checkLocalRequirement(requirement, inModule: moduleName, graph: graph)
        }
        
        // Inherited dependencies can come from any ancestor along any path
        return checkInheritedRequirement(requirement, forNode: nodeType, inModule: moduleName, paths: paths, graph: graph)
    }
    
    private func checkLocalRequirement(
        _ requirement: Dependency,
        inModule moduleName: String,
        graph: DependencyGraph
    ) -> Diagnostic? {
        let localProvisions = scanResults.provisionsByModule[moduleName]?.filter { $0.isLocal } ?? []
        
        if localProvisions.contains(where: { $0.satisfies(requirement) }) {
            return nil // Satisfied
        }
        
        // Build context for error message
        var context: [String] = []
        context.append("Local dependencies must be registered in the same module")
        
        // Check for similar registrations
        let sameType = localProvisions.filter { $0.type == requirement.type }
        if !sameType.isEmpty {
            if let mismatch = sameType.first(where: { $0.key != requirement.key }) {
                context.append("Found \(requirement.type) registered with different key: \(mismatch.key ?? "(no key)")")
            }
            if let mismatch = sameType.first(where: { $0.isMainActor != requirement.isMainActor }) {
                let registered = mismatch.isMainActor ? "@MainActor" : "non-isolated"
                let required = requirement.isMainActor ? "@MainActor" : "non-isolated"
                context.append("Found \(requirement.type) registered as \(registered), required as \(required)")
            }
        }
        
        return Diagnostic(
            severity: .error,
            message: "Missing local dependency in \(moduleName): \(formatDependency(requirement))",
            location: nodesByModule[moduleName]?.location,
            graph: graph.origin,
            context: context
        )
    }
    
    /// Checks if a provision is available in the context of a specific graph.
    /// Graph-root-scoped provisions are only available if they belong to this graph's origin.
    /// Node-scoped provisions are only available when their node is on the path.
    /// Module-scoped provisions are always available.
    private func isProvisionAvailable(_ provision: Dependency, forGraph graph: DependencyGraph, pathNodes: Set<String>) -> Bool {
        isScopeAvailable(provision.scope, forGraph: graph, pathNodes: pathNodes)
    }
    
    /// Checks if a provided input is available in the context of a specific graph.
    /// Uses the same scoping rules as provisions.
    private func isInputAvailable(_ input: ProvidedInput, forGraph graph: DependencyGraph, pathNodes: Set<String>) -> Bool {
        isScopeAvailable(input.scope, forGraph: graph, pathNodes: pathNodes)
    }
    
    /// Checks if a scope is available in the context of a specific graph.
    /// Graph-root scopes are only available if they belong to this graph's origin.
    /// Node scopes are only available when their node is on the path.
    /// Module scopes are always available.
    private func isScopeAvailable(_ scope: ProvisionScope, forGraph graph: DependencyGraph, pathNodes: Set<String>) -> Bool {
        switch scope {
        case .graphRoot(let filePath, let functionName):
            // Only available if this was registered in the same function that created this graph
            filePath == graph.origin.filePath && functionName == graph.origin.functionName
        case .node(let typeName):
            // Available if the node that provides this is on the current path
            pathNodes.contains(typeName)
        case .module:
            // Always available (legacy behavior)
            true
        }
    }
    
    private func checkInheritedRequirement(
        _ requirement: Dependency,
        forNode nodeType: String,
        inModule moduleName: String,
        paths: [[String]],
        graph: DependencyGraph
    ) -> Diagnostic? {
        var failingPaths: [[String]] = []
        
        for path in paths {
            let pathNodeSet = Set(path)
            // Collect non-local provisions available along this path
            var availableProvisions: [Dependency] = []
            
            // Add provisions from each node in the path
            for pathNode in path {
                // Check all possible modules for this node (handles root nodes specially)
                for nodeModule in modulesForProvisions(pathNode, graph: graph) {
                    let provisions = scanResults.provisionsByModule[nodeModule]?
                        .filter { !$0.isLocal && isProvisionAvailable($0, forGraph: graph, pathNodes: pathNodeSet) } ?? []
                    availableProvisions.append(contentsOf: provisions)
                }
            }
            
            // Also add provisions from the target module itself (non-local)
            let selfProvisions = scanResults.provisionsByModule[moduleName]?
                .filter { !$0.isLocal && isProvisionAvailable($0, forGraph: graph, pathNodes: pathNodeSet) } ?? []
            availableProvisions.append(contentsOf: selfProvisions)
            
            if !availableProvisions.contains(where: { $0.satisfies(requirement) }) {
                failingPaths.append(path)
            }
        }
        
        if failingPaths.isEmpty {
            return nil // All paths satisfy this requirement
        }
        
        // Build context
        var context: [String] = []
        
        // Collect all provisions for diagnostic hints
        var allProvisions: [Dependency] = []
        for path in paths {
            for pathNode in path {
                for nodeModule in modulesForProvisions(pathNode, graph: graph) {
                    allProvisions.append(contentsOf: scanResults.provisionsByModule[nodeModule] ?? [])
                }
            }
        }
        
        // Check for similar registrations
        let sameType = allProvisions.filter { $0.type == requirement.type }
        if !sameType.isEmpty {
            // Key mismatch
            let differentKey = sameType.filter { $0.key != requirement.key }
            if !differentKey.isEmpty {
                let keys = Set(differentKey.map { $0.key ?? "(no key)" }).sorted()
                context.append("Found \(requirement.type) registered with different key(s): \(keys.joined(separator: ", "))")
            }
            
            // Isolation mismatch
            if let mismatch = sameType.first(where: { $0.isMainActor != requirement.isMainActor && $0.key == requirement.key }) {
                let registered = mismatch.isMainActor ? "@MainActor" : "non-isolated"
                let required = requirement.isMainActor ? "@MainActor" : "non-isolated"
                context.append("Found \(requirement.type) registered as \(registered), required as \(required)")
            }
            
            // Locality mismatch
            if let mismatch = sameType.first(where: { $0.isLocal && $0.key == requirement.key }) {
                context.append("Found \(requirement.type) registered as local, but inherited is required")
            }
        }
        
        // Add path summary and failing paths info
        if failingPaths.count < paths.count {
            context.append("(\(paths.count - failingPaths.count) of \(paths.count) paths satisfy this requirement)")
        }
        let pathLabel = failingPaths.count > 1 ? "Failing paths" : "Failing path"
        context.append("\(pathLabel):")
        for path in failingPaths.prefix(5) { // Limit to first 5 paths
            context.append("  \(path.joined(separator: " -> "))")
        }
        if failingPaths.count > 5 {
            context.append("  ... and \(failingPaths.count - 5) more")
        }

        if showValid {
            let failingSet = Set(failingPaths.map { $0.joined(separator: " -> ") })
            let validPaths = paths.filter { !failingSet.contains($0.joined(separator: " -> ")) }
            context.append("")
            context.append("Valid paths:")
            if validPaths.isEmpty {
                context.append("  No existing paths found")
            } else {
                for path in validPaths.prefix(5) {
                    context.append("  \(path.joined(separator: " -> "))")
                }
                if validPaths.count > 5 {
                    context.append("  ... and \(validPaths.count - 5) more")
                }
            }
        }

        return Diagnostic(
            severity: .error,
            message: "Missing dependency in \(moduleName): \(formatDependency(requirement))",
            location: nodesByModule[moduleName]?.location,
            graph: graph.origin,
            context: context
        )
    }
    
    // MARK: - Input Requirement Analysis
    
    private func analyzeInputRequirements(for nodeType: String, in graph: DependencyGraph) -> [Diagnostic] {
        var diagnostics: [Diagnostic] = []
        
        guard let node = nodesByType[nodeType] else { return [] }
        let moduleName = node.moduleName
        
        guard let inputRequirements = scanResults.inputRequirementsByModule[moduleName], !inputRequirements.isEmpty else {
            return []
        }
        
        let paths = graph.pathsTo(nodeType)
        guard !paths.isEmpty else { return [] }
        
        for inputReq in inputRequirements {
            let result = checkInputRequirement(inputReq, forNode: nodeType, inModule: moduleName, paths: paths, graph: graph)
            if let diagnostic = result {
                diagnostics.append(diagnostic)
            }
        }
        
        return diagnostics
    }
    
    private func checkInputRequirement(
        _ inputReq: InputDependency,
        forNode nodeType: String,
        inModule moduleName: String,
        paths: [[String]],
        graph: DependencyGraph
    ) -> Diagnostic? {
        var failingPaths: [[String]] = []
        
        for path in paths {
            let pathNodeSet = Set(path)
            // Collect provided inputs along this path
            var availableInputTypes = Set<String>()
            
            for pathNode in path {
                for nodeModule in modulesForProvisions(pathNode, graph: graph) {
                    let inputs = scanResults.providedInputsByModule[nodeModule] ?? []
                    for input in inputs where isInputAvailable(input, forGraph: graph, pathNodes: pathNodeSet) {
                        availableInputTypes.insert(input.type)
                    }
                }
                // Also check by type name directly (buildChild closures store
                // inputs keyed by the target type name, not the module name)
                let typeNameInputs = scanResults.providedInputsByModule[pathNode] ?? []
                for input in typeNameInputs where isInputAvailable(input, forGraph: graph, pathNodes: pathNodeSet) {
                    availableInputTypes.insert(input.type)
                }
            }
            
            // Also check inputs provided TO this module (by module name and type name)
            let directInputs = scanResults.providedInputsByModule[moduleName] ?? []
            for input in directInputs where isInputAvailable(input, forGraph: graph, pathNodes: pathNodeSet) {
                availableInputTypes.insert(input.type)
            }
            let directInputsByType = scanResults.providedInputsByModule[nodeType] ?? []
            for input in directInputsByType where isInputAvailable(input, forGraph: graph, pathNodes: pathNodeSet) {
                availableInputTypes.insert(input.type)
            }
            
            if !availableInputTypes.contains(inputReq.type) {
                failingPaths.append(path)
            }
        }
        
        if failingPaths.isEmpty {
            return nil
        }
        
        var context: [String] = []
        context.append("No provideInput(\(inputReq.type).self, ...) found on failing path(s)")
        
        if failingPaths.count < paths.count {
            context.append("(\(paths.count - failingPaths.count) of \(paths.count) paths satisfy this requirement)")
        }
        let pathLabel = failingPaths.count > 1 ? "Failing paths" : "Failing path"
        context.append("\(pathLabel):")
        for path in failingPaths.prefix(5) {
            context.append("  \(path.joined(separator: " -> "))")
        }
        if failingPaths.count > 5 {
            context.append("  ... and \(failingPaths.count - 5) more")
        }

        if showValid {
            let failingSet = Set(failingPaths.map { $0.joined(separator: " -> ") })
            let validPaths = paths.filter { !failingSet.contains($0.joined(separator: " -> ")) }
            context.append("")
            context.append("Valid paths:")
            if validPaths.isEmpty {
                context.append("  No existing paths found")
            } else {
                for path in validPaths.prefix(5) {
                    context.append("  \(path.joined(separator: " -> "))")
                }
                if validPaths.count > 5 {
                    context.append("  ... and \(validPaths.count - 5) more")
                }
            }
        }

        return Diagnostic(
            severity: .error,
            message: "Missing input for \(moduleName): \(inputReq.type)",
            location: nodesByModule[moduleName]?.location,
            graph: graph.origin,
            context: context
        )
    }

    // MARK: - Find Dependency

    func findDependency(_ typeName: String) -> [Diagnostic] {
        var diagnostics: [Diagnostic] = []

        for graph in graphs {
            for nodeType in graph.nodes {
                guard let node = nodesByType[nodeType] else { continue }
                let moduleName = node.moduleName

                guard let requirements = scanResults.requirementsByModule[moduleName] else { continue }
                let matching = requirements.filter { $0.type == typeName }
                guard !matching.isEmpty else { continue }

                let paths = graph.pathsTo(nodeType)
                guard !paths.isEmpty else { continue }

                for requirement in matching {
                    var failingPaths: [[String]] = []
                    var validPaths: [[String]] = []

                    if requirement.isLocal {
                        // Local requirements: either all pass or all fail (no path-based checking)
                        let localProvisions = scanResults.provisionsByModule[moduleName]?.filter { $0.isLocal } ?? []
                        if localProvisions.contains(where: { $0.satisfies(requirement) }) {
                            validPaths = paths
                        } else {
                            failingPaths = paths
                        }
                    } else {
                        // Inherited requirements: check each path
                        for path in paths {
                            let pathNodeSet = Set(path)
                            var availableProvisions: [Dependency] = []

                            for pathNode in path {
                                for nodeModule in modulesForProvisions(pathNode, graph: graph) {
                                    let provisions = scanResults.provisionsByModule[nodeModule]?
                                        .filter { !$0.isLocal && isProvisionAvailable($0, forGraph: graph, pathNodes: pathNodeSet) } ?? []
                                    availableProvisions.append(contentsOf: provisions)
                                }
                            }

                            let selfProvisions = scanResults.provisionsByModule[moduleName]?
                                .filter { !$0.isLocal && isProvisionAvailable($0, forGraph: graph, pathNodes: pathNodeSet) } ?? []
                            availableProvisions.append(contentsOf: selfProvisions)

                            if availableProvisions.contains(where: { $0.satisfies(requirement) }) {
                                validPaths.append(path)
                            } else {
                                failingPaths.append(path)
                            }
                        }
                    }

                    let status = failingPaths.isEmpty ? "✅" : "❌"
                    var context: [String] = []

                    if !failingPaths.isEmpty {
                        let pathLabel = failingPaths.count > 1 ? "Failing paths" : "Failing path"
                        context.append("\(pathLabel):")
                        for path in failingPaths.prefix(5) {
                            context.append("  \(path.joined(separator: " -> "))")
                        }
                        if failingPaths.count > 5 {
                            context.append("  ... and \(failingPaths.count - 5) more")
                        }
                    }

                    if !validPaths.isEmpty {
                        if !failingPaths.isEmpty {
                            context.append("")
                        }
                        let pathLabel = validPaths.count > 1 ? "Valid paths" : "Valid path"
                        context.append("\(pathLabel):")
                        for path in validPaths.prefix(5) {
                            context.append("  \(path.joined(separator: " -> "))")
                        }
                        if validPaths.count > 5 {
                            context.append("  ... and \(validPaths.count - 5) more")
                        }
                    } else if failingPaths.isEmpty {
                        // Shouldn't happen, but handle gracefully
                        context.append("No paths found")
                    } else {
                        context.append("")
                        context.append("Valid paths:")
                        context.append("  No existing paths found")
                    }

                    diagnostics.append(Diagnostic(
                        severity: .info,
                        message: "\(status) \(formatDependency(requirement)) required by \(moduleName)",
                        location: node.location,
                        graph: graph.origin,
                        context: context
                    ))
                }
            }
        }

        return diagnostics.sorted {
            let dep0 = $0.message.components(separatedBy: ": ").last ?? $0.message
            let dep1 = $1.message.components(separatedBy: ": ").last ?? $1.message
            return dep0 < dep1
        }
    }
}

// MARK: - Formatting Helpers

func formatDependency(_ dep: Dependency) -> String {
    var result = dep.type
    if let key = dep.key {
        result += " (key: \(key))"
    } else {
        result += " (no key)"
    }
    if dep.isLocal {
        result += " [local]"
    }
    if dep.isMainActor {
        result += " [@MainActor]"
    }
    return result
}

func formatDependencyShort(_ dep: Dependency) -> String {
    var result = dep.type
    if let key = dep.key {
        result += " (key: \(key))"
    }
    if dep.isLocal {
        result += " [local]"
    }
    if dep.isMainActor {
        result += " [@MainActor]"
    }
    return result
}
