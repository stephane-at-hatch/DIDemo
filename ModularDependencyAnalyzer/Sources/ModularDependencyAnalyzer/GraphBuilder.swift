import Foundation

// MARK: - Helpers

/// Checks if a type name looks like a generic type parameter (T, U, V, Element, etc.)
private func isGenericTypeParameter(_ typeName: String) -> Bool {
    // Single uppercase letter is definitely a generic
    if typeName.count == 1, typeName.first?.isUppercase == true {
        return true
    }
    // Common generic parameter names
    let commonGenerics: Set<String> = ["T", "U", "V", "W", "Element", "Key", "Value", "Result"]
    return commonGenerics.contains(typeName)
}

// MARK: - Graph Builder

/// Assembles discovered elements into dependency graphs
class GraphBuilder {
    private let scanResults: ScanResults
    private let moduleGraph: ModuleGraph
    
    init(scanResults: ScanResults, moduleGraph: ModuleGraph) {
        self.scanResults = scanResults
        self.moduleGraph = moduleGraph
    }
    
    /// Builds all dependency graphs from scan results
    func build() -> GraphBuildResult {
        var graphs: [DependencyGraph] = []
        var orphanNodes: [DiscoveredNode] = []
        
        // Create a lookup from type name to discovered node
        let nodesByType = Dictionary(
            scanResults.nodes.map { ($0.typeName, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        
        // Also create a lookup from module name to its DependencyRequirements type
        let nodesByModule = Dictionary(
            scanResults.nodes.map { ($0.moduleName, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        
        // Build each graph from discovered roots
        // Filter out roots that are generic type parameters (single letter like T, U, V)
        let validRoots = scanResults.roots.filter { root in
            !isGenericTypeParameter(root.rootTypeName)
        }
        
        for root in validRoots {
            let graph = buildGraph(
                from: root,
                nodesByType: nodesByType,
                nodesByModule: nodesByModule
            )
            graphs.append(graph)
        }
        
        // Find orphan nodes (nodes not reachable from any graph)
        let allReachableNodes = Set(graphs.flatMap { $0.nodes })
        for node in scanResults.nodes {
            if !allReachableNodes.contains(node.typeName) {
                orphanNodes.append(node)
            }
        }
        
        return GraphBuildResult(
            graphs: graphs,
            orphanNodes: orphanNodes,
            nodesByType: nodesByType,
            nodesByModule: nodesByModule
        )
    }
    
    private func buildGraph(
        from root: DiscoveredRoot,
        nodesByType: [String: DiscoveredNode],
        nodesByModule: [String: DiscoveredNode]
    ) -> DependencyGraph {
        var edges = Set<GraphEdge>()
        var visitedNodes = Set<String>()
        var nodesToProcess = [root.rootTypeName]
        
        // Add initial edges from root discovery (skip self-edges)
        for edge in root.initialEdges where edge.fromType != edge.toType {
            edges.insert(GraphEdge(fromType: edge.fromType, toType: edge.toType))
            if !nodesToProcess.contains(edge.toType) {
                nodesToProcess.append(edge.toType)
            }
        }
        
        // Process nodes to find their outgoing edges
        while !nodesToProcess.isEmpty {
            let currentNode = nodesToProcess.removeFirst()
            guard !visitedNodes.contains(currentNode) else { continue }
            visitedNodes.insert(currentNode)
            
            // Find edges originating from this node
            // These come from discoveredEdges in the scan results
            let outgoingEdges = findOutgoingEdges(
                from: currentNode,
                nodesByType: nodesByType,
                nodesByModule: nodesByModule
            )
            
            for edge in outgoingEdges {
                edges.insert(edge)
                if !visitedNodes.contains(edge.toType) {
                    nodesToProcess.append(edge.toType)
                }
            }
        }
        
        return DependencyGraph(
            origin: root.origin,
            rootType: root.rootTypeName,
            edges: Array(edges),
            nodes: visitedNodes
        )
    }
    
    /// Finds all outgoing edges from a node type
    private func findOutgoingEdges(
        from nodeType: String,
        nodesByType: [String: DiscoveredNode],
        nodesByModule: [String: DiscoveredNode]
    ) -> [GraphEdge] {
        var edges: [GraphEdge] = []
        
        // Direct edges: fromType matches exactly (skip self-edges)
        for edge in scanResults.edges where edge.fromType == nodeType && edge.toType != nodeType {
            edges.append(GraphEdge(fromType: nodeType, toType: edge.toType))
        }
        
        // Module-attributed edges: fromType is a module name, and this node is in that module
        if let node = nodesByType[nodeType] {
            for edge in scanResults.edges where edge.fromType == node.moduleName && edge.toType != nodeType {
                edges.append(GraphEdge(fromType: nodeType, toType: edge.toType))
            }
        }
        
        return edges
    }
}

/// Results from building all graphs
struct GraphBuildResult {
    let graphs: [DependencyGraph]
    let orphanNodes: [DiscoveredNode]
    let nodesByType: [String: DiscoveredNode]
    let nodesByModule: [String: DiscoveredNode]
}
