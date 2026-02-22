//
//  WatchlistRepository.swift
//  WatchlistDomainInterface
//
//  Created by Stephane Magne
//

import Foundation

/// Repository for managing the user's movie watchlist.
///
/// Uses closure-based dependency injection for testability.
/// The storage mechanism is abstracted — callers don't know
/// whether persistence is file-based, SwiftData, or in-memory.
public struct WatchlistRepository: Sendable {

    // MARK: - Dependencies

    /// Returns all items in the watchlist, sorted by date added (newest first).
    public var all: @Sendable () async throws -> [WatchlistItem]

    /// Adds a movie to the watchlist.
    /// If the movie is already in the watchlist, this is a no-op.
    /// - Parameter item: The watchlist item to add
    public var add: @Sendable (_ item: WatchlistItem) async throws -> Void

    /// Removes a movie from the watchlist by its ID.
    /// If the movie is not in the watchlist, this is a no-op.
    /// - Parameter movieId: The ID of the movie to remove
    public var remove: @Sendable (_ movieId: Int) async throws -> Void

    /// Returns whether a movie is in the watchlist.
    /// - Parameter movieId: The ID of the movie to check
    public var contains: @Sendable (_ movieId: Int) async throws -> Bool

    // MARK: - Initialization

    public init(
        all: @escaping @Sendable () async throws -> [WatchlistItem],
        add: @escaping @Sendable (_ item: WatchlistItem) async throws -> Void,
        remove: @escaping @Sendable (_ movieId: Int) async throws -> Void,
        contains: @escaping @Sendable (_ movieId: Int) async throws -> Bool
    ) {
        self.all = all
        self.add = add
        self.remove = remove
        self.contains = contains
    }
}
