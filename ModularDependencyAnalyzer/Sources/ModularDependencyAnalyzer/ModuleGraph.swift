import Foundation
import SwiftParser
import SwiftSyntax

// MARK: - Module Graph

/// Builds and queries the module dependency graph
class ModuleGraph {
    private var modules: [String: ModuleInfo] = [:]
    private var dependents: [String: Set<String>] = [:] // moduleName -> modules that depend on it
    private var testTargets: Set<String> = []
    
    func addModule(_ info: ModuleInfo) {
        modules[info.name] = info
        if info.isTestTarget {
            testTargets.insert(info.name)
        }
    }
    
    /// Call after all modules are added to build the reverse lookup
    func buildDependentsGraph() {
        dependents = [:]
        for (moduleName, info) in modules {
            for dep in info.dependencies {
                dependents[dep, default: []].insert(moduleName)
            }
        }
    }
    
    func isTestTarget(_ moduleName: String) -> Bool {
        testTargets.contains(moduleName)
    }
    
    /// Returns all ancestor modules (modules that depend on this one, transitively)
    func ancestors(of moduleName: String) -> Set<String> {
        var result = Set<String>()
        var queue = [moduleName]
        var visited = Set<String>()
        
        while !queue.isEmpty {
            let current = queue.removeFirst()
            guard !visited.contains(current) else { continue }
            visited.insert(current)
            
            if let parents = dependents[current] {
                for parent in parents {
                    result.insert(parent)
                    queue.append(parent)
                }
            }
        }
        
        return result
    }
    
    func directDependencies(of moduleName: String) -> [String] {
        modules[moduleName]?.dependencies ?? []
    }
    
    func directDependents(of moduleName: String) -> [String] {
        Array(dependents[moduleName] ?? [])
    }
    
    func sourcePath(of moduleName: String) -> String? {
        modules[moduleName]?.sourcePath
    }
    
    var allModuleNames: [String] {
        Array(modules.keys)
    }
    
    /// Find which module a file belongs to based on path
    func moduleForFile(at path: String) -> String? {
        modules
            .filter { path.hasPrefix($0.value.sourcePath) }
            .max(by: { $0.value.sourcePath.count < $1.value.sourcePath.count })?
            .key
    }
}

// MARK: - Package Parsing

enum ProjectMode: String {
    case distributed // Multiple Package.swift files
    case monorepo // Single Package.swift with multiple targets
}

/// Parses Package.swift files in distributed mode (multiple packages)
func parseDistributedPackage(at url: URL) -> ModuleInfo? {
    guard let content = try? String(contentsOf: url, encoding: .utf8) else {
        return nil
    }
    
    let sourceFile = Parser.parse(source: content)
    let parser = DistributedPackageParser(viewMode: .sourceAccurate)
    parser.walk(sourceFile)
    
    guard let name = parser.packageName else { return nil }
    
    // Skip umbrella packages without matching target
    guard parser.targetDependencies.keys.contains(name) else {
        return nil
    }
    
    let packageDir = url.deletingLastPathComponent()
    let sourcePath = packageDir.appendingPathComponent("Sources/\(name)").path
    
    return ModuleInfo(
        name: name,
        sourcePath: sourcePath,
        dependencies: parser.mainTargetDependencies()
    )
}

/// Parses Package.swift in monorepo mode (single package, multiple targets)
func parseMonorepoPackage(at url: URL) -> [ModuleInfo] {
    guard let content = try? String(contentsOf: url, encoding: .utf8) else {
        return []
    }
    
    let sourceFile = Parser.parse(source: content)
    let packageDir = url.deletingLastPathComponent()
    let parser = MonorepoPackageParser(packageDir: packageDir)
    parser.walk(sourceFile)
    
    let allTargetNames = Set(parser.targets.map { $0.name })
    
    return parser.targets.map { target in
        let sourcePath: String = if let customPath = target.path {
            packageDir.appendingPathComponent(customPath).path
        } else {
            packageDir.appendingPathComponent("Sources/\(target.name)").path
        }
        
        let internalDeps = target.dependencies.filter { allTargetNames.contains($0) }
        
        return ModuleInfo(
            name: target.name,
            sourcePath: sourcePath,
            dependencies: internalDeps,
            isTestTarget: target.isTestTarget
        )
    }
}

// MARK: - Distributed Package Parser

private class DistributedPackageParser: SyntaxVisitor {
    var packageName: String?
    var targetDependencies: [String: [String]] = [:]
    
    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        let calledExpr = node.calledExpression.trimmedDescription
        
        if calledExpr == "Package" {
            for arg in node.arguments {
                if arg.label?.text == "name",
                   let stringLiteral = arg.expression.as(StringLiteralExprSyntax.self),
                   let segment = stringLiteral.segments.first?.as(StringSegmentSyntax.self) {
                    packageName = segment.content.text
                }
            }
            return .visitChildren
        }
        
        if calledExpr == ".target" {
            var targetName: String?
            var deps: [String] = []
            
            for arg in node.arguments {
                if arg.label?.text == "name",
                   let stringLiteral = arg.expression.as(StringLiteralExprSyntax.self),
                   let segment = stringLiteral.segments.first?.as(StringSegmentSyntax.self) {
                    targetName = segment.content.text
                }
                
                if arg.label?.text == "dependencies",
                   let array = arg.expression.as(ArrayExprSyntax.self) {
                    for element in array.elements {
                        if let call = element.expression.as(FunctionCallExprSyntax.self),
                           call.calledExpression.trimmedDescription == ".product" {
                            for productArg in call.arguments {
                                if productArg.label?.text == "package",
                                   let stringLiteral = productArg.expression.as(StringLiteralExprSyntax.self),
                                   let segment = stringLiteral.segments.first?.as(StringSegmentSyntax.self) {
                                    deps.append(segment.content.text)
                                }
                            }
                        }
                    }
                }
            }
            
            if let name = targetName {
                targetDependencies[name] = deps
            }
            return .skipChildren
        }
        
        return .visitChildren
    }
    
    func mainTargetDependencies() -> [String] {
        if let name = packageName, let deps = targetDependencies[name] {
            return deps
        }
        return targetDependencies.values.max(by: { $0.count < $1.count }) ?? []
    }
}

// MARK: - Monorepo Package Parser

private class MonorepoPackageParser: SyntaxVisitor {
    var packageName: String?
    var targets: [TargetInfo] = []
    private let packageDir: URL
    
    struct TargetInfo {
        let name: String
        let path: String?
        let dependencies: [String]
        let isTestTarget: Bool
    }
    
    init(packageDir: URL) {
        self.packageDir = packageDir
        super.init(viewMode: .sourceAccurate)
    }
    
    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        let calledExpr = node.calledExpression.trimmedDescription
        
        if calledExpr == "Package" {
            for arg in node.arguments {
                if arg.label?.text == "name",
                   let stringLiteral = arg.expression.as(StringLiteralExprSyntax.self),
                   let segment = stringLiteral.segments.first?.as(StringSegmentSyntax.self) {
                    packageName = segment.content.text
                }
            }
            return .visitChildren
        }
        
        if calledExpr == ".target" || calledExpr == ".executableTarget" || calledExpr == ".testTarget" {
            var targetName: String?
            var customPath: String?
            var deps: [String] = []
            let isTestTarget = calledExpr == ".testTarget"
            
            for arg in node.arguments {
                if arg.label?.text == "name",
                   let stringLiteral = arg.expression.as(StringLiteralExprSyntax.self),
                   let segment = stringLiteral.segments.first?.as(StringSegmentSyntax.self) {
                    targetName = segment.content.text
                }
                
                if arg.label?.text == "path",
                   let stringLiteral = arg.expression.as(StringLiteralExprSyntax.self),
                   let segment = stringLiteral.segments.first?.as(StringSegmentSyntax.self) {
                    customPath = segment.content.text
                }
                
                if arg.label?.text == "dependencies",
                   let array = arg.expression.as(ArrayExprSyntax.self) {
                    deps.append(contentsOf: parseDependencies(from: array))
                }
            }
            
            if let name = targetName {
                targets.append(TargetInfo(
                    name: name,
                    path: customPath,
                    dependencies: deps,
                    isTestTarget: isTestTarget
                ))
            }
            return .skipChildren
        }
        
        return .visitChildren
    }
    
    private func parseDependencies(from array: ArrayExprSyntax) -> [String] {
        var deps: [String] = []
        
        for element in array.elements {
            // String literal: "TargetName"
            if let stringLiteral = element.expression.as(StringLiteralExprSyntax.self),
               let segment = stringLiteral.segments.first?.as(StringSegmentSyntax.self) {
                deps.append(segment.content.text)
            }
            
            // .target(name: "...")
            if let call = element.expression.as(FunctionCallExprSyntax.self),
               call.calledExpression.trimmedDescription == ".target" {
                for targetArg in call.arguments {
                    if targetArg.label?.text == "name",
                       let stringLiteral = targetArg.expression.as(StringLiteralExprSyntax.self),
                       let segment = stringLiteral.segments.first?.as(StringSegmentSyntax.self) {
                        deps.append(segment.content.text)
                    }
                }
            }
            
            // .product(name: "...", package: "...")
            if let call = element.expression.as(FunctionCallExprSyntax.self),
               call.calledExpression.trimmedDescription == ".product" {
                for productArg in call.arguments {
                    if productArg.label?.text == "name",
                       let stringLiteral = productArg.expression.as(StringLiteralExprSyntax.self),
                       let segment = stringLiteral.segments.first?.as(StringSegmentSyntax.self) {
                        deps.append(segment.content.text)
                    }
                }
            }
            
            // .byName(name: "...")
            if let call = element.expression.as(FunctionCallExprSyntax.self),
               call.calledExpression.trimmedDescription == ".byName" {
                for byNameArg in call.arguments {
                    if byNameArg.label?.text == "name",
                       let stringLiteral = byNameArg.expression.as(StringLiteralExprSyntax.self),
                       let segment = stringLiteral.segments.first?.as(StringSegmentSyntax.self) {
                        deps.append(segment.content.text)
                    }
                }
            }
        }
        
        return deps
    }
}

// MARK: - File Utilities

func findSwiftFiles(at url: URL) -> [URL] {
    var files: [URL] = []
    let options: FileManager.DirectoryEnumerationOptions = [
        .skipsHiddenFiles,
        .skipsPackageDescendants
    ]
    
    guard let enumerator = FileManager.default.enumerator(
        at: url,
        includingPropertiesForKeys: [.isRegularFileKey],
        options: options
    ) else {
        return files
    }
    
    for case let fileURL as URL in enumerator {
        if fileURL.pathExtension == "swift",
           fileURL.lastPathComponent != "Package.swift",
           !isTestFile(fileURL) {
            files.append(fileURL)
        }
    }
    
    return files
}

func findPackageSwiftFiles(at url: URL) -> [URL] {
    var files: [URL] = []
    let options: FileManager.DirectoryEnumerationOptions = [
        .skipsHiddenFiles,
        .skipsPackageDescendants
    ]
    
    guard let enumerator = FileManager.default.enumerator(
        at: url,
        includingPropertiesForKeys: [.isRegularFileKey],
        options: options
    ) else {
        return files
    }
    
    for case let fileURL as URL in enumerator where fileURL.lastPathComponent == "Package.swift" {
        files.append(fileURL)
    }
    
    return files
}

func isTestFile(_ url: URL) -> Bool {
    let path = url.path
    let filename = url.lastPathComponent
    
    if filename.hasSuffix("Tests.swift") || filename.hasSuffix("Test.swift") {
        return true
    }
    
    if path.contains("/Tests/") {
        return true
    }
    
    for component in url.pathComponents where component.hasSuffix("Tests") {
        return true
    }
    
    return false
}

func isTestModule(_ moduleName: String) -> Bool {
    moduleName.hasSuffix("Tests") || moduleName.hasSuffix("Test")
}
