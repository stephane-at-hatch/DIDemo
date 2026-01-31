//
//  TMDBClient+Mock.swift
//  TMDBClientInterface
//
//  Created by Stephane Magne
//

import Foundation

extension TMDBClient {

    /// Creates a mock TMDB client for testing and previews.
    /// All closures default to throwing an error - override the ones you need.
    public static func mock(
        configuration: TMDBConfiguration = .mock,
        nowPlaying: (@Sendable (_ page: Int) async throws -> MovieListResponseDTO)? = nil,
        popular: (@Sendable (_ page: Int) async throws -> MovieListResponseDTO)? = nil,
        topRated: (@Sendable (_ page: Int) async throws -> MovieListResponseDTO)? = nil,
        upcoming: (@Sendable (_ page: Int) async throws -> MovieListResponseDTO)? = nil,
        trending: (@Sendable (_ timeWindow: TrendingTimeWindow, _ page: Int) async throws -> MovieListResponseDTO)? = nil,
        searchMovies: (@Sendable (_ query: String, _ page: Int) async throws -> MovieListResponseDTO)? = nil,
        movieDetails: (@Sendable (_ movieId: Int) async throws -> MovieDetailDTO)? = nil,
        movieCredits: (@Sendable (_ movieId: Int) async throws -> CreditsDTO)? = nil
    ) -> TMDBClient {
        TMDBClient(
            nowPlaying: nowPlaying ?? { _ in throw MockError.notImplemented },
            popular: popular ?? { _ in throw MockError.notImplemented },
            topRated: topRated ?? { _ in throw MockError.notImplemented },
            upcoming: upcoming ?? { _ in throw MockError.notImplemented },
            trending: trending ?? { _, _ in throw MockError.notImplemented },
            searchMovies: searchMovies ?? { _, _ in throw MockError.notImplemented },
            movieDetails: movieDetails ?? { _ in throw MockError.notImplemented },
            movieCredits: movieCredits ?? { _ in throw MockError.notImplemented },
            configuration: configuration
        )
    }

    private enum MockError: Error {
        case notImplemented
    }
}

extension TMDBConfiguration {

    /// A mock configuration for testing and previews.
    public static var mock: TMDBConfiguration {
        TMDBConfiguration(
            apiReadAccessToken: "mock-token"
        )
    }
}
