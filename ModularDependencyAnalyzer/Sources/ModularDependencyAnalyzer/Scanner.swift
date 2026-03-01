import Foundation
import SwiftParser
import SwiftSyntax

// MARK: - Scanner

/// Scans Swift source files to discover dependency graph elements
class Scanner {
    private let moduleGraph: ModuleGraph
    private let cache: FileCache

    init(moduleGraph: ModuleGraph, cache: FileCache) {
        self.moduleGraph = moduleGraph
        self.cache = cache
    }

    /// Modules to exclude from scanning (framework/infrastructure code)
    private static let excludedModules: Set<String> = [
        "HatchModularDependencyContainer",
        "ModularDependencyContainer"
    ]

    /// Checks if a module should be excluded from scanning
    private func shouldExcludeModule(_ moduleName: String) -> Bool {
        Self.excludedModules.contains(moduleName) ||
            moduleName.contains("DependencyContainer") ||
            moduleName.contains("DependencyBuilder")
    }

    /// Resolves the module name for a file path
    /// Falls back to "GraphRoot" for files not in the module graph (e.g., main app target)
    private func resolveModuleName(for path: String) -> String {
        // First try the module graph
        if let moduleName = moduleGraph.moduleForFile(at: path) {
            return moduleName
        }

        // Fallback: check if this is in a Sources directory
        let components = path.components(separatedBy: "/")
        if let sourcesIndex = components.lastIndex(of: "Sources"),
           sourcesIndex + 1 < components.count {
            return components[sourcesIndex + 1]
        }

        // Final fallback: files outside known modules are treated as GraphRoot
        // This handles main app targets that aren't part of the module graph
        return "GraphRoot"
    }

    /// Scans a single file and returns discovered elements
    func scan(file: URL) -> ScannedFileData? {
        // Check cache first
        if let cached = cache.getCached(file: file) {
            return cached
        }

        // In cache-only mode, we can't parse new files
        if cache.isCacheOnly {
            return nil
        }

        // Parse the file
        guard let content = try? String(contentsOf: file, encoding: .utf8) else {
            return nil
        }

        guard let attrs = try? FileManager.default.attributesOfItem(atPath: file.path),
              let mtime = (attrs[.modificationDate] as? Date)?.timeIntervalSince1970 else {
            return nil
        }

        let moduleName = resolveModuleName(for: file.path)

        // Skip excluded modules (framework/infrastructure code)
        if shouldExcludeModule(moduleName) {
            return nil
        }

        let sourceFile = Parser.parse(source: content)

        // Run the visitor
        let visitor = ScannerVisitor(
            filePath: file.path,
            moduleName: moduleName,
            source: content
        )
        visitor.walk(sourceFile)

        let data = ScannedFileData(
            mtime: mtime,
            moduleName: moduleName,
            discoveredNode: visitor.discoveredNode,
            discoveredRoots: visitor.discoveredRoots,
            discoveredEdges: visitor.discoveredEdges,
            requirements: visitor.requirements,
            inputRequirements: visitor.inputRequirements,
            provisions: visitor.provisions,
            providedInputs: visitor.providedInputs,
            testAdoption: TestAdoptionData(
                testDependencyProviderConformances: visitor.testDependencyProviderConformances,
                mockRegistrationImplementations: visitor.mockRegistrationImplementations
            ),
            importDependenciesCalls: visitor.importDependenciesCalls,
            mockRegistrations: visitor.mockRegistrations,
            mockProvidedInputTypes: visitor.mockProvidedInputTypes
        )

        cache.update(file: file, data: data)
        return data
    }

    /// Scans all Swift files and returns aggregated results
    func scanAll(files: [URL]) -> ScanResults {
        var allNodes: [DiscoveredNode] = []
        var allRoots: [DiscoveredRoot] = []
        var allEdges: [DiscoveredEdge] = []
        var requirementsByModule: [String: [Dependency]] = [:]
        var inputRequirementsByModule: [String: [InputDependency]] = [:]
        var provisionsByModule: [String: [Dependency]] = [:]
        var providedInputsByModule: [String: [ProvidedInput]] = [:]
        var tdpConformancesByModule: [String: [String]] = [:]
        var mockRegImplementationsByModule: [String: [String]] = [:]
        var importDepsByModule: [String: [ImportDependenciesCall]] = [:]
        var mockRegsByModule: [String: [Dependency]] = [:]
        var mockProvidedInputTypesByModule: [String: [String]] = [:]

        for file in files {
            guard let data = scan(file: file) else { continue }

            if let node = data.discoveredNode {
                allNodes.append(node)
            }

            allRoots.append(contentsOf: data.discoveredRoots)
            allEdges.append(contentsOf: data.discoveredEdges)

            if !data.requirements.isEmpty {
                requirementsByModule[data.moduleName, default: []].append(contentsOf: data.requirements)
            }

            if !data.inputRequirements.isEmpty {
                inputRequirementsByModule[data.moduleName, default: []].append(contentsOf: data.inputRequirements)
            }

            if !data.provisions.isEmpty {
                provisionsByModule[data.moduleName, default: []].append(contentsOf: data.provisions)
            }

            // Group provided inputs by their target module
            for input in data.providedInputs {
                providedInputsByModule[input.targetModule, default: []].append(input)
            }

            // Aggregate test adoption data
            if !data.testAdoption.testDependencyProviderConformances.isEmpty {
                tdpConformancesByModule[data.moduleName, default: []]
                    .append(contentsOf: data.testAdoption.testDependencyProviderConformances)
            }
            if !data.testAdoption.mockRegistrationImplementations.isEmpty {
                mockRegImplementationsByModule[data.moduleName, default: []]
                    .append(contentsOf: data.testAdoption.mockRegistrationImplementations)
            }

            // Aggregate importDependencies calls
            if !data.importDependenciesCalls.isEmpty {
                importDepsByModule[data.moduleName, default: []]
                    .append(contentsOf: data.importDependenciesCalls)
            }

            // Aggregate mock registrations
            if !data.mockRegistrations.isEmpty {
                mockRegsByModule[data.moduleName, default: []]
                    .append(contentsOf: data.mockRegistrations)
            }

            // Aggregate mock provided input types
            if !data.mockProvidedInputTypes.isEmpty {
                mockProvidedInputTypesByModule[data.moduleName, default: []]
                    .append(contentsOf: data.mockProvidedInputTypes)
            }
        }

        return ScanResults(
            nodes: allNodes,
            roots: allRoots,
            edges: allEdges,
            requirementsByModule: requirementsByModule,
            inputRequirementsByModule: inputRequirementsByModule,
            provisionsByModule: provisionsByModule,
            providedInputsByModule: providedInputsByModule,
            testDependencyProviderConformancesByModule: tdpConformancesByModule,
            mockRegistrationImplementationsByModule: mockRegImplementationsByModule,
            importDependenciesByModule: importDepsByModule,
            mockRegistrationsByModule: mockRegsByModule,
            mockProvidedInputTypesByModule: mockProvidedInputTypesByModule
        )
    }
}

/// Aggregated results from scanning all files
struct ScanResults {
    let nodes: [DiscoveredNode]
    let roots: [DiscoveredRoot]
    let edges: [DiscoveredEdge]
    let requirementsByModule: [String: [Dependency]]
    let inputRequirementsByModule: [String: [InputDependency]]
    let provisionsByModule: [String: [Dependency]]
    let providedInputsByModule: [String: [ProvidedInput]]

    /// Test adoption: type names that conform to TestDependencyProvider, grouped by module
    let testDependencyProviderConformancesByModule: [String: [String]]
    /// Test adoption: type names that have a mockRegistration implementation, grouped by module
    let mockRegistrationImplementationsByModule: [String: [String]]

    /// Test alignment: importDependencies(X.self) calls, grouped by module
    let importDependenciesByModule: [String: [ImportDependenciesCall]]

    /// Mock registrations: register* calls inside mockRegistration bodies, grouped by module
    let mockRegistrationsByModule: [String: [Dependency]]

    /// Mock provided input types: provideInput calls inside mockRegistration bodies, grouped by module
    let mockProvidedInputTypesByModule: [String: [String]]
}

// MARK: - Scanner Visitor

/// SwiftSyntax visitor that discovers dependency graph elements
private class ScannerVisitor: SyntaxVisitor {
    let filePath: String
    let moduleName: String
    private let sourceLocationConverter: SourceLocationConverter

    // Discovered elements
    var discoveredNode: DiscoveredNode?
    var discoveredRoots: [DiscoveredRoot] = []
    var discoveredEdges: [DiscoveredEdge] = []
    var requirements: [Dependency] = []
    var inputRequirements: [InputDependency] = []
    var provisions: [Dependency] = []
    var providedInputs: [ProvidedInput] = []

    // Test adoption tracking
    var testDependencyProviderConformances: [String] = []
    var mockRegistrationImplementations: [String] = []

    // Test alignment tracking
    var importDependenciesCalls: [ImportDependenciesCall] = []

    // Mock registration tracking (register* and provideInput calls inside mockRegistration)
    var mockRegistrations: [Dependency] = []
    var mockProvidedInputTypes: [String] = []

    // State tracking
    private var isInsideDependencyRequirementsType = false
    private var currentDependencyRequirementsTypeName: String?
    private var currentFunctionName: String?

    // Enclosing type context for resolving nested types (e.g., extension AppCoordinator { struct Dependencies })
    private var enclosingTypeNames: [String] = []

    // For local variable tracking within a function
    private var variableTypes: [String: String] = [:]  // variableName -> typeName
    private var pendingRootEdges: [DiscoveredEdge] = []
    private var currentRootOrigin: GraphOrigin?
    private var currentRootType: String?

    init(filePath: String, moduleName: String, source: String) {
        self.filePath = filePath
        self.moduleName = moduleName
        let sourceFile = Parser.parse(source: source)
        self.sourceLocationConverter = SourceLocationConverter(fileName: filePath, tree: sourceFile)
        super.init(viewMode: .sourceAccurate)
    }

    private func location(for node: some SyntaxProtocol) -> FileLocation {
        let loc = sourceLocationConverter.location(for: node.positionAfterSkippingLeadingTrivia)
        return FileLocation(filePath: filePath, line: loc.line)
    }

    // MARK: - Freestanding Macro Filtering

    /// Skip #Preview and other freestanding macros that shouldn't participate in dependency analysis.
    /// #Preview blocks often contain `RootDependencyBuilder.buildChild()` calls for setting up
    /// previews, but these are not real app dependency graphs.
    override func visit(_ node: MacroExpansionDeclSyntax) -> SyntaxVisitorContinueKind {
        if node.macroName.text == "Preview" {
            return .skipChildren
        }
        return .visitChildren
    }

    override func visit(_ node: MacroExpansionExprSyntax) -> SyntaxVisitorContinueKind {
        if node.macroName.text == "Preview" {
            return .skipChildren
        }
        return .visitChildren
    }

    // MARK: - Enclosing Type Context Tracking

    /// Resolves the fully-qualified type name by prepending enclosing type names.
    /// e.g., if we're inside `extension AppCoordinator` and see `struct Dependencies`,
    /// this returns `"AppCoordinator.Dependencies"` instead of just `"Dependencies"`.
    private func qualifiedTypeName(_ simpleName: String) -> String {
        if enclosingTypeNames.isEmpty {
            return simpleName
        }
        return (enclosingTypeNames + [simpleName]).joined(separator: ".")
    }

    override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
        enclosingTypeNames.append(node.extendedType.trimmedDescription)

        // Check for TestDependencyProvider conformance added via extension
        if let inheritanceClause = node.inheritanceClause {
            let conformsToTDP = inheritanceClause.inheritedTypes.contains { inherited in
                inherited.type.trimmedDescription == "TestDependencyProvider"
            }
            if conformsToTDP {
                let typeName = node.extendedType.trimmedDescription
                if !testDependencyProviderConformances.contains(typeName) {
                    testDependencyProviderConformances.append(typeName)
                }
            }
        }

        return .visitChildren
    }

    override func visitPost(_ node: ExtensionDeclSyntax) {
        enclosingTypeNames.removeLast()
    }

    // MARK: - Node Discovery (DependencyRequirements conformance)

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        // Check for @DependencyRequirements macro
        for attributeElement in node.attributes {
            if let attribute = attributeElement.as(AttributeSyntax.self),
               attribute.attributeName.as(IdentifierTypeSyntax.self)?.name.text == "DependencyRequirements" {
                let typeName = qualifiedTypeName(node.name.text)
                discoveredNode = DiscoveredNode(
                    typeName: typeName,
                    moduleName: moduleName,
                    location: location(for: node)
                )
                isInsideDependencyRequirementsType = true
                currentDependencyRequirementsTypeName = typeName

                // Parse requirements from macro
                requirements.append(contentsOf: parseRequirementsFromAttribute(attribute))
                inputRequirements.append(contentsOf: parseInputRequirementsFromAttribute(attribute))
            }
        }

        // Check for protocol conformance
        if conformsToDependencyRequirements(node) {
            let typeName = qualifiedTypeName(node.name.text)
            discoveredNode = DiscoveredNode(
                typeName: typeName,
                moduleName: moduleName,
                location: location(for: node)
            )
            isInsideDependencyRequirementsType = true
            currentDependencyRequirementsTypeName = typeName
        }

        // Check for TestDependencyProvider conformance (direct on struct)
        if conformsToTestDependencyProvider(node) {
            let typeName = qualifiedTypeName(node.name.text)
            if !testDependencyProviderConformances.contains(typeName) {
                testDependencyProviderConformances.append(typeName)
            }
        }

        // Track nesting for non-extension struct declarations too
        // (e.g., struct Outer { struct Dependencies: DependencyRequirements {} })
        enclosingTypeNames.append(node.name.text)

        return .visitChildren
    }

    override func visitPost(_ node: StructDeclSyntax) {
        // Pop the struct nesting context
        enclosingTypeNames.removeLast()

        if conformsToDependencyRequirements(node) || hasDependencyRequirementsMacro(node) {
            isInsideDependencyRequirementsType = false
            currentDependencyRequirementsTypeName = nil
        }
    }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        // Check for @DependencyRequirements macro on classes too
        for attributeElement in node.attributes {
            if let attribute = attributeElement.as(AttributeSyntax.self),
               attribute.attributeName.as(IdentifierTypeSyntax.self)?.name.text == "DependencyRequirements" {
                let typeName = qualifiedTypeName(node.name.text)
                discoveredNode = DiscoveredNode(
                    typeName: typeName,
                    moduleName: moduleName,
                    location: location(for: node)
                )
                isInsideDependencyRequirementsType = true
                currentDependencyRequirementsTypeName = typeName

                requirements.append(contentsOf: parseRequirementsFromAttribute(attribute))
                inputRequirements.append(contentsOf: parseInputRequirementsFromAttribute(attribute))
            }
        }

        // Track nesting for class declarations too
        enclosingTypeNames.append(node.name.text)

        return .visitChildren
    }

    override func visitPost(_ node: ClassDeclSyntax) {
        // Pop the class nesting context
        enclosingTypeNames.removeLast()

        if hasDependencyRequirementsMacro(node) {
            isInsideDependencyRequirementsType = false
            currentDependencyRequirementsTypeName = nil
        }
    }

    // MARK: - Function/Initializer Tracking

    /// Common setup when entering a function-like scope (function or init)
    private func enterFunctionScope(name: String) {
        currentFunctionName = name
        variableTypes = [:]
        pendingRootEdges = []
        currentRootOrigin = nil
        currentRootType = nil
    }

    /// Common teardown when leaving a function-like scope
    private func exitFunctionScope() {
        // If we found a root in this scope, finalize it
        if let origin = currentRootOrigin, let rootType = currentRootType {
            discoveredRoots.append(DiscoveredRoot(
                rootTypeName: rootType,
                origin: origin,
                initialEdges: pendingRootEdges
            ))
        }

        currentFunctionName = nil
        variableTypes = [:]
        pendingRootEdges = []
        currentRootOrigin = nil
        currentRootType = nil
    }

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        enterFunctionScope(name: node.name.text)

        // Check for mockRegistration function with a non-empty body
        if node.name.text == "mockRegistration" {
            let hasBody = node.body.map { !$0.statements.isEmpty } ?? false
            if hasBody {
                // Determine which type this belongs to
                let owningType = currentDependencyRequirementsTypeName
                    ?? enclosingTypeNames.last
                if let typeName = owningType, !mockRegistrationImplementations.contains(typeName) {
                    mockRegistrationImplementations.append(typeName)
                }

                // Scan register* calls inside mockRegistration body
                let mockScope: ProvisionScope = if let typeName = currentDependencyRequirementsTypeName {
                    .node(typeName: typeName)
                } else {
                    .module
                }
                let mockRegVisitor = RegistrationVisitor(scope: mockScope, filePath: filePath, sourceLocationConverter: sourceLocationConverter)
                mockRegVisitor.walk(node)
                mockRegistrations.append(contentsOf: mockRegVisitor.registrations)
                mockProvidedInputTypes.append(contentsOf: mockRegVisitor.providedInputTypes)
            }
        }

        // Check for registerDependencies function
        if node.name.text == "registerDependencies" {
            let nodeScope: ProvisionScope = if let typeName = currentDependencyRequirementsTypeName {
                .node(typeName: typeName)
            } else {
                .module
            }
            let registrationVisitor = RegistrationVisitor(scope: nodeScope, filePath: filePath, sourceLocationConverter: sourceLocationConverter)
            registrationVisitor.walk(node)
            provisions.append(contentsOf: registrationVisitor.registrations)
        }

        return .visitChildren
    }

    override func visitPost(_ node: FunctionDeclSyntax) {
        exitFunctionScope()
    }

    override func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
        enterFunctionScope(name: "init")
        return .visitChildren
    }

    override func visitPost(_ node: InitializerDeclSyntax) {
        exitFunctionScope()
    }

    // MARK: - Variable Declarations (for local tracking)

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        // Handle property declarations inside DependencyRequirements types
        if isInsideDependencyRequirementsType {
            for binding in node.bindings {
                guard let identifier = binding.pattern.as(IdentifierPatternSyntax.self) else { continue }
                let propertyName = identifier.identifier.text

                if propertyName == "requirements",
                   let initializer = binding.initializer,
                   let array = initializer.value.as(ArrayExprSyntax.self) {
                    requirements.append(contentsOf: parseRequirementsFromArray(array))
                }

                if propertyName == "inputRequirements",
                   let initializer = binding.initializer,
                   let array = initializer.value.as(ArrayExprSyntax.self) {
                    inputRequirements.append(contentsOf: parseInputRequirementsFromArray(array))
                }
            }
        }

        return .visitChildren
    }

    // MARK: - Function Call Analysis

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        let calledExpr = node.calledExpression.trimmedDescription

        // MARK: Root Discovery - DependencyBuilder<T>()

        if let genericExpr = node.calledExpression.as(GenericSpecializationExprSyntax.self),
           genericExpr.expression.trimmedDescription == "DependencyBuilder",
           let genericArg = genericExpr.genericArgumentClause.arguments.first {
            let rootType = genericArg.argument.trimmedDescription
            let fileName = URL(fileURLWithPath: filePath).deletingPathExtension().lastPathComponent
            let funcName = currentFunctionName ?? "unknown"

            currentRootOrigin = GraphOrigin(
                fileName: fileName,
                functionName: funcName,
                filePath: filePath,
                line: location(for: node).line
            )
            currentRootType = rootType

            // Track the variable if this is assigned
            if let parent = findParentVariableBinding(for: node) {
                variableTypes[parent] = rootType
            }
        }

        // MARK: .freeze() call tracking

        if let memberAccess = node.calledExpression.as(MemberAccessExprSyntax.self),
           memberAccess.declName.baseName.text == "freeze" {
            // The result of freeze() has the same type as the builder
            if let baseVar = memberAccess.base?.trimmedDescription,
               let baseType = variableTypes[baseVar] {
                if let parent = findParentVariableBinding(for: node) {
                    variableTypes[parent] = baseType
                }
            }
        }

        // MARK: register* call tracking on tracked builder/container variables

        // Handles all 5 access patterns:
        //   1. builder.register*(...)              → base = "builder"
        //   2. builder.mainActor.register*(...)    → base = "builder.mainActor"
        //   3. builder.local.register*(...)        → base = "builder.local"
        //   4. builder.mainActor.local.register*() → base = "builder.mainActor.local"
        //   5. builder.provideInput(...)           → handled separately below
        if let memberAccess = node.calledExpression.as(MemberAccessExprSyntax.self),
           memberAccess.declName.baseName.text.hasPrefix("register") {
            if let baseExpr = memberAccess.base?.trimmedDescription {
                // Strip .mainActor / .local accessors to find the root variable name
                let rootVar = stripAccessorSuffixes(baseExpr)
                if variableTypes[rootVar] != nil {
                    // This is a registration call on a tracked DependencyBuilder/Container
                    if let typeArg = node.arguments.first?.expression.as(MemberAccessExprSyntax.self),
                       typeArg.declName.baseName.text == "self",
                       let type = typeArg.base?.trimmedDescription {
                        let keyArg = node.arguments.first(where: { $0.label?.text == "key" })
                        let key = keyArg?.expression.trimmedDescription
                        let fullExpr = memberAccess.trimmedDescription
                        let isLocal = fullExpr.contains(".local.")
                        let isMainActor = fullExpr.contains(".mainActor.")
                        // Scope to the current graph root function so provisions don't leak across graphs
                        let scope: ProvisionScope = if let funcName = currentFunctionName {
                            .graphRoot(filePath: filePath, functionName: funcName)
                        } else {
                            .module
                        }
                        provisions.append(Dependency(type: type, key: key, isMainActor: isMainActor, isLocal: isLocal, scope: scope, location: location(for: node)))
                    }
                }
            }
        }

        // MARK: Root Discovery - RootDependencyBuilder.buildChild(T.self)

        // This is the shorthand form for starting a dependency graph.
        // Instead of creating a DependencyBuilder<GraphRoot>() and then calling
        // .buildChild(), this jumps straight into the first child type as the root.
        // Since RootDependencyBuilder.buildChild is a single call that both creates
        // the root and returns the first node, we emit the root immediately and
        // set up variable tracking so subsequent .buildChild() calls chain from it.
        if let memberAccess = node.calledExpression.as(MemberAccessExprSyntax.self),
           memberAccess.declName.baseName.text == "buildChild",
           memberAccess.base?.trimmedDescription == "RootDependencyBuilder" {
            if let rootType = extractBuildChildTargetType(from: node) {
                let fileName = URL(fileURLWithPath: filePath).deletingPathExtension().lastPathComponent
                let funcName = currentFunctionName ?? "unknown"

                let origin = GraphOrigin(
                    fileName: fileName,
                    functionName: funcName,
                    filePath: filePath,
                    line: location(for: node).line
                )

                // If we're already tracking a root in this function, finalize it first
                if let existingOrigin = currentRootOrigin, let existingType = currentRootType {
                    discoveredRoots.append(DiscoveredRoot(
                        rootTypeName: existingType,
                        origin: existingOrigin,
                        initialEdges: pendingRootEdges
                    ))
                    pendingRootEdges = []
                }

                currentRootOrigin = origin
                currentRootType = rootType

                // Track the variable so subsequent .buildChild() calls chain correctly
                if let parent = findParentVariableBinding(for: node) {
                    variableTypes[parent] = rootType
                }

                // If we're not inside a function/init body (e.g. property initializer),
                // emit the root immediately since there's no visitPost to finalize it.
                if currentFunctionName == nil {
                    discoveredRoots.append(DiscoveredRoot(
                        rootTypeName: rootType,
                        origin: origin,
                        initialEdges: []
                    ))
                    // Reset so we don't double-emit if visitPost fires later
                    currentRootOrigin = nil
                    currentRootType = nil
                }
            }
        }

        // MARK: .buildChild(T.self) call tracking

        if let memberAccess = node.calledExpression.as(MemberAccessExprSyntax.self),
           memberAccess.declName.baseName.text == "buildChild",
           memberAccess.base?.trimmedDescription != "RootDependencyBuilder" {
            if let childType = extractBuildChildTargetType(from: node) {
                // Determine the "from" type
                var fromType: String?

                // Try to get from local variable tracking
                if let baseVar = memberAccess.base?.trimmedDescription,
                   let baseType = variableTypes[baseVar] {
                    fromType = baseType
                }

                // If we're in a root discovery context, all edges go to pendingRootEdges
                if currentRootOrigin != nil {
                    // Use tracked type, or fall back to current root type
                    let from = fromType ?? currentRootType ?? "Unknown"
                    let edge = DiscoveredEdge(
                        fromType: from,
                        toType: childType,
                        location: location(for: node)
                    )
                    pendingRootEdges.append(edge)

                    // Track the result variable
                    if let parent = findParentVariableBinding(for: node) {
                        variableTypes[parent] = childType
                    }
                } else if let from = fromType {
                    // Outside root context with local tracking
                    let edge = DiscoveredEdge(
                        fromType: from,
                        toType: childType,
                        location: location(for: node)
                    )
                    discoveredEdges.append(edge)

                    // Track the result variable
                    if let parent = findParentVariableBinding(for: node) {
                        variableTypes[parent] = childType
                    }
                } else if isInsideDependencyRequirementsType, let nodeType = discoveredNode?.typeName {
                    // We're inside a DependencyRequirements type, attribute to it
                    let edge = DiscoveredEdge(
                        fromType: nodeType,
                        toType: childType,
                        location: location(for: node)
                    )
                    discoveredEdges.append(edge)
                } else {
                    // Fallback: attribute to module's DependencyRequirements
                    // This will be resolved later by the graph builder
                    let edge = DiscoveredEdge(
                        fromType: moduleName, // Placeholder - will be resolved
                        toType: childType,
                        location: location(for: node)
                    )
                    discoveredEdges.append(edge)
                }

                // Handle buildChild closure for provideInput tracking.
                // The ProvideInputClosureVisitor handles provideInput calls inside the closure
                // with the correct targetModule (the child type). We increment buildChildClosureDepth
                // so the general provideInput handler skips these calls (they'd be incorrectly
                // attributed to the current module otherwise).
                handleBuildChildClosure(node: node, targetModule: childType)
                return .skipChildren
            }
        }

        // MARK: importDependencies(X.self) call tracking

        if let memberAccess = node.calledExpression.as(MemberAccessExprSyntax.self),
           memberAccess.declName.baseName.text == "importDependencies" {
            if let firstArg = node.arguments.first,
               let memberExpr = firstArg.expression.as(MemberAccessExprSyntax.self),
               memberExpr.declName.baseName.text == "self",
               let base = memberExpr.base {
                importDependenciesCalls.append(ImportDependenciesCall(
                    importedType: base.trimmedDescription,
                    location: location(for: node)
                ))
            }
        }

        // MARK: provideInput(T.self, ...) call tracking

        if let memberAccess = node.calledExpression.as(MemberAccessExprSyntax.self),
           memberAccess.declName.baseName.text == "provideInput" {
            if let inputType = extractProvideInputType(from: node) {
                // Scope to graph root function if we're inside one, so inputs
                // don't leak across graphs built in the same module
                let scope: ProvisionScope = if let funcName = currentFunctionName, currentRootOrigin != nil {
                    .graphRoot(filePath: filePath, functionName: funcName)
                } else {
                    .module
                }
                // Determine target module - this depends on context
                // For now, use the module name; buildChild closure handling refines this
                providedInputs.append(ProvidedInput(
                    type: inputType,
                    targetModule: moduleName,
                    location: location(for: node),
                    scope: scope
                ))
            }
        }

        return .visitChildren
    }

    // MARK: - Access Pattern Helpers

    /// The dependency container supports 5 access patterns for registration:
    ///   1. `builder.register*(...)` — standard dependency
    ///   2. `builder.mainActor.register*(...)` — main actor dependency
    ///   3. `builder.local.register*(...)` — local dependency
    ///   4. `builder.mainActor.local.register*(...)` — main actor + local dependency
    ///   5. `builder.provideInput(...)` — input dependency
    ///
    /// When tracking registrations on builder variables, the base expression may include
    /// `.mainActor` and/or `.local` accessors that need to be stripped to find the root
    /// variable name in `variableTypes`.
    private static let accessorSuffixes = [
        ".mainActor.local",
        ".local.mainActor",
        ".mainActor",
        ".local"
    ]

    /// Strips `.mainActor` and `.local` accessor suffixes from a base expression
    /// to recover the root variable name for `variableTypes` lookup.
    ///
    /// Examples:
    ///   - `"dependencyBuilder"` → `"dependencyBuilder"`
    ///   - `"dependencyBuilder.mainActor"` → `"dependencyBuilder"`
    ///   - `"dependencyBuilder.local"` → `"dependencyBuilder"`
    ///   - `"dependencyBuilder.mainActor.local"` → `"dependencyBuilder"`
    private func stripAccessorSuffixes(_ expr: String) -> String {
        for suffix in Self.accessorSuffixes {
            if expr.hasSuffix(suffix) {
                return String(expr.dropLast(suffix.count))
            }
        }
        return expr
    }

    // MARK: - Helper Methods

    private func conformsToDependencyRequirements(_ node: StructDeclSyntax) -> Bool {
        guard let inheritanceClause = node.inheritanceClause else { return false }
        return inheritanceClause.inheritedTypes.contains { inherited in
            let typeName = inherited.type.trimmedDescription
            return typeName == "DependencyRequirements" || typeName == "TestDependencyProvider"
        }
    }

    private func conformsToTestDependencyProvider(_ node: StructDeclSyntax) -> Bool {
        guard let inheritanceClause = node.inheritanceClause else { return false }
        return inheritanceClause.inheritedTypes.contains { inherited in
            inherited.type.trimmedDescription == "TestDependencyProvider"
        }
    }

    private func hasDependencyRequirementsMacro(_ node: StructDeclSyntax) -> Bool {
        for attributeElement in node.attributes {
            if let attribute = attributeElement.as(AttributeSyntax.self),
               attribute.attributeName.as(IdentifierTypeSyntax.self)?.name.text == "DependencyRequirements" {
                return true
            }
        }
        return false
    }

    private func hasDependencyRequirementsMacro(_ node: ClassDeclSyntax) -> Bool {
        for attributeElement in node.attributes {
            if let attribute = attributeElement.as(AttributeSyntax.self),
               attribute.attributeName.as(IdentifierTypeSyntax.self)?.name.text == "DependencyRequirements" {
                return true
            }
        }
        return false
    }

    /// Finds the variable name if this expression is part of a variable declaration
    private func findParentVariableBinding(for node: some SyntaxProtocol) -> String? {
        var current: Syntax? = Syntax(node)
        while let parent = current?.parent {
            if let binding = parent.as(PatternBindingSyntax.self),
               let identifier = binding.pattern.as(IdentifierPatternSyntax.self) {
                return identifier.identifier.text
            }
            current = parent
        }
        return nil
    }

    /// Extracts the target type from buildChild(T.self) or buildChild(Module.Dependencies.self)
    /// Returns the full type name as it appears in the source (e.g., "AdultScreenDependencies")
    private func extractBuildChildTargetType(from node: FunctionCallExprSyntax) -> String? {
        guard let firstArg = node.arguments.first else { return nil }

        guard let memberAccess = firstArg.expression.as(MemberAccessExprSyntax.self),
              memberAccess.declName.baseName.text == "self" else {
            return nil
        }

        // Return the full type name without modification
        // This matches the typeName of DiscoveredNode which is also the full struct name
        return memberAccess.base?.trimmedDescription
    }

    /// Extracts the type from provideInput(T.self, ...)
    private func extractProvideInputType(from node: FunctionCallExprSyntax) -> String? {
        guard let firstArg = node.arguments.first else { return nil }

        guard let memberAccess = firstArg.expression.as(MemberAccessExprSyntax.self),
              memberAccess.declName.baseName.text == "self",
              let base = memberAccess.base else {
            return nil
        }

        return base.trimmedDescription
    }

    /// Handles buildChild closures to track provideInput calls with correct target module
    private func handleBuildChildClosure(node: FunctionCallExprSyntax, targetModule: String) {
        // Scope to graph root function if we're inside one, so inputs
        // don't leak across graphs built in the same module
        let scope: ProvisionScope = if let funcName = currentFunctionName, currentRootOrigin != nil {
            .graphRoot(filePath: filePath, functionName: funcName)
        } else {
            .module
        }

        // Look for trailing closure or closure argument
        let closures: [ClosureExprSyntax] = node.arguments.compactMap { arg in
            arg.expression.as(ClosureExprSyntax.self)
        } + [node.trailingClosure].compactMap { $0 }

        for closure in closures {
            let closureVisitor = ProvideInputClosureVisitor(
                filePath: filePath,
                targetModule: targetModule,
                sourceLocationConverter: sourceLocationConverter,
                scope: scope
            )
            closureVisitor.walk(closure)
            providedInputs.append(contentsOf: closureVisitor.providedInputs)
        }
    }

    // MARK: - Requirement Parsing

    private func parseRequirementsFromAttribute(_ attribute: AttributeSyntax) -> [Dependency] {
        guard let arguments = attribute.arguments?.as(LabeledExprListSyntax.self) else {
            return []
        }

        var results: [Dependency] = []

        // Parse first unlabeled argument (regular requirements)
        if let firstArg = arguments.first,
           firstArg.label == nil,
           let array = firstArg.expression.as(ArrayExprSyntax.self) {
            results.append(contentsOf: parseRequirementsFromArray(array, isMainActor: false, isLocal: false))
        }

        // Parse mainActor: labeled argument
        if let mainActorArg = arguments.first(where: { $0.label?.text == "mainActor" }),
           let array = mainActorArg.expression.as(ArrayExprSyntax.self) {
            results.append(contentsOf: parseRequirementsFromArray(array, isMainActor: true, isLocal: false))
        }

        // Parse local: labeled argument
        if let localArg = arguments.first(where: { $0.label?.text == "local" }),
           let array = localArg.expression.as(ArrayExprSyntax.self) {
            results.append(contentsOf: parseRequirementsFromArray(array, isMainActor: false, isLocal: true))
        }

        // Parse localMainActor: labeled argument
        if let localMainActorArg = arguments.first(where: { $0.label?.text == "localMainActor" }),
           let array = localMainActorArg.expression.as(ArrayExprSyntax.self) {
            results.append(contentsOf: parseRequirementsFromArray(array, isMainActor: true, isLocal: true))
        }

        return results
    }

    private func parseInputRequirementsFromAttribute(_ attribute: AttributeSyntax) -> [InputDependency] {
        guard let arguments = attribute.arguments?.as(LabeledExprListSyntax.self) else {
            return []
        }

        guard let inputsArg = arguments.first(where: { $0.label?.text == "inputs" }),
              let array = inputsArg.expression.as(ArrayExprSyntax.self) else {
            return []
        }

        return parseInputRequirementsFromArray(array)
    }

    private func parseRequirementsFromArray(
        _ array: ArrayExprSyntax,
        isMainActor: Bool = false,
        isLocal: Bool = false
    ) -> [Dependency] {
        array.elements.compactMap { element -> Dependency? in
            guard let call = element.expression.as(FunctionCallExprSyntax.self),
                  call.calledExpression.trimmedDescription == "Requirement" else {
                return nil
            }
            guard let typeArg = call.arguments.first,
                  let member = typeArg.expression.as(MemberAccessExprSyntax.self),
                  member.declName.baseName.text == "self",
                  let base = member.base else {
                return nil
            }
            let type = base.trimmedDescription
            let keyArg = call.arguments.dropFirst().first { $0.label?.text == "key" }
            let key = keyArg?.expression.trimmedDescription
            return Dependency(type: type, key: key, isMainActor: isMainActor, isLocal: isLocal)
        }
    }

    private func parseInputRequirementsFromArray(_ array: ArrayExprSyntax) -> [InputDependency] {
        array.elements.compactMap { element -> InputDependency? in
            guard let call = element.expression.as(FunctionCallExprSyntax.self),
                  call.calledExpression.trimmedDescription == "InputRequirement" else {
                return nil
            }
            guard let typeArg = call.arguments.first,
                  let member = typeArg.expression.as(MemberAccessExprSyntax.self),
                  member.declName.baseName.text == "self",
                  let base = member.base else {
                return nil
            }
            return InputDependency(type: base.trimmedDescription)
        }
    }
}

// MARK: - Registration Visitor

/// Visits function bodies to find register* calls
private class RegistrationVisitor: SyntaxVisitor {
    var registrations: [Dependency] = []
    var providedInputTypes: [String] = []
    private let scope: ProvisionScope
    private let filePath: String
    private let sourceLocationConverter: SourceLocationConverter

    init(scope: ProvisionScope, filePath: String, sourceLocationConverter: SourceLocationConverter) {
        self.scope = scope
        self.filePath = filePath
        self.sourceLocationConverter = sourceLocationConverter
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard let calledExpression = node.calledExpression.as(MemberAccessExprSyntax.self) else {
            return .visitChildren
        }

        let functionName = calledExpression.declName.baseName.text

        // Track provideInput calls
        if functionName == "provideInput" {
            if let typeArg = node.arguments.first?.expression.as(MemberAccessExprSyntax.self),
               typeArg.declName.baseName.text == "self",
               let type = typeArg.base?.trimmedDescription {
                providedInputTypes.append(type)
            }
            return .skipChildren
        }

        guard functionName.starts(with: "register") else {
            return .visitChildren
        }

        guard let typeArg = node.arguments.first?.expression.as(MemberAccessExprSyntax.self),
              typeArg.declName.baseName.text == "self",
              let type = typeArg.base?.trimmedDescription else {
            return .visitChildren
        }

        let keyArg = node.arguments.first { $0.label?.text == "key" }
        let key = keyArg?.expression.trimmedDescription

        // Analyze call chain for isolation and locality
        let fullExpr = calledExpression.trimmedDescription
        let isLocal = fullExpr.contains(".local.")
        let isMainActor = fullExpr.contains(".mainActor.")

        let loc = sourceLocationConverter.location(for: node.positionAfterSkippingLeadingTrivia)
        let fileLocation = FileLocation(filePath: filePath, line: loc.line)
        registrations.append(Dependency(type: type, key: key, isMainActor: isMainActor, isLocal: isLocal, scope: scope, location: fileLocation))
        return .skipChildren
    }
}

// MARK: - ProvideInput Closure Visitor

/// Visits closures inside buildChild to track provideInput calls with correct target
private class ProvideInputClosureVisitor: SyntaxVisitor {
    var providedInputs: [ProvidedInput] = []
    private let filePath: String
    private let targetModule: String
    private let sourceLocationConverter: SourceLocationConverter
    private let scope: ProvisionScope

    init(filePath: String, targetModule: String, sourceLocationConverter: SourceLocationConverter, scope: ProvisionScope) {
        self.filePath = filePath
        self.targetModule = targetModule
        self.sourceLocationConverter = sourceLocationConverter
        self.scope = scope
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard let memberAccess = node.calledExpression.as(MemberAccessExprSyntax.self),
              memberAccess.declName.baseName.text == "provideInput" else {
            return .visitChildren
        }

        guard let firstArg = node.arguments.first,
              let typeMember = firstArg.expression.as(MemberAccessExprSyntax.self),
              typeMember.declName.baseName.text == "self",
              let base = typeMember.base else {
            return .visitChildren
        }

        let loc = sourceLocationConverter.location(for: node.positionAfterSkippingLeadingTrivia)
        providedInputs.append(ProvidedInput(
            type: base.trimmedDescription,
            targetModule: targetModule,
            location: FileLocation(filePath: filePath, line: loc.line),
            scope: scope
        ))

        return .skipChildren
    }
}
