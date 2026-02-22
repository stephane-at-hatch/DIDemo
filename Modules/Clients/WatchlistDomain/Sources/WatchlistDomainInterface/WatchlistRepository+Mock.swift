//
//  WatchlistRepository+Mock.swift
//  WatchlistDomainInterface
//
//  Created by Stephane Magne
//

import Foundation

extension WatchlistRepository {

    /// Creates a mock repository for testing and previews.
    /// All closures default to throwing an error — override the ones you need.
    public static func mock(
        all: (@Sendable () async throws -> [WatchlistItem])? = nil,
        add: (@Sendable (_ item: WatchlistItem) async throws -> Void)? = nil,
        remove: (@Sendable (_ movieId: Int) async throws -> Void)? = nil,
        contains: (@Sendable (_ movieId: Int) async throws -> Bool)? = nil
    ) -> WatchlistRepository {
        WatchlistRepository(
            all: all ?? { throw MockError.notImplemented },
            add: add ?? { _ in throw MockError.notImplemented },
            remove: remove ?? { _ in throw MockError.notImplemented },
            contains: contains ?? { _ in throw MockError.notImplemented }
        )
    }

    /// Creates a mock repository that returns fixture data.
    /// Useful for SwiftUI previews.
    public static var fixtureData: WatchlistRepository {
        WatchlistRepository(
            all: { WatchlistItem.fixtures },
            add: { _ in },
            remove: { _ in },
            contains: { movieId in
                WatchlistItem.fixtures.contains { $0.id == movieId }
            }
        )
    }

    /// Creates an empty in-memory watchlist. Useful for previews and tests.
    public static var empty: WatchlistRepository {
        WatchlistRepository(
            all: { [] },
            add: { _ in },
            remove: { _ in },
            contains: { _ in false }
        )
    }

    private enum MockError: Error {
        case notImplemented
    }
}
