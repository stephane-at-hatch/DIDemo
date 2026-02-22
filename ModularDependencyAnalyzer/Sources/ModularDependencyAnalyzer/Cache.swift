import CryptoKit
import Foundation

// MARK: - Cache Mode

enum CacheMode {
    case normal // Use cache if available, update as needed
    case cacheOnly // Only use cache, fail if file not cached
    case noCache // Ignore cache entirely, always parse
}

// MARK: - Cache Manifest

struct CacheManifest: Codable {
    let version: Int
    let files: [String: ScannedFileData]

    static let currentVersion = 6
}

// MARK: - File Cache

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

        // Build cache path: ~/Library/Developer/Xcode/DerivedData/ModularDependencyAnalyzer-{hash}/cache.json
        let cacheKey = Self.computeCacheKey(projectRoot: projectRoot)
        let derivedDataURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Developer/Xcode/DerivedData")
            .appendingPathComponent("ModularDependencyAnalyzer-\(cacheKey)")

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
    func getCached(file: URL) -> ScannedFileData? {
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
    func update(file: URL, data: ScannedFileData) {
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
