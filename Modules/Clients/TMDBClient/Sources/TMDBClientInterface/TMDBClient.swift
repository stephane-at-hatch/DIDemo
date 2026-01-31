//
//  TMDBClient.swift
//  TMDBClientInterface
//
//  Created by Stephane Magne
//

import Foundation

/// Errors that can occur when interacting with the TMDB API.
public enum TMDBClientError: Error, Sendable, Equatable {
    case invalidURL
    case networkError(String)
    case decodingError(String)
    case httpError(statusCode: Int, message: String?)
    case unauthorized
    case notFound
    case rateLimited
}

/// A client for interacting with The Movie Database (TMDB) API.
///
/// Uses closure-based dependency injection for testability.
public struct TMDBClient: Sendable {

    // MARK: - Dependencies

    /// Fetches movies currently playing in theatres.
    /// - Parameters:
    ///   - page: The page number (1-based)
    /// - Returns: A paginated response containing movie list items
    public var nowPlaying: @Sendable (_ page: Int) async throws -> MovieListResponseDTO

    /// Fetches popular movies.
    /// - Parameters:
    ///   - page: The page number (1-based)
    /// - Returns: A paginated response containing movie list items
    public var popular: @Sendable (_ page: Int) async throws -> MovieListResponseDTO

    /// Fetches top rated movies.
    /// - Parameters:
    ///   - page: The page number (1-based)
    /// - Returns: A paginated response containing movie list items
    public var topRated: @Sendable (_ page: Int) async throws -> MovieListResponseDTO

    /// Fetches upcoming movies.
    /// - Parameters:
    ///   - page: The page number (1-based)
    /// - Returns: A paginated response containing movie list items
    public var upcoming: @Sendable (_ page: Int) async throws -> MovieListResponseDTO

    /// Fetches trending movies.
    /// - Parameters:
    ///   - timeWindow: The time window for trending (day or week)
    ///   - page: The page number (1-based)
    /// - Returns: A paginated response containing movie list items
    public var trending: @Sendable (_ timeWindow: TrendingTimeWindow, _ page: Int) async throws -> MovieListResponseDTO

    /// Searches for movies by query string.
    /// - Parameters:
    ///   - query: The search query
    ///   - page: The page number (1-based)
    /// - Returns: A paginated response containing movie list items
    public var searchMovies: @Sendable (_ query: String, _ page: Int) async throws -> MovieListResponseDTO

    /// Fetches detailed information for a specific movie.
    /// - Parameters:
    ///   - movieId: The TMDB movie ID
    /// - Returns: Detailed movie information
    public var movieDetails: @Sendable (_ movieId: Int) async throws -> MovieDetailDTO

    /// Fetches credits (cast and crew) for a specific movie.
    /// - Parameters:
    ///   - movieId: The TMDB movie ID
    /// - Returns: Credits information including cast and crew
    public var movieCredits: @Sendable (_ movieId: Int) async throws -> CreditsDTO

    /// The configuration used by this client.
    public var configuration: TMDBConfiguration

    // MARK: - Initialization

    public init(
        nowPlaying: @escaping @Sendable (_ page: Int) async throws -> MovieListResponseDTO,
        popular: @escaping @Sendable (_ page: Int) async throws -> MovieListResponseDTO,
        topRated: @escaping @Sendable (_ page: Int) async throws -> MovieListResponseDTO,
        upcoming: @escaping @Sendable (_ page: Int) async throws -> MovieListResponseDTO,
        trending: @escaping @Sendable (_ timeWindow: TrendingTimeWindow, _ page: Int) async throws -> MovieListResponseDTO,
        searchMovies: @escaping @Sendable (_ query: String, _ page: Int) async throws -> MovieListResponseDTO,
        movieDetails: @escaping @Sendable (_ movieId: Int) async throws -> MovieDetailDTO,
        movieCredits: @escaping @Sendable (_ movieId: Int) async throws -> CreditsDTO,
        configuration: TMDBConfiguration
    ) {
        self.nowPlaying = nowPlaying
        self.popular = popular
        self.topRated = topRated
        self.upcoming = upcoming
        self.trending = trending
        self.searchMovies = searchMovies
        self.movieDetails = movieDetails
        self.movieCredits = movieCredits
        self.configuration = configuration
    }
}

/// Time window for trending content.
public enum TrendingTimeWindow: String, Sendable {
    case day
    case week
}
