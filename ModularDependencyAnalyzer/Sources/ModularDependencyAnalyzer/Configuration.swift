import Foundation

// MARK: - Configuration

struct Configuration {
    let appName: String
    let projectRoot: URL
    let modulesDirectory: URL
    let mode: ProjectMode
    let graphOnly: Bool
    let dependencyGraphOnly: Bool
    let appSourceDirectory: URL?
    let cacheMode: CacheMode
    
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
                        printUsageAndExit("Invalid mode '\(modeStr)'. Use 'distributed' or 'monorepo'")
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
                if projectRoot == nil {
                    projectRoot = URL(fileURLWithPath: arg)
                }
                argIndex += 1
            }
        }
        
        let resolvedProjectRoot = projectRoot ?? findProjectRoot()
        
        let resolvedModulesDir: URL = if let modulesPath {
            if modulesPath.hasPrefix("/") {
                URL(fileURLWithPath: modulesPath)
            } else {
                resolvedProjectRoot.appendingPathComponent(modulesPath)
            }
        } else {
            resolvedProjectRoot.appendingPathComponent(mode == .monorepo ? "Sources" : "Modules")
        }
        
        let resolvedAppSourceDir: URL? = appSourcePath.map { path in
            if path.hasPrefix("/") {
                return URL(fileURLWithPath: path)
            } else {
                let cwd = FileManager.default.currentDirectoryPath
                let fullPath = (cwd as NSString).appendingPathComponent(path)
                return URL(fileURLWithPath: (fullPath as NSString).standardizingPath)
            }
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
    
    static func printUsageAndExit(_ error: String?) -> Never {
        if let error {
            print("Error: \(error)\n")
        }
        
        print("""
        ModularDependencyAnalyzer - Validates dependency injection graphs
        
        USAGE:
            ModularDependencyAnalyzer [OPTIONS] [PROJECT_ROOT]
        
        OPTIONS:
            -a, --app <name>        App name (default: AppShell)
            -p, --project <path>    Project root directory
            -m, --modules <path>    Modules/Sources directory
            --mode <mode>           Project mode: distributed (default) or monorepo
            -as, --app-source <path> Additional directory for root-level registrations
            -g, --graph             Print only module dependency graph
            -dg, --dependency-graph Print only discovered DI graphs
            --cache-only            Only use cached data (fail if stale)
            --no-cache              Ignore cache entirely
            -h, --help              Show this help
        
        DISCOVERY:
            The analyzer discovers dependency graphs by:
            1. Finding all types conforming to DependencyRequirements (nodes)
            2. Finding DependencyBuilder<T>() instantiations (graph roots)
            3. Tracing buildChild() calls to build edges between nodes
        
        EXAMPLES:
            swift run ModularDependencyAnalyzer
            swift run ModularDependencyAnalyzer --app MyApp --mode monorepo
            swift run ModularDependencyAnalyzer -dg  # Show discovered graphs only
        """)
        
        exit(error == nil ? 0 : 1)
    }
}

// MARK: - Project Root Discovery

func findProjectRoot() -> URL {
    let fileManager = FileManager.default
    let cwd = URL(fileURLWithPath: fileManager.currentDirectoryPath)
    
    if isValidProjectRoot(cwd) {
        return cwd
    }
    
    var currentDir = cwd
    for _ in 0..<10 {
        let parent = currentDir.deletingLastPathComponent()
        if parent.path == currentDir.path {
            break
        }
        currentDir = parent
        
        if isValidProjectRoot(currentDir) {
            return currentDir
        }
    }
    
    return cwd
}

func isValidProjectRoot(_ dir: URL) -> Bool {
    let fileManager = FileManager.default
    
    if dir.path.contains("/.build/") {
        return false
    }
    
    // Check for Modules folder with Package.swift (distributed mode)
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
    
    // Check for monorepo: Package.swift with Sources directory
    let packagePath = dir.appendingPathComponent("Package.swift")
    let sourcesPath = dir.appendingPathComponent("Sources")
    if fileManager.fileExists(atPath: packagePath.path),
       fileManager.fileExists(atPath: sourcesPath.path) {
        if let content = try? String(contentsOf: packagePath, encoding: .utf8),
           !content.contains("name: \"ModularDependencyAnalyzer\"") {
            return true
        }
    }
    
    return false
}
