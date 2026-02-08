import Foundation

// MARK: - File Location

/// Represents a location in source code
struct FileLocation: Codable, Hashable {
    let filePath: String
    let line: Int
    
    var fileName: String {
        URL(fileURLWithPath: filePath).lastPathComponent
    }
}

// MARK: - Graph Origin

/// Identifies where a dependency graph is rooted
struct GraphOrigin: Codable, Hashable {
    let fileName: String
    let functionName: String
    let filePath: String
    let line: Int
    
    var displayName: String {
        "\(fileName).\(functionName)()"
    }
}

// MARK: - Discovered Elements (Scanner Output)

/// A type conforming to DependencyRequirements, discovered in a module
struct DiscoveredNode: Codable, Hashable {
    let typeName: String
    let moduleName: String
    let location: FileLocation
}

/// A DependencyBuilder<T>() instantiation that starts a new graph
struct DiscoveredRoot: Codable {
    let rootTypeName: String // e.g., "GraphRoot"
    let origin: GraphOrigin // file + function where instantiated
    let initialEdges: [DiscoveredEdge] // edges discovered via local variable tracking
}

/// A buildChild(T.self) call that creates an edge between nodes
struct DiscoveredEdge: Codable, Hashable {
    let fromType: String
    let toType: String
    let location: FileLocation
}

// MARK: - Dependency Information

/// Identifies the scope where a provision was registered
enum ProvisionScope: Codable, Hashable {
    /// Registered inside a DependencyRequirements type's registerDependencies function.
    /// These are scoped to the node and available when that node is on the path.
    case node(typeName: String)
    
    /// Registered inline on a DependencyBuilder/container variable in a graph root function.
    /// These are scoped to that specific graph and only available within it.
    case graphRoot(filePath: String, functionName: String)
    
    /// Legacy/unknown scope - treated as module-wide (fallback)
    case module
}

/// A dependency requirement or provision
struct Dependency: Codable, Hashable {
    let type: String
    let key: String?
    let isMainActor: Bool
    let isLocal: Bool
    let scope: ProvisionScope
    let location: FileLocation?

    init(type: String, key: String? = nil, isMainActor: Bool = false, isLocal: Bool = false, scope: ProvisionScope = .module, location: FileLocation? = nil) {
        self.type = type
        self.key = key
        self.isMainActor = isMainActor
        self.isLocal = isLocal
        self.scope = scope
        self.location = location
    }
    
    /// Matches requirements (ignores scope for comparison)
    func satisfies(_ requirement: Dependency) -> Bool {
        type == requirement.type
            && key == requirement.key
            && isMainActor == requirement.isMainActor
            && isLocal == requirement.isLocal
    }
}

/// An input dependency requirement
struct InputDependency: Codable, Hashable {
    let type: String
}

/// Tracks where a provideInput call was found
struct ProvidedInput: Codable, Hashable {
    let type: String
    let targetModule: String // The module this input is provided TO
    let location: FileLocation
    let scope: ProvisionScope
    
    init(type: String, targetModule: String, location: FileLocation, scope: ProvisionScope = .module) {
        self.type = type
        self.targetModule = targetModule
        self.location = location
        self.scope = scope
    }
}

// MARK: - Module Information

/// Represents a module (either a package or a target)
struct ModuleInfo: Codable {
    let name: String
    let sourcePath: String
    let dependencies: [String] // Names of modules this depends on
    let isTestTarget: Bool
    
    init(name: String, sourcePath: String, dependencies: [String], isTestTarget: Bool = false) {
        self.name = name
        self.sourcePath = sourcePath
        self.dependencies = dependencies
        self.isTestTarget = isTestTarget
    }
}

// MARK: - Scanner Output (per file)

/// All elements discovered from scanning a single Swift file
struct ScannedFileData: Codable {
    let mtime: TimeInterval
    let moduleName: String
    
    // Node discovery
    let discoveredNode: DiscoveredNode? // At most one per module
    
    // Root discovery
    let discoveredRoots: [DiscoveredRoot]
    
    // Edge discovery (for non-root contexts)
    let discoveredEdges: [DiscoveredEdge]
    
    // Dependency requirements
    let requirements: [Dependency]
    let inputRequirements: [InputDependency]
    
    // Provisions
    let provisions: [Dependency]
    let providedInputs: [ProvidedInput]
}

// MARK: - Graph Structures (Builder Output)

/// A complete dependency graph starting from a root
struct DependencyGraph {
    let origin: GraphOrigin
    let rootType: String
    let edges: [GraphEdge]
    let nodes: Set<String> // All node types reachable in this graph
    
    /// Returns all paths from root to a given node type
    func pathsTo(_ nodeType: String) -> [[String]] {
        guard nodes.contains(nodeType) else { return [] }
        
        var allPaths: [[String]] = []
        
        func dfs(current: String, path: [String]) {
            let newPath = path + [current]
            
            if current == nodeType {
                allPaths.append(newPath)
                return
            }
            
            let children = edges.filter { $0.fromType == current }.map { $0.toType }
            for child in children {
                guard !path.contains(child) else { continue } // Avoid cycles
                dfs(current: child, path: newPath)
            }
        }
        
        dfs(current: rootType, path: [])
        return allPaths
    }
}

/// An edge in a dependency graph
struct GraphEdge: Hashable {
    let fromType: String
    let toType: String
}

// MARK: - Analysis Results

/// A diagnostic message from analysis
struct Diagnostic {
    enum Severity {
        case error
        case warning
        case info
    }
    
    let severity: Severity
    let message: String
    let location: FileLocation?
    let graph: GraphOrigin?
    let context: [String] // Additional context lines
    
    init(
        severity: Severity,
        message: String,
        location: FileLocation? = nil,
        graph: GraphOrigin? = nil,
        context: [String] = []
    ) {
        self.severity = severity
        self.message = message
        self.location = location
        self.graph = graph
        self.context = context
    }
}
