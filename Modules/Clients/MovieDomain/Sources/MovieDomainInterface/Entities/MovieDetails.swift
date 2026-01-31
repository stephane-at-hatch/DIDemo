//
//  MovieDetails.swift
//  MovieDomainInterface
//
//  Created by Stephane Magne
//

import Foundation

/// Detailed information about a movie.
public struct MovieDetails: Sendable, Equatable, Identifiable {
    public let id: Int
    public let title: String
    public let overview: String
    public let tagline: String?
    public let posterPath: String?
    public let backdropPath: String?
    public let releaseDate: Date?
    public let voteAverage: Double
    public let voteCount: Int
    public let popularity: Double
    public let runtime: Int?
    public let budget: Int
    public let revenue: Int
    public let status: String
    public let genres: [Genre]
    public let homepage: String?
    public let imdbId: String?

    public init(
        id: Int,
        title: String,
        overview: String,
        tagline: String?,
        posterPath: String?,
        backdropPath: String?,
        releaseDate: Date?,
        voteAverage: Double,
        voteCount: Int,
        popularity: Double,
        runtime: Int?,
        budget: Int,
        revenue: Int,
        status: String,
        genres: [Genre],
        homepage: String?,
        imdbId: String?
    ) {
        self.id = id
        self.title = title
        self.overview = overview
        self.tagline = tagline
        self.posterPath = posterPath
        self.backdropPath = backdropPath
        self.releaseDate = releaseDate
        self.voteAverage = voteAverage
        self.voteCount = voteCount
        self.popularity = popularity
        self.runtime = runtime
        self.budget = budget
        self.revenue = revenue
        self.status = status
        self.genres = genres
        self.homepage = homepage
        self.imdbId = imdbId
    }
}

// MARK: - Convenience

extension MovieDetails {

    /// The release year as a string, or nil if no release date.
    public var releaseYear: String? {
        guard let releaseDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: releaseDate)
    }

    /// The vote average formatted as a percentage string (e.g., "84%").
    public var formattedRating: String {
        let percentage = Int(voteAverage * 10)
        return "\(percentage)%"
    }

    /// The runtime formatted as hours and minutes (e.g., "2h 19m").
    public var formattedRuntime: String? {
        guard let runtime, runtime > 0 else { return nil }
        let hours = runtime / 60
        let minutes = runtime % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    /// The budget formatted as currency, or nil if zero.
    public var formattedBudget: String? {
        guard budget > 0 else { return nil }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: budget))
    }

    /// The revenue formatted as currency, or nil if zero.
    public var formattedRevenue: String? {
        guard revenue > 0 else { return nil }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: revenue))
    }

    /// Converts to a basic Movie for use in lists.
    public var asMovie: Movie {
        Movie(
            id: id,
            title: title,
            overview: overview,
            posterPath: posterPath,
            backdropPath: backdropPath,
            releaseDate: releaseDate,
            voteAverage: voteAverage,
            voteCount: voteCount,
            popularity: popularity,
            genreIds: genres.map(\.id)
        )
    }
}

/// A movie genre.
public struct Genre: Sendable, Equatable, Identifiable, Hashable {
    public let id: Int
    public let name: String

    public init(id: Int, name: String) {
        self.id = id
        self.name = name
    }
}
