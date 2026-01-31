//
//  MovieDTO+Mapping.swift
//  MovieDomain
//
//  Created by Stephane Magne
//

import Foundation
import MovieDomainInterface
import TMDBClientInterface

// MARK: - Movie List Item Mapping

extension MovieListItemDTO {

    func toDomain() -> Movie {
        Movie(
            id: id,
            title: title,
            overview: overview,
            posterPath: posterPath,
            backdropPath: backdropPath,
            releaseDate: releaseDate.flatMap { Self.parseDate($0) },
            voteAverage: voteAverage,
            voteCount: voteCount,
            popularity: popularity,
            genreIds: genreIds
        )
    }

    private static func parseDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString)
    }
}

// MARK: - Movie Detail Mapping

extension MovieDetailDTO {

    func toDomain() -> MovieDetails {
        MovieDetails(
            id: id,
            title: title,
            overview: overview,
            tagline: tagline,
            posterPath: posterPath,
            backdropPath: backdropPath,
            releaseDate: releaseDate.flatMap { Self.parseDate($0) },
            voteAverage: voteAverage,
            voteCount: voteCount,
            popularity: popularity,
            runtime: runtime,
            budget: budget,
            revenue: revenue,
            status: status,
            genres: genres.map { $0.toDomain() },
            homepage: homepage,
            imdbId: imdbId
        )
    }

    private static func parseDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString)
    }
}

extension GenreDTO {

    func toDomain() -> Genre {
        Genre(id: id, name: name)
    }
}

// MARK: - Paginated Response Mapping

extension MovieListResponseDTO {

    func toDomain() -> PaginatedMovies {
        PaginatedMovies(
            items: results.map { $0.toDomain() },
            page: page,
            totalPages: totalPages,
            totalResults: totalResults
        )
    }
}
