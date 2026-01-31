//
//  MovieRepository+Mock.swift
//  MovieDomainInterface
//
//  Created by Stephane Magne
//

import Foundation

extension MovieRepository {

    /// Creates a mock repository for testing and previews.
    /// All closures default to throwing an error - override the ones you need.
    public static func mock(
        nowPlaying: (@Sendable (_ page: Int) async throws -> PaginatedMovies)? = nil,
        popular: (@Sendable (_ page: Int) async throws -> PaginatedMovies)? = nil,
        topRated: (@Sendable (_ page: Int) async throws -> PaginatedMovies)? = nil,
        upcoming: (@Sendable (_ page: Int) async throws -> PaginatedMovies)? = nil,
        trending: (@Sendable (_ timeWindow: TrendingWindow, _ page: Int) async throws -> PaginatedMovies)? = nil,
        search: (@Sendable (_ query: String, _ page: Int) async throws -> PaginatedMovies)? = nil,
        details: (@Sendable (_ movieId: Int) async throws -> MovieDetails)? = nil,
        credits: (@Sendable (_ movieId: Int) async throws -> MovieCredits)? = nil
    ) -> MovieRepository {
        MovieRepository(
            nowPlaying: nowPlaying ?? { _ in throw MockError.notImplemented },
            popular: popular ?? { _ in throw MockError.notImplemented },
            topRated: topRated ?? { _ in throw MockError.notImplemented },
            upcoming: upcoming ?? { _ in throw MockError.notImplemented },
            trending: trending ?? { _, _ in throw MockError.notImplemented },
            search: search ?? { _, _ in throw MockError.notImplemented },
            details: details ?? { _ in throw MockError.notImplemented },
            credits: credits ?? { _ in throw MockError.notImplemented }
        )
    }

    /// Creates a mock repository that returns fixture data.
    /// Useful for SwiftUI previews.
    public static var fixtureData: MovieRepository {
        MovieRepository(
            nowPlaying: { _ in .fixture },
            popular: { _ in .fixture },
            topRated: { _ in .fixture },
            upcoming: { _ in .fixture },
            trending: { _, _ in .fixture },
            search: { _, _ in .fixture },
            details: { _ in .fixture },
            credits: { _ in .fixture }
        )
    }

    private enum MockError: Error {
        case notImplemented
    }
}
