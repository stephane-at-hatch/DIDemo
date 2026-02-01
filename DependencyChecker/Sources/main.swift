// swiftlint:disable file_length
import CryptoKit
import Foundation
import SwiftParser
import SwiftSyntax

// MARK: - Cache

enum CacheMode {
    case normal // Use cache if available, update as needed
    case cacheOnly // Only use cache, fail if file not cached
    case noCache // Ignore cache entirely, always parse
}

/// Cached data for a single Swift file
struct CachedFileData: Codable {
    let mtime: TimeInterval
    let requirements: [CachedDependency]
    let inputRequirements: [CachedInputDependency]
    let provisions: [CachedDependency]
    let providedInputs: [CachedProvidedInput]
    let hasDependencyContainer: Bool
}

struct CachedDependency: Codable, Hashable {
    let type: String
    let key: String?
    let isMainActor: Bool
    let isLocal: Bool

    init(_ dep: Dependency) {
        self.type = dep.type
        self.key = dep.key
        self.isMainActor = dep.isMainActor
        self.isLocal = dep.isLocal
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.type = try container.decode(String.self, forKey: .type)
        self.key = try container.decodeIfPresent(String.self, forKey: .key)
        // Default to false for backwards compatibility with old cache files
        self.isMainActor = try container.decodeIfPresent(Bool.self, forKey: .isMainActor) ?? false
        self.isLocal = try container.decodeIfPresent(Bool.self, forKey: .isLocal) ?? false
    }

    func toDependency() -> Dependency {
        Dependency(type: type, key: key, isMainActor: isMainActor, isLocal: isLocal)
    }
}

struct CachedInputDependency: Codable, Hashable {
    let type: String

    init(_ dep: InputDependency) {
        self.type = dep.type
    }

    func toInputDependency() -> InputDependency {
        InputDependency(type: type)
    }
}

struct CachedProvidedInput: Codable {
    let type: String
    let module: String
    let file: String
    let line: Int

    init(_ input: ProvidedInput) {
        self.type = input.type
        self.module = input.module
        self.file = input.file
        self.line = input.line
    }

    func toProvidedInput() -> ProvidedInput {
        ProvidedInput(type: type, module: module, file: file, line: line)
    }
}

struct CacheManifest: Codable {
    let version: Int
    let files: [String: CachedFileData]

    static let currentVersion = 4 // Bumped to 4 for buildChild provideInput fix + AppRoot inputRequirements fix
}

class FileCache {
    private var manifest: CacheManifest
    private let cacheURL: URL?
    private let mode: CacheMode
    private var cacheHits = 0
    private var cacheMisses = 0

    init(projectRoot: URL, mode: CacheMode) {
        self.mode = mode

        if mode == .noCache {
            self.cacheURL = nil
            self.manifest = CacheManifest(version: CacheManifest.currentVersion, files: [:])
            return
        }

        // Build cache path: ~/Library/Developer/Xcode/DerivedData/DependencyChecker-{hash}/cache.json
        let cacheKey = Self.computeCacheKey(projectRoot: projectRoot)
        let derivedDataURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Developer/Xcode/DerivedData")
            .appendingPathComponent("DependencyChecker-\(cacheKey)")

        self.cacheURL = derivedDataURL.appendingPathComponent("cache.json")

        // Load existing cache or create empty one
        if let cacheURL,
           let data = try? Data(contentsOf: cacheURL),
           let loaded = try? JSONDecoder().decode(CacheManifest.self, from: data),
           loaded.version == CacheManifest.currentVersion {
            self.manifest = loaded
        } else {
            self.manifest = CacheManifest(version: CacheManifest.currentVersion, files: [:])
        }
    }

    /// Computes a cache key from the project root and git branch
    private static func computeCacheKey(projectRoot: URL) -> String {
        let branch = getGitBranch(at: projectRoot) ?? "unknown"
        let input = "\(projectRoot.path):\(branch)"
        let hash = SHA256.hash(data: Data(input.utf8))
        return hash.prefix(8).map { String(format: "%02x", $0) }.joined()
    }

    /// Gets the current git branch name
    private static func getGitBranch(at url: URL) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["rev-parse", "--abbrev-ref", "HEAD"]
        process.currentDirectoryURL = url

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()

            if process.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !output.isEmpty {
                    return output
                }
            }
        } catch {
            // Ignore - will return nil
        }
        return nil
    }

    /// Checks if a file is cached and up-to-date
    func getCached(file: URL) -> CachedFileData? {
        guard mode != .noCache else { return nil }

        let path = file.path
        guard let cached = manifest.files[path] else {
            cacheMisses += 1
            return nil
        }

        // Check if file has been modified
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: path),
              let mtime = (attrs[.modificationDate] as? Date)?.timeIntervalSince1970 else {
            cacheMisses += 1
            return nil
        }

        if abs(mtime - cached.mtime) < 0.001 {
            cacheHits += 1
            return cached
        }

        cacheMisses += 1
        return nil
    }

    /// Updates the cache for a file
    func update(file: URL, data: CachedFileData) {
        guard mode != .noCache, mode != .cacheOnly else { return }
        manifest = CacheManifest(
            version: manifest.version,
            files: manifest.files.merging([file.path: data]) { _, new in new }
        )
    }

    /// Saves the cache to disk
    func save() {
        guard mode == .normal, let cacheURL else { return }

        do {
            // Create directory if needed
            let directory = cacheURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(manifest)
            try data.write(to: cacheURL)
        } catch {
            print("Warning: Failed to save cache: \(error)")
        }
    }

    /// Removes entries for files that no longer exist
    func pruneStaleEntries() {
        guard mode == .normal else { return }

        let fileManager = FileManager.default
        var updatedFiles = manifest.files
        for path in manifest.files.keys where !fileManager.fileExists(atPath: path) {
            updatedFiles.removeValue(forKey: path)
        }
        manifest = CacheManifest(version: manifest.version, files: updatedFiles)
    }

    func printStats() {
        let total = cacheHits + cacheMisses
        if total > 0 {
            let hitRate = Int(Double(cacheHits) / Double(total) * 100)
            print("Cache: \(cacheHits) hits, \(cacheMisses) misses (\(hitRate)% hit rate)")
        }
    }

    var isCacheOnly: Bool {
        mode == .cacheOnly
    }

    var hasMisses: Bool {
        cacheMisses > 0
    }
}

// MARK: - Configuration

enum ProjectMode: String {
    case distributed // Multiple Package.swift files (default)
    case monorepo // Single Package.swift with multiple targets
}

struct Configuration {
    let appName: String
    let projectRoot: URL
    let modulesDirectory: URL
    let mode: ProjectMode
    let graphOnly: Bool
    let dependencyGraphOnly: Bool
    let appSourceDirectory: URL? // Additional directory to scan for root-level registrations
    let cacheMode: CacheMode

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    static func parse() -> Configuration {
        let arguments = CommandLine.arguments

        // Default values
        var appName = "AppShell"
        var projectRoot: URL?
        var modulesPath: String?
        var mode: ProjectMode = .distributed
        var graphOnly = false
        var dependencyGraphOnly = false
        var appSourcePath: String?
        var cacheMode: CacheMode = .normal

        // Parse arguments
        var argIndex = 1
        while argIndex < arguments.count {
            let arg = arguments[argIndex]

            switch arg {
            case "--app",
                 "-a":
                if argIndex + 1 < arguments.count {
                    appName = arguments[argIndex + 1]
                    argIndex += 2
                } else {
                    printUsageAndExit("Missing value for \(arg)")
                }

            case "--project",
                 "-p":
                if argIndex + 1 < arguments.count {
                    projectRoot = URL(fileURLWithPath: arguments[argIndex + 1])
                    argIndex += 2
                } else {
                    printUsageAndExit("Missing value for \(arg)")
                }

            case "--modules",
                 "-m":
                if argIndex + 1 < arguments.count {
                    modulesPath = arguments[argIndex + 1]
                    argIndex += 2
                } else {
                    printUsageAndExit("Missing value for \(arg)")
                }

            case "--mode":
                if argIndex + 1 < arguments.count {
                    let modeStr = arguments[argIndex + 1].lowercased()
                    switch modeStr {
                    case "distributed",
                         "dist",
                         "d":
                        mode = .distributed
                    case "monorepo",
                         "mono",
                         "m":
                        mode = .monorepo
                    default:
                        let msg = "Invalid mode '\(modeStr)'. Use 'distributed' or 'monorepo'"
                        printUsageAndExit(msg)
                    }
                    argIndex += 2
                } else {
                    printUsageAndExit("Missing value for \(arg)")
                }

            case "--help",
                 "-h":
                printUsageAndExit(nil)

            case "--graph",
                 "-g":
                graphOnly = true
                argIndex += 1

            case "--dependency-graph",
                 "-dg":
                dependencyGraphOnly = true
                argIndex += 1

            case "--app-source",
                 "-as":
                if argIndex + 1 < arguments.count {
                    appSourcePath = arguments[argIndex + 1]
                    argIndex += 2
                } else {
                    printUsageAndExit("Missing value for \(arg)")
                }

            case "--cache-only":
                cacheMode = .cacheOnly
                argIndex += 1

            case "--no-cache":
                cacheMode = .noCache
                argIndex += 1

            default:
                // If no flag, treat as project root for backwards compatibility
                if projectRoot == nil {
                    projectRoot = URL(fileURLWithPath: arg)
                }
                argIndex += 1
            }
        }

        // Default project root: find by searching upward for a directory with Modules/ or app Package.swift
        let resolvedProjectRoot = projectRoot ?? findProjectRoot()

        // Default modules directory: {projectRoot}/Modules (or Sources for monorepo)
        let resolvedModulesDir: URL = if let modulesPath {
            if modulesPath.hasPrefix("/") {
                URL(fileURLWithPath: modulesPath)
            } else {
                resolvedProjectRoot.appendingPathComponent(modulesPath)
            }
        } else {
            // Default based on mode
            resolvedProjectRoot.appendingPathComponent(mode == .monorepo ? "Sources" : "Modules")
        }

        // Resolve app source directory if provided
        let resolvedAppSourceDir: URL? = if let appSourcePath {
            if appSourcePath.hasPrefix("/") {
                URL(fileURLWithPath: appSourcePath)
            } else {
                resolvedProjectRoot.appendingPathComponent(appSourcePath)
            }
        } else {
            nil
        }

        return Configuration(
            appName: appName,
            projectRoot: resolvedProjectRoot,
            modulesDirectory: resolvedModulesDir,
            mode: mode,
            graphOnly: graphOnly,
            dependencyGraphOnly: dependencyGraphOnly,
            appSourceDirectory: resolvedAppSourceDir,
            cacheMode: cacheMode
        )
    }

    // swiftlint:disable:next function_body_length
    static func printUsageAndExit(_ error: String?) -> Never {
        if let error {
            print("Error: \(error)\n")
        }

        print("""
        DependencyChecker - Validates dependency injection requirements

        USAGE:
            DependencyChecker [OPTIONS] [PROJECT_ROOT]

        OPTIONS:
            -a, --app <name>        App name (default: AppShell)
                                    Used to identify the root module for dependency registration

            -p, --project <path>    Project root directory (default: parent of current directory)
                                    The root directory containing your app and modules

            -m, --modules <path>    Modules/Sources directory (default: {project}/Modules or {project}/Sources)
                                    Can be absolute or relative to project root

            --mode <mode>           Project structure mode (default: distributed)
                                    - distributed (dist, d): Multiple Package.swift files
                                    - monorepo (mono, m): Single Package.swift with multiple targets

            -as, --app-source <path>
                                    Additional directory to scan for root-level registrations.
                                    Use this when your app's dependency registrations live outside
                                    the modules directory (e.g., in a separate app package).
                                    Can be absolute or relative to project root.

            -g, --graph             Print only the module dependency graph and exit

            -dg, --dependency-graph Print the dependency injection graph (modules with DI containers,
                                    their requirements, and registrations) and exit

            --cache-only            Only use cached analysis data; fail if any file is not cached.
                                    Use this for fast CI builds after a full build has populated the cache.

            --no-cache              Ignore the cache entirely; always parse all files.
                                    Use this when you want a clean analysis.

            -h, --help              Show this help message

        EXAMPLES:
            # Run with defaults (distributed mode, from DependencyChecker directory)
            swift run DependencyChecker

            # Specify app name
            swift run DependencyChecker --app MyApp

            # Monorepo mode (single Package.swift)
            swift run DependencyChecker --mode monorepo --project /path/to/MyPackage

            # Distributed mode with all options
            swift run DependencyChecker --app MyApp --project /path/to/MyProject --modules Packages/Modules

            # Hybrid: monorepo modules with separate app package for registrations
            swift run DependencyChecker --mode monorepo -p /path/to/Modules --app-source /path/to/AppPackage/Sources

            # Short form
            swift run DependencyChecker -a MyApp -p /path/to/MyProject -m Modules

            # Fast build using cache (fails if cache is stale)
            swift run DependencyChecker --cache-only --mode monorepo -p /path/to/Modules

            # Full build ignoring cache
            swift run DependencyChecker --no-cache --mode monorepo -p /path/to/Modules

        MODES:
            distributed (default):
                - Multiple Package.swift files throughout the project
                - Each module is a separate SwiftPM package
                - Dependencies defined via .package(path: "...") and .product(name:package:)
                - Module names derived from package names

            monorepo:
                - Single Package.swift at project root
                - Multiple targets in one package
                - Dependencies defined via .target(name: "...") between targets
                - Module names derived from target names
                - Sources expected at Sources/{TargetName}/ (or custom path:)

        NOTES:
            - The app name is used to identify the root module (e.g., "AppShell" -> "AppRoot")
            - @DependencyRequirements macros are analyzed for requirements
            - register* calls are analyzed for provisions
            - provideInput calls are analyzed for input provisions
            - Use --app-source when registrations are in a separate package from modules

        CACHING:
            - Cache is stored in ~/Library/Developer/Xcode/DerivedData/DependencyChecker-{hash}/
            - Cache key is derived from project path + git branch name
            - Clearing DerivedData will also clear the cache
            - Use --cache-only for fast builds, --no-cache for full rebuilds
        """)

        exit(error == nil ? 0 : 1)
    }
}

/// Finds the project root by searching from the current directory.
/// Looks for a directory that contains a valid "Modules" folder or Sources for monorepo.
func findProjectRoot() -> URL {
    let fileManager = FileManager.default
    let cwd = URL(fileURLWithPath: fileManager.currentDirectoryPath)

    // First, check if current directory is already a valid project root
    if isValidProjectRoot(cwd) {
        return cwd
    }

    // Walk up the directory tree looking for a valid project root
    var currentDir = cwd
    for _ in 0..<10 {
        let parent = currentDir.deletingLastPathComponent()
        if parent.path == currentDir.path {
            break // Reached filesystem root
        }
        currentDir = parent

        if isValidProjectRoot(currentDir) {
            return currentDir
        }
    }

    // Fallback: return current working directory
    return cwd
}

/// Checks if a directory is a valid project root
func isValidProjectRoot(_ dir: URL) -> Bool {
    let fileManager = FileManager.default

    // Skip .build directories
    if dir.path.contains("/.build/") {
        return false
    }

    // Check for Modules folder with a Package.swift (distributed mode)
    let modulesPath = dir.appendingPathComponent("Modules")
    let modulesPackage = modulesPath.appendingPathComponent("Package.swift")
    if fileManager.fileExists(atPath: modulesPackage.path) {
        return true
    }

    // Check for Modules folder containing subdirectories with Package.swift
    if fileManager.fileExists(atPath: modulesPath.path),
       let contents = try? fileManager.contentsOfDirectory(at: modulesPath, includingPropertiesForKeys: nil) {
        for item in contents {
            let subPackage = item.appendingPathComponent("Package.swift")
            if fileManager.fileExists(atPath: subPackage.path) {
                return true
            }
        }
    }

    // Check for monorepo: Package.swift (not DependencyChecker) with Sources directory
    let packagePath = dir.appendingPathComponent("Package.swift")
    let sourcesPath = dir.appendingPathComponent("Sources")
    if fileManager.fileExists(atPath: packagePath.path),
       fileManager.fileExists(atPath: sourcesPath.path) {
        if let content = try? String(contentsOf: packagePath, encoding: .utf8),
           !content.contains("name: \"DependencyChecker\"") {
            return true
        }
    }

    return false
}

struct Dependency: Hashable {
    let type: String
    let key: String?
    let isMainActor: Bool
    let isLocal: Bool

    init(type: String, key: String?, isMainActor: Bool = false, isLocal: Bool = false) {
        self.type = type
        self.key = key
        self.isMainActor = isMainActor
        self.isLocal = isLocal
    }
}

struct InputDependency: Hashable {
    let type: String
}

/// Tracks where a provideInput call was found
struct ProvidedInput {
    let type: String
    let module: String
    let file: String
    let line: Int
}

// MARK: - Module Graph (unified for both modes)

/// Represents a module (either a package or a target)
struct ModuleInfo {
    let name: String
    let sourcePath: String // Path to the Sources directory for this module
    let dependencies: [String] // Names of modules this depends on
    let isTestTarget: Bool // Whether this is a test target

    init(name: String, sourcePath: String, dependencies: [String], isTestTarget: Bool = false) {
        self.name = name
        self.sourcePath = sourcePath
        self.dependencies = dependencies
        self.isTestTarget = isTestTarget
    }
}

/// Builds and queries the module dependency graph (works for both modes)
class ModuleGraph {
    private var modules: [String: ModuleInfo] = [:] // moduleName -> ModuleInfo
    private var dependents: [String: Set<String>] = [:] // moduleName -> modules that depend on it
    private var testTargets: Set<String> = [] // Track test targets separately

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

    /// Returns whether a module is a test target
    func isTestTarget(_ moduleName: String) -> Bool {
        testTargets.contains(moduleName)
    }

    /// Returns all ancestor modules (modules that depend on this one, transitively)
    /// These are the modules "above" in the DI hierarchy that could provide dependencies/inputs
    func ancestors(of moduleName: String) -> Set<String> {
        var result = Set<String>()
        var queue = [moduleName]
        var visited = Set<String>()

        while !queue.isEmpty {
            let current = queue.removeFirst()
            guard !visited.contains(current) else { continue }
            visited.insert(current)

            // Find modules that depend on current (i.e., modules that import current)
            if let parents = dependents[current] {
                for parent in parents {
                    result.insert(parent)
                    queue.append(parent)
                }
            }
        }

        return result
    }

    /// Returns direct dependencies for a module (what it imports)
    func directDependencies(of moduleName: String) -> [String] {
        modules[moduleName]?.dependencies ?? []
    }

    /// Returns direct dependents for a module (who imports it)
    func directDependents(of moduleName: String) -> [String] {
        Array(dependents[moduleName] ?? [])
    }

    /// Returns the source path for a module
    func sourcePath(of moduleName: String) -> String? {
        modules[moduleName]?.sourcePath
    }

    var allModuleNames: [String] {
        Array(modules.keys)
    }

    /// Find which module a file belongs to based on path
    func moduleForFile(at path: String) -> String? {
        for (name, info) in modules where path.hasPrefix(info.sourcePath) {
            return name
        }
        return nil
    }

    /// Returns all paths from root modules to the target module.
    /// A path is represented as an array of module names from root to target (inclusive).
    /// Root modules are modules that have no dependents (nothing imports them).
    /// Test targets are excluded from paths since they are not part of the production dependency graph.
    func allPathsToModule(_ targetModule: String, rootModuleNames: Set<String>) -> [[String]] {
        var allPaths: [[String]] = []

        // DFS to find all paths from target back to roots
        func findPaths(current: String, currentPath: [String], visited: Set<String>) {
            let pathWithCurrent = [current] + currentPath

            // Check if we've reached a root module
            if rootModuleNames.contains(current) {
                allPaths.append(pathWithCurrent)
                return
            }

            // Get modules that depend on current (parents in the import hierarchy)
            // Exclude test targets - they are not part of the production dependency graph
            let parents = directDependents(of: current).filter { !isTestTarget($0) }

            // If no parents but not a root, this is a disconnected module - still record the path
            if parents.isEmpty {
                allPaths.append(pathWithCurrent)
                return
            }

            // Continue searching through each parent
            for parent in parents {
                // Avoid cycles
                guard !visited.contains(parent) else { continue }
                var newVisited = visited
                newVisited.insert(parent)
                findPaths(current: parent, currentPath: pathWithCurrent, visited: newVisited)
            }
        }

        findPaths(current: targetModule, currentPath: [], visited: [targetModule])
        return allPaths
    }
}

// MARK: - Distributed Mode Parser (multiple Package.swift files)

class DistributedPackageParser: SyntaxVisitor {
    var packageName: String?
    var targetDependencies: [String: [String]] = [:] // targetName -> [packageNames from .product()]

    // swiftlint:disable:next cyclomatic_complexity
    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        let calledExpr = node.calledExpression.trimmedDescription

        // Package(name: "...", ...)
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

        // .target(name: "...", dependencies: [...])
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
                        // .product(name: "...", package: "...")
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

    /// Returns the dependencies for the "main" target
    func mainTargetDependencies() -> [String] {
        if let name = packageName, let deps = targetDependencies[name] {
            return deps
        }
        return targetDependencies.values.max(by: { $0.count < $1.count }) ?? []
    }
}

func parseDistributedPackage(at url: URL) -> ModuleInfo? {
    do {
        let content = try String(contentsOf: url, encoding: .utf8)
        let sourceFile = Parser.parse(source: content)
        let parser = DistributedPackageParser(viewMode: .sourceAccurate)
        parser.walk(sourceFile)

        guard let name = parser.packageName else { return nil }

        // Skip umbrella packages without matching target
        let hasMatchingTarget = parser.targetDependencies.keys.contains(name)
        if !hasMatchingTarget {
            return nil
        }

        let packageDir = url.deletingLastPathComponent()
        let sourcePath = packageDir.appendingPathComponent("Sources/\(name)").path

        return ModuleInfo(
            name: name,
            sourcePath: sourcePath,
            dependencies: parser.mainTargetDependencies()
        )
    } catch {
        print("Error parsing Package.swift at \(url.path): \(error)")
        return nil
    }
}

// MARK: - Monorepo Mode Parser (single Package.swift with multiple targets)

class MonorepoPackageParser: SyntaxVisitor {
    var packageName: String?
    var targets: [TargetInfo] = []
    private let packageDir: URL

    struct TargetInfo {
        let name: String
        let path: String? // Custom path if specified
        let dependencies: [String] // Target names (from .target(name:)) and product names
        let isTestTarget: Bool // Whether this is a test target
    }

    init(packageDir: URL) {
        self.packageDir = packageDir
        super.init(viewMode: .sourceAccurate)
    }

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        let calledExpr = node.calledExpression.trimmedDescription

        // Package(name: "...", ...)
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

        // .target(name: "...", dependencies: [...], path: "...")
        // .executableTarget(name: "...", ...)
        // .testTarget(name: "...", ...)
        if calledExpr == ".target" || calledExpr == ".executableTarget" || calledExpr == ".testTarget" {
            var targetName: String?
            var customPath: String?
            var deps: [String] = []
            let isTestTarget = calledExpr == ".testTarget"

            for arg in node.arguments {
                // name: "..."
                if arg.label?.text == "name",
                   let stringLiteral = arg.expression.as(StringLiteralExprSyntax.self),
                   let segment = stringLiteral.segments.first?.as(StringSegmentSyntax.self) {
                    targetName = segment.content.text
                }

                // path: "..."
                if arg.label?.text == "path",
                   let stringLiteral = arg.expression.as(StringLiteralExprSyntax.self),
                   let segment = stringLiteral.segments.first?.as(StringSegmentSyntax.self) {
                    customPath = segment.content.text
                }

                // dependencies: [...]
                if arg.label?.text == "dependencies",
                   let array = arg.expression.as(ArrayExprSyntax.self) {
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

                        // .product(name: "...", package: "...") - external dependency
                        if let call = element.expression.as(FunctionCallExprSyntax.self),
                           call.calledExpression.trimmedDescription == ".product" {
                            // For monorepo, we track the product name, not package
                            // (external packages aren't part of the internal dependency graph)
                            for productArg in call.arguments {
                                if productArg.label?.text == "name",
                                   let stringLiteral = productArg.expression.as(StringLiteralExprSyntax.self),
                                   let segment = stringLiteral.segments.first?.as(StringSegmentSyntax.self) {
                                    // Only add if it might be an internal target
                                    // (we'll filter later based on known targets)
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
}

func parseMonorepoPackage(at url: URL) -> [ModuleInfo] {
    do {
        let content = try String(contentsOf: url, encoding: .utf8)
        let sourceFile = Parser.parse(source: content)
        let packageDir = url.deletingLastPathComponent()
        let parser = MonorepoPackageParser(packageDir: packageDir)
        parser.walk(sourceFile)

        // Get all target names for filtering
        let allTargetNames = Set(parser.targets.map { $0.name })

        return parser.targets.map { target in
            // Determine source path
            let sourcePath: String = if let customPath = target.path {
                packageDir.appendingPathComponent(customPath).path
            } else {
                packageDir.appendingPathComponent("Sources/\(target.name)").path
            }

            // Filter dependencies to only include known internal targets
            let internalDeps = target.dependencies.filter { allTargetNames.contains($0) }

            return ModuleInfo(
                name: target.name,
                sourcePath: sourcePath,
                dependencies: internalDeps,
                isTestTarget: target.isTestTarget
            )
        }
    } catch {
        print("Error parsing Package.swift at \(url.path): \(error)")
        return []
    }
}

// MARK: - Main Analyzer

class DependencyAnalyzer: SyntaxVisitor {
    var requirements: [String: [Dependency]] = [:]
    var inputRequirements: [String: [InputDependency]] = [:]
    var provisions: [String: [Dependency]] = [:]
    var modulesWithDependencyContainer: Set<String> = [] // Tracks all modules with DependencyRequirements
    private var currentFilePath = ""
    private let appName: String
    private let moduleGraph: ModuleGraph

    /// Tracks whether we're inside a struct that conforms to DependencyRequirements
    private var isInsideDependencyRequirementsStruct = false

    init(appName: String, moduleGraph: ModuleGraph) {
        self.appName = appName
        self.moduleGraph = moduleGraph
        super.init(viewMode: .sourceAccurate)
    }

    func analyze(file: URL) {
        currentFilePath = file.path
        do {
            let content = try String(contentsOf: file, encoding: .utf8)
            let sourceFile = Parser.parse(source: content)
            walk(sourceFile)
        } catch {
            print("Error parsing file \(file.path): \(error)")
        }
    }

    private func currentModuleName() -> String {
        // First try to find module via graph
        if let moduleName = moduleGraph.moduleForFile(at: currentFilePath) {
            return moduleName
        }
        // Fallback to path-based detection
        return moduleName(for: currentFilePath, appName: appName, moduleGraph: moduleGraph)
    }

    /// Checks if a struct conforms to DependencyRequirements
    private func conformsToDependencyRequirements(_ node: StructDeclSyntax) -> Bool {
        guard let inheritanceClause = node.inheritanceClause else {
            return false
        }
        return inheritanceClause.inheritedTypes.contains { inherited in
            inherited.type.trimmedDescription == "DependencyRequirements"
        }
    }

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        // Check for @DependencyRequirements macro (existing behavior)
        for attributeElement in node.attributes {
            if let attribute = attributeElement.as(AttributeSyntax.self),
               attribute.attributeName.as(IdentifierTypeSyntax.self)?.name.text == "DependencyRequirements" {
                let module = currentModuleName()
                modulesWithDependencyContainer.insert(module) // Track this module
                let newRequirements = parseRequirementsFromAttribute(attribute)
                let newInputRequirements = parseInputRequirementsFromAttribute(attribute)
                requirements[module, default: []].append(contentsOf: newRequirements)
                inputRequirements[module, default: []].append(contentsOf: newInputRequirements)
            }
        }

        // Track if we're inside a DependencyRequirements-conforming struct
        // (for hand-written property detection)
        if conformsToDependencyRequirements(node) {
            isInsideDependencyRequirementsStruct = true
            modulesWithDependencyContainer.insert(currentModuleName()) // Track this module
        }

        return .visitChildren
    }

    override func visitPost(_ node: StructDeclSyntax) {
        // Reset when leaving a DependencyRequirements struct
        if conformsToDependencyRequirements(node) {
            isInsideDependencyRequirementsStruct = false
        }
    }

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        // Only look at properties inside DependencyRequirements-conforming structs
        guard isInsideDependencyRequirementsStruct else {
            return .visitChildren
        }

        // Check each binding in the variable declaration
        for binding in node.bindings {
            guard let identifier = binding.pattern.as(IdentifierPatternSyntax.self) else {
                continue
            }

            let propertyName = identifier.identifier.text

            // Handle: let requirements: [Requirement] = [...]
            // or: var requirements: [Requirement] = [...]
            if propertyName == "requirements" {
                if let initializer = binding.initializer,
                   let array = initializer.value.as(ArrayExprSyntax.self) {
                    let module = currentModuleName()
                    let newRequirements = parseRequirementsFromArray(array)
                    requirements[module, default: []].append(contentsOf: newRequirements)
                }
            }

            // Handle: let inputRequirements: [InputRequirement] = [...]
            // or: var inputRequirements: [InputRequirement] = [...]
            if propertyName == "inputRequirements" {
                if let initializer = binding.initializer,
                   let array = initializer.value.as(ArrayExprSyntax.self) {
                    let module = currentModuleName()
                    let newInputRequirements = parseInputRequirementsFromArray(array)
                    inputRequirements[module, default: []].append(contentsOf: newInputRequirements)
                }
            }
        }

        return .visitChildren
    }

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        guard node.name.text == "registerDependencies" else {
            return .visitChildren
        }
        let module = currentModuleName()
        let visitor = RegistrationVisitor(viewMode: .sourceAccurate)
        visitor.walk(node)
        provisions[module, default: []].append(contentsOf: visitor.registrations)
        return .skipChildren
    }

    // MARK: - Parsing from @DependencyRequirements attribute

    private func parseRequirementsFromAttribute(_ attribute: AttributeSyntax) -> [Dependency] {
        guard let arguments = attribute.arguments?.as(LabeledExprListSyntax.self) else {
            return []
        }

        var results: [Dependency] = []

        // Parse the first unlabeled argument (regular requirements)
        if let firstArg = arguments.first,
           firstArg.label == nil,
           let array = firstArg.expression.as(ArrayExprSyntax.self) {
            results.append(contentsOf: parseRequirementsFromArray(array, isMainActor: false, isLocal: false))
        }

        // Parse the mainActor: labeled argument
        if let mainActorArg = arguments.first(where: { $0.label?.text == "mainActor" }),
           let array = mainActorArg.expression.as(ArrayExprSyntax.self) {
            results.append(contentsOf: parseRequirementsFromArray(array, isMainActor: true, isLocal: false))
        }

        // Parse the local: labeled argument
        if let localArg = arguments.first(where: { $0.label?.text == "local" }),
           let array = localArg.expression.as(ArrayExprSyntax.self) {
            results.append(contentsOf: parseRequirementsFromArray(array, isMainActor: false, isLocal: true))
        }

        // Parse the localMainActor: labeled argument
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

    // MARK: - Parsing from array literals (shared between macro and hand-written)

    private func parseRequirementsFromArray(_ array: ArrayExprSyntax, isMainActor: Bool = false, isLocal: Bool = false) -> [Dependency] {
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
            let type = base.trimmedDescription
            return InputDependency(type: type)
        }
    }
}

// MARK: - Registration Visitor

class RegistrationVisitor: SyntaxVisitor {
    var registrations: [Dependency] = []

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard let calledExpression = node.calledExpression.as(MemberAccessExprSyntax.self) else {
            return .visitChildren
        }
        let functionName = calledExpression.declName.baseName.text
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

        // Analyze the call chain to determine isolation and locality
        // New API patterns:
        // - builder.registerSingleton(...) -> inherited, non-MainActor
        // - builder.mainActor.registerSingleton(...) -> inherited, MainActor
        // - builder.local.registerSingleton(...) -> local, non-MainActor
        // - builder.local.mainActor.registerSingleton(...) -> local, MainActor
        //
        // We look at the base expression to detect "local" and "mainActor" namespaces
        let fullExpr = calledExpression.trimmedDescription
        let isLocal = fullExpr.contains(".local.")
        let isMainActor = fullExpr.contains(".mainActor.")

        registrations.append(Dependency(type: type, key: key, isMainActor: isMainActor, isLocal: isLocal))
        return .skipChildren
    }
}

// MARK: - ProvideInput Visitor

class ProvideInputVisitor: SyntaxVisitor {
    var providedInputs: [ProvidedInput] = []
    private let filePath: String
    private let defaultModuleName: String
    private let sourceLocationConverter: SourceLocationConverter
    
    /// Stack of module contexts - when inside a buildChild closure, we push the target module
    private var moduleContextStack: [String] = []

    init(filePath: String, moduleName: String, source: String) {
        self.filePath = filePath
        self.defaultModuleName = moduleName
        let sourceFile = Parser.parse(source: source)
        self.sourceLocationConverter = SourceLocationConverter(fileName: filePath, tree: sourceFile)
        super.init(viewMode: .sourceAccurate)
    }
    
    /// The current module context - either from buildChild closure or the default file module
    private var currentModuleName: String {
        moduleContextStack.last ?? defaultModuleName
    }
    
    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        // Check if this is a buildChild call
        if let calledExpression = node.calledExpression.as(MemberAccessExprSyntax.self),
           calledExpression.declName.baseName.text == "buildChild" {
            // Extract the target module from buildChild(ChildModule.Dependencies.self, ...)
            if let targetModule = extractBuildChildTargetModule(from: node) {
                moduleContextStack.append(targetModule)
                
                // Visit all arguments - the closure containing provideInput calls
                // could be either a regular argument or a trailing closure
                for arg in node.arguments {
                    // Walk the expression inside the labeled argument
                    walk(arg.expression)
                }
                if let trailingClosure = node.trailingClosure {
                    walk(trailingClosure)
                }
                walk(node.additionalTrailingClosures)
                
                moduleContextStack.removeLast()
                return .skipChildren
            }
        }
        
        // Check if this is a provideInput call
        if let calledExpression = node.calledExpression.as(MemberAccessExprSyntax.self),
           calledExpression.declName.baseName.text == "provideInput" {
            if let typeArg = node.arguments.first?.expression.as(MemberAccessExprSyntax.self),
               typeArg.declName.baseName.text == "self",
               let base = typeArg.base {
                let inputType = base.trimmedDescription
                let location = sourceLocationConverter.location(for: node.positionAfterSkippingLeadingTrivia)
                
                providedInputs.append(ProvidedInput(
                    type: inputType,
                    module: currentModuleName,
                    file: filePath,
                    line: location.line
                ))
            }
            return .skipChildren
        }

        return .visitChildren
    }
    
    /// Extracts the target module name from a buildChild call.
    /// Example: parent.buildChild(ChildModule.Dependencies.self, ...) -> "ChildModule"
    /// Also handles: parent.buildChild(ChildModule.Dependencies.self, configure: { ... })
    private func extractBuildChildTargetModule(from node: FunctionCallExprSyntax) -> String? {
        // The first argument should be something like ChildModule.Dependencies.self
        guard let firstArg = node.arguments.first else {
            return nil
        }
        
        // Handle both labeled and unlabeled first argument
        let argExpr = firstArg.expression
        
        guard let memberAccess = argExpr.as(MemberAccessExprSyntax.self),
              memberAccess.declName.baseName.text == "self" else {
            return nil
        }
        
        // The base could be:
        // 1. ChildModule.Dependencies (MemberAccessExprSyntax) -> extract "ChildModule"
        // 2. SomethingDependencies (IdentifierExprSyntax or DeclReferenceExprSyntax) -> extract "Something" by stripping "Dependencies" suffix
        
        // Try pattern 1: ChildModule.Dependencies
        if let base = memberAccess.base?.as(MemberAccessExprSyntax.self),
           base.declName.baseName.text == "Dependencies",
           let moduleName = base.base?.trimmedDescription {
            return moduleName
        }
        
        // Try pattern 2: SomethingDependencies (as DeclReferenceExprSyntax - Swift 5.9+)
        if let base = memberAccess.base?.as(DeclReferenceExprSyntax.self) {
            let typeName = base.baseName.text
            if typeName.hasSuffix("Dependencies") {
                return String(typeName.dropLast("Dependencies".count))
            }
        }
        
        // Try pattern 2: SomethingDependencies (as IdentifierExprSyntax - older Swift)
        if let base = memberAccess.base?.as(IdentifierExprSyntax.self) {
            let typeName = base.identifier.text
            if typeName.hasSuffix("Dependencies") {
                return String(typeName.dropLast("Dependencies".count))
            }
        }
        
        return nil
    }
}

// MARK: - Helper Functions

func moduleName(for path: String, appName: String, moduleGraph: ModuleGraph) -> String {
    // First try graph-based lookup
    if let name = moduleGraph.moduleForFile(at: path) {
        return name
    }

    // Fallback: path-based detection
    let components = path.components(separatedBy: "/")

    // Look for Sources/{TargetName}/ pattern
    if let sourcesIndex = components.lastIndex(of: "Sources") {
        if sourcesIndex + 1 < components.count {
            let targetName = components[sourcesIndex + 1]
            // If this target name matches the appName, treat as AppRoot
            if targetName == appName {
                return "AppRoot"
            }
            // If the target isn't in our module graph, it's likely the app target
            if moduleGraph.sourcePath(of: targetName) == nil {
                return "AppRoot"
            }
            return targetName
        }
    }

    // Check if this is the app root (contains the app name in path but not in Modules)
    if path.contains("/\(appName)/"), !path.contains("/Modules/") {
        return "AppRoot"
    }

    // If the file isn't in the Modules directory at all, treat it as AppRoot
    if !path.contains("/Modules/") {
        return "AppRoot"
    }

    return "Unknown"
}

/// Formats a Dependency for display, including key and isolation info
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

/// Formats a Dependency for display (short form, without "no key")
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

func findSwiftFiles(at url: URL) -> [URL] {
    var files: [URL] = []
    let options: FileManager.DirectoryEnumerationOptions = [
        .skipsHiddenFiles,
        .skipsPackageDescendants
    ]
    let enumerator = FileManager.default.enumerator(
        at: url,
        includingPropertiesForKeys: [.isRegularFileKey],
        options: options
    )
    if let enumerator {
        for case let fileURL as URL in enumerator {
            if fileURL.pathExtension == "swift",
               fileURL.lastPathComponent != "Package.swift" {
                files.append(fileURL)
            }
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
    let enumerator = FileManager.default.enumerator(
        at: url,
        includingPropertiesForKeys: [.isRegularFileKey],
        options: options
    )
    if let enumerator {
        for case let fileURL as URL in enumerator where fileURL.lastPathComponent == "Package.swift" {
            files.append(fileURL)
        }
    }
    return files
}

// MARK: - Main Execution

// swiftlint:disable:next cyclomatic_complexity function_body_length
func main() {
    // Parse configuration from command line
    let config = Configuration.parse()

    print("DependencyChecker")
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

    // Verify paths exist
    var isDirectory: ObjCBool = false
    let projectExists = FileManager.default.fileExists(
        atPath: config.projectRoot.path,
        isDirectory: &isDirectory
    )
    guard projectExists, isDirectory.boolValue else {
        print("Error: Project root does not exist or is not a directory:")
        print("       \(config.projectRoot.path)")
        exit(1)
    }

    // For monorepo, modules directory might be Sources which should exist
    // For distributed, Modules directory should exist
    if !FileManager.default.fileExists(atPath: config.modulesDirectory.path, isDirectory: &isDirectory) {
        print("Warning: Modules directory does not exist: \(config.modulesDirectory.path)")
        print("         Continuing with project root for file scanning...")
    }

    // MARK: - Build Module Graph

    print("\nBuilding module dependency graph (\(config.mode.rawValue) mode)...")
    let moduleGraph = ModuleGraph()

    switch config.mode {
    case .distributed:
        // Find all Package.swift files
        let packageFiles = findPackageSwiftFiles(at: config.projectRoot)
        for packageFile in packageFiles {
            if let info = parseDistributedPackage(at: packageFile) {
                moduleGraph.addModule(info)
            }
        }

    case .monorepo:
        // Parse the single Package.swift at project root
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

    // Build reverse lookup after all modules are loaded
    moduleGraph.buildDependentsGraph()

    let moduleCount = moduleGraph.allModuleNames.count
    let moduleList = moduleGraph.allModuleNames.sorted().joined(separator: ", ")
    print("Found \(moduleCount) modules: \(moduleList)")

    // If --graph flag is set, print the graph and exit early
    if config.graphOnly {
        print("\n" + String(repeating: "=", count: 60))
        print("MODULE DEPENDENCY GRAPH")
        print(String(repeating: "=", count: 60))

        for moduleName in moduleGraph.allModuleNames.sorted() {
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
        exit(0)
    }

    // MARK: - Initialize Cache

    let cache = FileCache(projectRoot: config.projectRoot, mode: config.cacheMode)

    // MARK: - Analyze Swift Files

    let files = findSwiftFiles(at: config.projectRoot)
    print("Found \(files.count) Swift files to analyze.")

    var allRequirements: [String: [Dependency]] = [:]
    var allInputRequirements: [String: [InputDependency]] = [:]
    var allProvisions: [String: [Dependency]] = [:]
    var allProvidedInputs: [String: [ProvidedInput]] = [:]
    var allModulesWithDependencyContainer: Set<String> = []

    /// Parses a file and returns cached data, updating the cache if needed
    func analyzeFile(_ file: URL, moduleName: String, isAppRoot: Bool) -> CachedFileData? {
        // Check cache first
        if let cached = cache.getCached(file: file) {
            return cached
        }

        // In cache-only mode, we can't parse new files
        if cache.isCacheOnly {
            return nil
        }

        // Parse the file
        do {
            let content = try String(contentsOf: file, encoding: .utf8)
            let sourceFile = Parser.parse(source: content)

            // Get file modification time
            guard let attrs = try? FileManager.default.attributesOfItem(atPath: file.path),
                  let mtime = (attrs[.modificationDate] as? Date)?.timeIntervalSince1970 else {
                return nil
            }

            var fileRequirements: [Dependency] = []
            var fileInputRequirements: [InputDependency] = []
            var fileProvisions: [Dependency] = []
            var fileProvidedInputs: [ProvidedInput] = []
            var hasDependencyContainer = false

            // Analyze requirements and input requirements for all modules (including AppRoot)
            let moduleAnalyzer = DependencyAnalyzer(appName: config.appName, moduleGraph: moduleGraph)
            moduleAnalyzer.analyze(file: file)
            fileRequirements = moduleAnalyzer.requirements[moduleName] ?? []
            fileInputRequirements = moduleAnalyzer.inputRequirements[moduleName] ?? []
            hasDependencyContainer = moduleAnalyzer.modulesWithDependencyContainer.contains(moduleName)

            // Scan for registrations
            let registrationVisitor = RegistrationVisitor(viewMode: .sourceAccurate)
            registrationVisitor.walk(sourceFile)
            fileProvisions = registrationVisitor.registrations

            // Scan for provideInput calls
            let provideInputVisitor = ProvideInputVisitor(filePath: file.path, moduleName: moduleName, source: content)
            provideInputVisitor.walk(sourceFile)
            fileProvidedInputs = provideInputVisitor.providedInputs

            let cachedData = CachedFileData(
                mtime: mtime,
                requirements: fileRequirements.map { CachedDependency($0) },
                inputRequirements: fileInputRequirements.map { CachedInputDependency($0) },
                provisions: fileProvisions.map { CachedDependency($0) },
                providedInputs: fileProvidedInputs.map { CachedProvidedInput($0) },
                hasDependencyContainer: hasDependencyContainer
            )

            cache.update(file: file, data: cachedData)
            return cachedData

        } catch {
            print("Error processing file \(file.path): \(error)")
            return nil
        }
    }

    // Process main project files
    for file in files {
        let currentModule = moduleName(
            for: file.path,
            appName: config.appName,
            moduleGraph: moduleGraph
        )
        let isAppRoot = currentModule == "AppRoot" || currentModule == config.appName

        if let data = analyzeFile(file, moduleName: currentModule, isAppRoot: isAppRoot) {
            // Aggregate results
            if !data.requirements.isEmpty {
                let reqs = data.requirements.map { $0.toDependency() }
                allRequirements[currentModule, default: []].append(contentsOf: reqs)
            }
            if !data.inputRequirements.isEmpty {
                let inputs = data.inputRequirements.map { $0.toInputDependency() }
                allInputRequirements[currentModule, default: []].append(contentsOf: inputs)
            }
            if !data.provisions.isEmpty {
                let provs = data.provisions.map { $0.toDependency() }
                allProvisions[currentModule, default: []].append(contentsOf: provs)
            }
            if !data.providedInputs.isEmpty {
                // Group provided inputs by their actual module (not the file's module)
                // This is important for buildChild closures where provideInput targets a child module
                for cachedInput in data.providedInputs {
                    let input = cachedInput.toProvidedInput()
                    allProvidedInputs[input.module, default: []].append(input)
                }
            }
            if data.hasDependencyContainer {
                allModulesWithDependencyContainer.insert(currentModule)
            }
        }
    }

    // MARK: - Scan App Source Directory (if provided)

    // This scans an additional directory for root-level registrations and provideInput calls,
    // associating them with "AppRoot". Useful for hybrid projects where the app package
    // is separate from the modules package.

    if let appSourceDir = config.appSourceDirectory {
        let appSourceFiles = findSwiftFiles(at: appSourceDir)
        print("Scanning app source directory: \(appSourceDir.path)")
        print("  (\(appSourceFiles.count) files)")

        for file in appSourceFiles {
            if let data = analyzeFile(file, moduleName: "AppRoot", isAppRoot: true) {
                if !data.provisions.isEmpty {
                    let provs = data.provisions.map { $0.toDependency() }
                    allProvisions["AppRoot", default: []].append(contentsOf: provs)
                }
                if !data.providedInputs.isEmpty {
                    let inputs = data.providedInputs.map { $0.toProvidedInput() }
                    allProvidedInputs["AppRoot", default: []].append(contentsOf: inputs)
                }
            }
        }
    }

    // Prune stale entries and save cache
    cache.pruneStaleEntries()
    cache.save()
    cache.printStats()

    // Check for cache-only failures
    if cache.isCacheOnly, cache.hasMisses {
        print("\nError: --cache-only specified but some files were not in cache.")
        print("       Run a full build first to populate the cache.")
        exit(1)
    }

    // If --dependency-graph flag is set, print the DI-focused graph and exit
    if config.dependencyGraphOnly {
        print("\n" + String(repeating: "=", count: 60))
        print("DEPENDENCY INJECTION GRAPH")
        print(String(repeating: "=", count: 60))

        // Include AppRoot/appName in the set of DI modules for traversal
        var diModules = allModulesWithDependencyContainer
        diModules.insert("AppRoot")
        diModules.insert(config.appName)

        // Helper function to print a module with its DI info at a given depth
        // swiftlint:disable:next cyclomatic_complexity
        func printModule(_ moduleName: String, depth: Int, visited: inout Set<String>) {
            guard !visited.contains(moduleName) else { return }
            visited.insert(moduleName)

            let indent = String(repeating: "  ", count: depth)
            if depth > 0 {
                print("") // Blank line before nested modules
                print("\(indent)--> \(moduleName)")
            } else {
                print("\(config.appName) (AppRoot)")
            }

            // Print requirements
            if let reqs = allRequirements[moduleName], !reqs.isEmpty {
                print("\(indent)  Requirements:")
                for req in reqs {
                    print("\(indent)    - \(formatDependencyShort(req))")
                }
            }

            // Print input requirements
            if let inputs = allInputRequirements[moduleName], !inputs.isEmpty {
                print("\(indent)  Input Requirements:")
                for input in inputs {
                    print("\(indent)    - \(input.type)")
                }
            }

            // Print provisions (registrations)
            var provs = allProvisions[moduleName] ?? []
            // For AppRoot, also include provisions from config.appName
            if moduleName == "AppRoot" {
                provs += allProvisions[config.appName] ?? []
            }
            if !provs.isEmpty {
                print("\(indent)  Registers:")
                for prov in provs {
                    print("\(indent)    - \(formatDependencyShort(prov))")
                }
            }

            // Print provided inputs
            var providedInputs = allProvidedInputs[moduleName] ?? []
            // For AppRoot, also include inputs from config.appName
            if moduleName == "AppRoot" {
                providedInputs += allProvidedInputs[config.appName] ?? []
            }
            if !providedInputs.isEmpty {
                print("\(indent)  Provides Inputs:")
                for input in providedInputs {
                    print("\(indent)    - \(input.type)")
                }
            }

            // Recursively print dependencies that are also DI modules
            let deps = moduleGraph.directDependencies(of: moduleName)
            let diDeps = Set(deps).filter { diModules.contains($0) }.sorted()
            for dep in diDeps {
                printModule(dep, depth: depth + 1, visited: &visited)
            }
        }

        // Find DI modules that are "roots" - not a dependency of any other DI module
        // These should be printed as direct children of AppRoot
        let diRoots = diModules.filter { moduleName in
            // Skip AppRoot and appName
            guard moduleName != "AppRoot", moduleName != config.appName else { return false }
            // Check if any other DI module depends on this one
            let dependents = moduleGraph.directDependents(of: moduleName)
            let diDependents = dependents.filter { diModules.contains($0) }
            return diDependents.isEmpty
        }.sorted()

        // Start by printing AppRoot
        var visited = Set<String>()
        print("\(config.appName) (AppRoot)")
        visited.insert("AppRoot")
        visited.insert(config.appName)

        // Print AppRoot's provisions (registrations)
        let rootProvisions = (allProvisions["AppRoot"] ?? []) + (allProvisions[config.appName] ?? [])
        if !rootProvisions.isEmpty {
            print("  Registers:")
            for prov in rootProvisions {
                print("    - \(formatDependencyShort(prov))")
            }
        }

        // Print AppRoot's provided inputs
        let rootInputs = (allProvidedInputs["AppRoot"] ?? []) + (allProvidedInputs[config.appName] ?? [])
        if !rootInputs.isEmpty {
            print("  Provides Inputs:")
            for input in rootInputs {
                print("    - \(input.type)")
            }
        }

        // Print each DI root as a child of AppRoot (depth 1)
        for rootModule in diRoots {
            printModule(rootModule, depth: 1, visited: &visited)
        }

        print("")
        exit(0)
    }

    // MARK: - Output: Module Graph

    print("\n" + String(repeating: "=", count: 60))
    print("MODULE DEPENDENCY GRAPH")
    print(String(repeating: "=", count: 60))

    for moduleName in moduleGraph.allModuleNames.sorted() {
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

    // MARK: - Output: Requirements

    print("\n" + String(repeating: "=", count: 60))
    print("DEPENDENCY REQUIREMENTS")
    print(String(repeating: "=", count: 60))

    if allRequirements.isEmpty {
        print("\n  (No dependency requirements declared)")
    } else {
        allRequirements.keys.sorted().forEach { module in
            print("\n  \(module):")
            for dep in allRequirements[module]! {
                print("    - \(formatDependencyShort(dep))")
            }
        }
    }

    // MARK: - Output: Input Requirements

    print("\n" + String(repeating: "=", count: 60))
    print("INPUT REQUIREMENTS")
    print(String(repeating: "=", count: 60))

    let modulesWithInputs = allInputRequirements.filter { !$0.value.isEmpty }
    if modulesWithInputs.isEmpty {
        print("\n  (No input requirements declared)")
    } else {
        modulesWithInputs.keys.sorted().forEach { module in
            print("\n  \(module):")
            for input in allInputRequirements[module]! {
                print("    - \(input.type)")
            }
        }
    }

    // MARK: - Output: Provisions

    print("\n" + String(repeating: "=", count: 60))
    print("PROVISIONS")
    print(String(repeating: "=", count: 60))

    if allProvisions.isEmpty {
        print("\n  (No provisions found)")
    } else {
        allProvisions.keys.sorted().forEach { module in
            print("\n  \(module):")
            for dep in allProvisions[module]! {
                print("    - \(formatDependencyShort(dep))")
            }
        }
    }

    // MARK: - Output: Provided Inputs

    print("\n" + String(repeating: "=", count: 60))
    print("PROVIDED INPUTS")
    print(String(repeating: "=", count: 60))

    let allInputsFlat = allProvidedInputs.values.flatMap { $0 }
    if allInputsFlat.isEmpty {
        print("\n  (No provideInput calls found)")
    } else {
        for (module, inputs) in allProvidedInputs.sorted(by: { $0.key < $1.key }) {
            print("\n  \(module):")
            for input in inputs {
                let fileName = URL(fileURLWithPath: input.file).lastPathComponent
                print("    - \(input.type) @ \(fileName):\(input.line)")
            }
        }
    }

    // MARK: - Analysis: Dependencies

    print("\n" + String(repeating: "=", count: 60))
    print("ANALYSIS: DEPENDENCIES")
    print(String(repeating: "=", count: 60))

    // Determine the root module names
    let rootModuleNames: Set<String> = ["AppRoot", config.appName]

    var missingDependencies = 0
    for (module, requirements) in allRequirements {
        // Find all paths from root to this module
        let paths = moduleGraph.allPathsToModule(module, rootModuleNames: rootModuleNames)

        // If no paths found, fall back to ancestor-based check
        guard !paths.isEmpty else {
            // Fallback: use old ancestor-based logic
            let ancestors = moduleGraph.ancestors(of: module)
            var availableProvisions: [Dependency] = []
            // Only include non-local provisions from ancestors
            availableProvisions.append(contentsOf: (allProvisions[module] ?? []).filter { !$0.isLocal })
            availableProvisions.append(contentsOf: (allProvisions["AppRoot"] ?? []).filter { !$0.isLocal })
            availableProvisions.append(contentsOf: (allProvisions[config.appName] ?? []).filter { !$0.isLocal })
            for ancestor in ancestors {
                availableProvisions.append(contentsOf: (allProvisions[ancestor] ?? []).filter { !$0.isLocal })
            }

            for req in requirements {
                // Handle local dependencies separately
                if req.isLocal {
                    let localProvisions = allProvisions[module]?.filter { $0.isLocal } ?? []
                    if !localProvisions.contains(req) {
                        print("\n  ❌ Missing local dependency in \(module):")
                        print("     \(formatDependency(req))")
                        print("     (Local dependencies must be registered in the same module)")
                        missingDependencies += 1
                    }
                    continue
                }

                // Inherited dependencies
                if !availableProvisions.contains(req) {
                    print("\n  ❌ Missing dependency in \(module):")
                    print("     \(formatDependency(req))")

                    // Collect ALL provisions for diagnostics (including all isolation types)
                    var allDiagnosticProvisions: [Dependency] = []
                    allDiagnosticProvisions.append(contentsOf: allProvisions[module] ?? [])
                    allDiagnosticProvisions.append(contentsOf: allProvisions["AppRoot"] ?? [])
                    allDiagnosticProvisions.append(contentsOf: allProvisions[config.appName] ?? [])
                    for ancestor in ancestors {
                        allDiagnosticProvisions.append(contentsOf: allProvisions[ancestor] ?? [])
                    }

                    // Find all registrations of the same type
                    let sameType = allDiagnosticProvisions.filter { $0.type == req.type }

                    if !sameType.isEmpty {
                        // Check for same type+key but different isolation or locality
                        let sameTypeAndKey = sameType.filter { $0.key == req.key }
                        let isolationMismatch = sameTypeAndKey.filter {
                            $0.isMainActor != req.isMainActor || $0.isLocal != req.isLocal
                        }
                        for mismatch in isolationMismatch {
                            var differences: [String] = []
                            if mismatch.isMainActor != req.isMainActor {
                                let registered = mismatch.isMainActor ? "@MainActor" : "non-isolated"
                                let required = req.isMainActor ? "@MainActor" : "non-isolated"
                                differences.append("registered as \(registered), required as \(required)")
                            }
                            if mismatch.isLocal != req.isLocal {
                                let registered = mismatch.isLocal ? "local" : "inherited"
                                let required = req.isLocal ? "local" : "inherited"
                                differences.append("registered as \(registered), required as \(required)")
                            }
                            print("     ⚠️  Found \(req.type) but \(differences.joined(separator: " and "))")
                        }

                        // Check for same type with different keys
                        let sameTypeDifferentKey = sameType.filter { $0.key != req.key }
                        if !sameTypeDifferentKey.isEmpty {
                            let uniqueRegistrations = Set(sameTypeDifferentKey.map { formatDependencyShort($0) })
                            let registrationList = uniqueRegistrations.sorted().joined(separator: "\n        ")
                            print("     ⚠️  Found \(req.type) registered differently:")
                            print("        \(registrationList)")
                        }
                    }

                    print("     No paths found from root to this module")
                    missingDependencies += 1
                }
            }
            continue
        }

        // Check each requirement against ALL paths
        for req in requirements {
            // LOCAL dependencies: only check within the same module
            if req.isLocal {
                let localProvisions = allProvisions[module]?.filter { $0.isLocal } ?? []
                if !localProvisions.contains(req) {
                    print("\n  ❌ Missing local dependency in \(module):")
                    print("     \(formatDependency(req))")

                    // Check for same type registered with different isolation within local scope
                    let sameTypeLocal = localProvisions.filter { $0.type == req.type && $0.key == req.key }
                    let isolationMismatch = sameTypeLocal.first { $0.isMainActor != req.isMainActor }
                    if let mismatch = isolationMismatch {
                        let registeredIsolation = mismatch.isMainActor ? "@MainActor" : "non-isolated"
                        let requiredIsolation = req.isMainActor ? "@MainActor" : "non-isolated"
                        print("     ⚠️  Found \(req.type) registered locally as \(registeredIsolation), but required as \(requiredIsolation)")
                    }

                    // Check for same type with different keys in local scope
                    let sameTypeDifferentKey = localProvisions.filter { $0.type == req.type && $0.key != req.key }
                    if !sameTypeDifferentKey.isEmpty {
                        let uniqueKeys = Set(sameTypeDifferentKey.map { $0.key ?? "(no key)" })
                        let keyList = uniqueKeys.sorted().joined(separator: ", ")
                        print("     ⚠️  Found \(req.type) registered locally with different key(s):")
                        print("        \(keyList)")
                    }

                    print("     (Local dependencies must be registered in the same module)")
                    missingDependencies += 1
                }
                continue
            }

            // INHERITED dependencies: check along paths
            var failingPaths: [[String]] = []

            for path in paths {
                // Collect provisions available along this specific path
                // Path is ordered from root to target, e.g., ["AppShell", "ModuleA", "ModuleB", "ModuleZ"]
                // Only consider non-local provisions from ancestors
                var pathProvisions: [Dependency] = []

                // Add non-local provisions from the module itself
                pathProvisions.append(contentsOf: (allProvisions[module] ?? []).filter { !$0.isLocal })

                // Add non-local provisions from each module in the path (these are the ancestors for this specific path)
                for pathModule in path {
                    pathProvisions.append(contentsOf: (allProvisions[pathModule] ?? []).filter { !$0.isLocal })
                }

                // Also always include AppRoot and appName provisions (non-local)
                pathProvisions.append(contentsOf: (allProvisions["AppRoot"] ?? []).filter { !$0.isLocal })
                pathProvisions.append(contentsOf: (allProvisions[config.appName] ?? []).filter { !$0.isLocal })

                // Check if requirement is satisfied on this path
                if !pathProvisions.contains(req) {
                    failingPaths.append(path)
                }
            }

            // Report if ANY path fails to satisfy this requirement
            if !failingPaths.isEmpty {
                print("\n  ❌ Missing dependency in \(module):")
                print("     \(formatDependency(req))")

                // Collect ALL provisions from all paths for diagnostics (including all isolation types)
                // We need to check all registrations to provide helpful suggestions
                var allPathProvisions: [Dependency] = []
                for path in paths {
                    for pathModule in path {
                        allPathProvisions.append(contentsOf: allProvisions[pathModule] ?? [])
                    }
                }
                allPathProvisions.append(contentsOf: allProvisions[module] ?? [])
                allPathProvisions.append(contentsOf: allProvisions["AppRoot"] ?? [])
                allPathProvisions.append(contentsOf: allProvisions[config.appName] ?? [])

                // Find all registrations of the same type (regardless of key/isolation/locality)
                let sameType = allPathProvisions.filter { $0.type == req.type }

                if !sameType.isEmpty {
                    // Check for same type+key but different isolation or locality
                    let sameTypeAndKey = sameType.filter { $0.key == req.key }
                    let isolationMismatch = sameTypeAndKey.filter {
                        $0.isMainActor != req.isMainActor || $0.isLocal != req.isLocal
                    }
                    for mismatch in isolationMismatch {
                        var differences: [String] = []
                        if mismatch.isMainActor != req.isMainActor {
                            let registered = mismatch.isMainActor ? "@MainActor" : "non-isolated"
                            let required = req.isMainActor ? "@MainActor" : "non-isolated"
                            differences.append("registered as \(registered), required as \(required)")
                        }
                        if mismatch.isLocal != req.isLocal {
                            let registered = mismatch.isLocal ? "local" : "inherited"
                            let required = req.isLocal ? "local" : "inherited"
                            differences.append("registered as \(registered), required as \(required)")
                        }
                        print("     ⚠️  Found \(req.type) but \(differences.joined(separator: " and "))")
                    }

                    // Check for same type with different keys
                    let sameTypeDifferentKey = sameType.filter { $0.key != req.key }
                    if !sameTypeDifferentKey.isEmpty {
                        let uniqueRegistrations = Set(sameTypeDifferentKey.map { formatDependencyShort($0) })
                        let registrationList = uniqueRegistrations.sorted().joined(separator: "\n        ")
                        print("     ⚠️  Found \(req.type) registered differently:")
                        print("        \(registrationList)")
                    }
                }

                let pathLabel = failingPaths.count > 1 ? "s" : ""
                print("     Failing path\(pathLabel):")
                for path in failingPaths {
                    print("       - AppRoot -> \(path.joined(separator: " -> "))")
                }

                if failingPaths.count < paths.count {
                    let satisfied = paths.count - failingPaths.count
                    print("     ℹ️  (\(satisfied) of \(paths.count) paths satisfy this requirement)")
                }

                missingDependencies += 1
            }
        }
    }

    if missingDependencies == 0 {
        print("\n  ✅ All dependencies are satisfied on all paths.")
    }

    // MARK: - Analysis: Input Requirements

    print("\n" + String(repeating: "=", count: 60))
    print("ANALYSIS: INPUT REQUIREMENTS")
    print(String(repeating: "=", count: 60))

    var missingInputs = 0

    for (module, inputs) in allInputRequirements where !inputs.isEmpty {
        // Find all paths from root to this module
        let paths = moduleGraph.allPathsToModule(module, rootModuleNames: rootModuleNames)

        // If no paths found, fall back to ancestor-based check
        guard !paths.isEmpty else {
            let ancestors = moduleGraph.ancestors(of: module)
            var availableInputTypes = Set<String>()
            for input in allProvidedInputs["AppRoot"] ?? [] {
                availableInputTypes.insert(input.type)
            }
            for input in allProvidedInputs[config.appName] ?? [] {
                availableInputTypes.insert(input.type)
            }
            for ancestor in ancestors {
                for input in allProvidedInputs[ancestor] ?? [] {
                    availableInputTypes.insert(input.type)
                }
            }

            for input in inputs where !availableInputTypes.contains(input.type) {
                print("\n  ❌ Missing input for \(module):")
                print("     \(input.type)")
                print("     No paths found from root to this module")
                missingInputs += 1
            }
            continue
        }

        // Check each input requirement against ALL paths
        for input in inputs {
            var failingPaths: [[String]] = []

            for path in paths {
                // Collect provided inputs along this specific path
                // Inputs come from ancestors, NOT from the module itself
                var pathInputTypes = Set<String>()

                // Add inputs from each module in the path (ancestors)
                for pathModule in path {
                    for providedInput in allProvidedInputs[pathModule] ?? [] {
                        pathInputTypes.insert(providedInput.type)
                    }
                }

                // Also always include AppRoot and appName inputs
                for providedInput in allProvidedInputs["AppRoot"] ?? [] {
                    pathInputTypes.insert(providedInput.type)
                }
                for providedInput in allProvidedInputs[config.appName] ?? [] {
                    pathInputTypes.insert(providedInput.type)
                }

                // Check if input requirement is satisfied on this path
                if !pathInputTypes.contains(input.type) {
                    failingPaths.append(path)
                }
            }

            // Report if ANY path fails to satisfy this input requirement
            if !failingPaths.isEmpty {
                print("\n  ❌ Missing input for \(module):")
                print("     \(input.type)")
                let pathLabel = failingPaths.count > 1 ? "s" : ""
                print("     No provideInput(\(input.type).self, ...) found on failing path\(pathLabel):")
                for path in failingPaths {
                    print("       - AppRoot -> \(path.joined(separator: " -> "))")
                }

                if failingPaths.count < paths.count {
                    let satisfied = paths.count - failingPaths.count
                    print("     ℹ️  (\(satisfied) of \(paths.count) paths satisfy this requirement)")
                }

                missingInputs += 1
            }
        }
    }

    if missingInputs == 0, !modulesWithInputs.isEmpty {
        print("\n  ✅ All input requirements have matching provideInput calls on all paths.")
        print("     (Runtime validation will verify correct ordering)")
    } else if modulesWithInputs.isEmpty {
        print("\n  ℹ️  No modules declare input requirements.")
    }

    // MARK: - Summary

    print("\n" + String(repeating: "=", count: 60))
    print("SUMMARY")
    print(String(repeating: "=", count: 60))

    let totalIssues = missingDependencies + missingInputs
    if totalIssues == 0 {
        print("\n  ✅ All checks passed! All dependency paths are satisfied.")
    } else {
        print("\n  Found \(totalIssues) issue(s):")
        if missingDependencies > 0 {
            let depLabel = missingDependencies == 1 ? "y" : "ies"
            print("    - \(missingDependencies) missing dependenc\(depLabel) (on one or more paths)")
        }
        if missingInputs > 0 {
            let inputLabel = missingInputs == 1 ? "" : "s"
            print("    - \(missingInputs) missing input\(inputLabel) (on one or more paths)")
        }
        exit(1)
    }

    print("")
}

main()
