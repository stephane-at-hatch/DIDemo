//
//  TMDBClient+Live.swift
//  TMDBClient
//
//  Created by Stephane Magne
//

import Foundation
import TMDBClientInterface

extension TMDBClient {

    /// Creates a live TMDB client that makes real network requests.
    /// - Parameter configuration: The TMDB configuration including API credentials
    /// - Returns: A configured TMDBClient instance
    public static func live(configuration: TMDBConfiguration) -> TMDBClient {
        let networkClient = TMDBNetworkClient(configuration: configuration)

        return TMDBClient(
            nowPlaying: { page in
                try await networkClient.fetch(
                    endpoint: "/movie/now_playing",
                    queryItems: [
                        URLQueryItem(name: "page", value: String(page)),
                        URLQueryItem(name: "region", value: configuration.region)
                    ]
                )
            },
            popular: { page in
                try await networkClient.fetch(
                    endpoint: "/movie/popular",
                    queryItems: [
                        URLQueryItem(name: "page", value: String(page)),
                        URLQueryItem(name: "region", value: configuration.region)
                    ]
                )
            },
            topRated: { page in
                try await networkClient.fetch(
                    endpoint: "/movie/top_rated",
                    queryItems: [
                        URLQueryItem(name: "page", value: String(page)),
                        URLQueryItem(name: "region", value: configuration.region)
                    ]
                )
            },
            upcoming: { page in
                try await networkClient.fetch(
                    endpoint: "/movie/upcoming",
                    queryItems: [
                        URLQueryItem(name: "page", value: String(page)),
                        URLQueryItem(name: "region", value: configuration.region)
                    ]
                )
            },
            trending: { timeWindow, page in
                try await networkClient.fetch(
                    endpoint: "/trending/movie/\(timeWindow.rawValue)",
                    queryItems: [
                        URLQueryItem(name: "page", value: String(page))
                    ]
                )
            },
            searchMovies: { query, page in
                try await networkClient.fetch(
                    endpoint: "/search/movie",
                    queryItems: [
                        URLQueryItem(name: "query", value: query),
                        URLQueryItem(name: "page", value: String(page)),
                        URLQueryItem(name: "include_adult", value: "false"),
                        URLQueryItem(name: "region", value: configuration.region)
                    ]
                )
            },
            movieDetails: { movieId in
                try await networkClient.fetch(
                    endpoint: "/movie/\(movieId)",
                    queryItems: []
                )
            },
            movieCredits: { movieId in
                try await networkClient.fetch(
                    endpoint: "/movie/\(movieId)/credits",
                    queryItems: []
                )
            },
            configuration: configuration
        )
    }
}
