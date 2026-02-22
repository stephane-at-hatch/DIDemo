//
//  WatchlistStorage.swift
//  WatchlistDomain
//
//  Created by Stephane Magne
//

import Foundation
import WatchlistDomainInterface

/// Thread-safe, actor-isolated storage for watchlist items.
///
/// This actor owns all mutable state and serializes access,
/// making it safe to call from any concurrency context.
/// The storage mechanism is injected via closures, keeping
/// this actor decoupled from the actual persistence strategy.
actor WatchlistStorage {

    // MARK: - Types

    /// Closure types for the persistence strategy.
    typealias LoadHandler = @Sendable () throws -> [WatchlistItem]
    typealias SaveHandler = @Sendable ([WatchlistItem]) throws -> Void

    // MARK: - State

    private var items: [WatchlistItem]?
    private let load: LoadHandler
    private let save: SaveHandler

    // MARK: - Init

    init(load: @escaping LoadHandler, save: @escaping SaveHandler) {
        self.load = load
        self.save = save
    }

    // MARK: - Public API

    func all() throws -> [WatchlistItem] {
        let items = try ensureLoaded()
        return items.sorted { $0.dateAdded > $1.dateAdded }
    }

    func add(_ item: WatchlistItem) throws {
        var items = try ensureLoaded()

        // No-op if already present
        guard !items.contains(where: { $0.id == item.id }) else { return }

        items.append(item)
        try save(items)
        self.items = items
    }

    func remove(_ movieId: Int) throws {
        var items = try ensureLoaded()

        // No-op if not present
        guard items.contains(where: { $0.id == movieId }) else { return }

        items.removeAll { $0.id == movieId }
        try save(items)
        self.items = items
    }

    func contains(_ movieId: Int) throws -> Bool {
        let items = try ensureLoaded()
        return items.contains { $0.id == movieId }
    }

    // MARK: - Private

    private func ensureLoaded() throws -> [WatchlistItem] {
        if let items {
            return items
        }
        let loaded = try load()
        self.items = loaded
        return loaded
    }
}
