//
//  MovieRepository.swift
//  MovieDomainInterface
//
//  Created by Stephane Magne
//

import Foundation

/// Errors that can occur in the movie domain.
public enum MovieDomainError: Error, Sendable, Equatable {
    case networkError(String)
    case notFound
    case unauthorized
    case unknown(String)
}

/// Repository for fetching movie data.
///
/// Uses closure-based dependency injection for testability.
public struct MovieRepository: Sendable {

    // MARK: - Dependencies

    /// Fetches movies currently playing in theatres.
    /// - Parameter page: The page number (1-based)
    /// - Returns: A paginated result containing movies
    public var nowPlaying: @Sendable (_ page: Int) async throws -> PaginatedMovies

    /// Fetches popular movies.
    /// - Parameter page: The page number (1-based)
    /// - Returns: A paginated result containing movies
    public var popular: @Sendable (_ page: Int) async throws -> PaginatedMovies

    /// Fetches top rated movies.
    /// - Parameter page: The page number (1-based)
    /// - Returns: A paginated result containing movies
    public var topRated: @Sendable (_ page: Int) async throws -> PaginatedMovies

    /// Fetches upcoming movies.
    /// - Parameter page: The page number (1-based)
    /// - Returns: A paginated result containing movies
    public var upcoming: @Sendable (_ page: Int) async throws -> PaginatedMovies

    /// Fetches trending movies.
    /// - Parameters:
    ///   - timeWindow: The time window (day or week)
    ///   - page: The page number (1-based)
    /// - Returns: A paginated result containing movies
    public var trending: @Sendable (_ timeWindow: TrendingWindow, _ page: Int) async throws -> PaginatedMovies

    /// Searches for movies by query.
    /// - Parameters:
    ///   - query: The search query
    ///   - page: The page number (1-based)
    /// - Returns: A paginated result containing movies
    public var search: @Sendable (_ query: String, _ page: Int) async throws -> PaginatedMovies

    /// Fetches detailed information about a movie.
    /// - Parameter movieId: The movie ID
    /// - Returns: Detailed movie information
    public var details: @Sendable (_ movieId: Int) async throws -> MovieDetails

    /// Fetches credits (cast and crew) for a movie.
    /// - Parameter movieId: The movie ID
    /// - Returns: Credits information
    public var credits: @Sendable (_ movieId: Int) async throws -> MovieCredits

    // MARK: - Initialization

    public init(
        nowPlaying: @escaping @Sendable (_ page: Int) async throws -> PaginatedMovies,
        popular: @escaping @Sendable (_ page: Int) async throws -> PaginatedMovies,
        topRated: @escaping @Sendable (_ page: Int) async throws -> PaginatedMovies,
        upcoming: @escaping @Sendable (_ page: Int) async throws -> PaginatedMovies,
        trending: @escaping @Sendable (_ timeWindow: TrendingWindow, _ page: Int) async throws -> PaginatedMovies,
        search: @escaping @Sendable (_ query: String, _ page: Int) async throws -> PaginatedMovies,
        details: @escaping @Sendable (_ movieId: Int) async throws -> MovieDetails,
        credits: @escaping @Sendable (_ movieId: Int) async throws -> MovieCredits
    ) {
        self.nowPlaying = nowPlaying
        self.popular = popular
        self.topRated = topRated
        self.upcoming = upcoming
        self.trending = trending
        self.search = search
        self.details = details
        self.credits = credits
    }
}

/// Time window for trending content.
public enum TrendingWindow: String, Sendable, CaseIterable {
    case day
    case week
}
