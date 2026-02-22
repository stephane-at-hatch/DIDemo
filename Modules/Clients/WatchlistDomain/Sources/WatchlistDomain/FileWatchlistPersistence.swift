//
//  FileWatchlistPersistence.swift
//  WatchlistDomain
//
//  Created by Stephane Magne
//

import Foundation
import WatchlistDomainInterface

/// File-based JSON persistence for watchlist items.
///
/// Reads/writes a JSON array of `WatchlistItem` to the app's
/// Application Support directory. This is the default concrete
/// implementation — swap it out for SwiftData, Core Data, etc.
/// by providing different load/save closures to `WatchlistStorage`.
enum FileWatchlistPersistence {

    // MARK: - File Location

    private static var fileURL: URL {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!

        let directory = appSupport.appendingPathComponent("MovieFinder", isDirectory: true)

        // Ensure directory exists
        try? FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )

        return directory.appendingPathComponent("watchlist.json")
    }

    // MARK: - Load / Save

    static func load() throws -> [WatchlistItem] {
        let url = fileURL

        guard FileManager.default.fileExists(atPath: url.path) else {
            return []
        }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([WatchlistItem].self, from: data)
    }

    static func save(_ items: [WatchlistItem]) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(items)
        try data.write(to: fileURL, options: .atomic)
    }
}
