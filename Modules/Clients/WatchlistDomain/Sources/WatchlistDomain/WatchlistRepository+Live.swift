//
//  WatchlistRepository+Live.swift
//  WatchlistDomain
//
//  Created by Stephane Magne
//

import Foundation
import WatchlistDomainInterface

extension WatchlistRepository {

    /// Creates a live watchlist repository backed by file-based JSON persistence.
    ///
    /// The `WatchlistStorage` actor serializes all reads and writes,
    /// so this repository is safe to use from any concurrency context.
    public static func live() -> WatchlistRepository {
        let storage = WatchlistStorage(
            load: FileWatchlistPersistence.load,
            save: FileWatchlistPersistence.save
        )

        return WatchlistRepository(
            all: {
                try await storage.all()
            },
            add: { item in
                try await storage.add(item)
            },
            remove: { movieId in
                try await storage.remove(movieId)
            },
            contains: { movieId in
                try await storage.contains(movieId)
            }
        )
    }
}
