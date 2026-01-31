//
//  MovieRepository+Live.swift
//  MovieDomain
//
//  Created by Stephane Magne
//

import Foundation
import MovieDomainInterface
import TMDBClientInterface

extension MovieRepository {

    /// Creates a live movie repository that fetches from TMDB.
    /// - Parameter client: The TMDB client to use for API requests
    /// - Returns: A configured MovieRepository instance
    public static func live(client: TMDBClient) -> MovieRepository {
        MovieRepository(
            nowPlaying: { page in
                let response = try await client.nowPlaying(page)
                return response.toDomain()
            },
            popular: { page in
                let response = try await client.popular(page)
                return response.toDomain()
            },
            topRated: { page in
                let response = try await client.topRated(page)
                return response.toDomain()
            },
            upcoming: { page in
                let response = try await client.upcoming(page)
                return response.toDomain()
            },
            trending: { timeWindow, page in
                let response = try await client.trending(timeWindow.toDTO(), page)
                return response.toDomain()
            },
            search: { query, page in
                let response = try await client.searchMovies(query, page)
                return response.toDomain()
            },
            details: { movieId in
                let response = try await client.movieDetails(movieId)
                return response.toDomain()
            },
            credits: { movieId in
                let response = try await client.movieCredits(movieId)
                return response.toDomain()
            }
        )
    }
}
