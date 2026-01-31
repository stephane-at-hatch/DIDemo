//
//  Movie.swift
//  MovieDomainInterface
//
//  Created by Stephane Magne
//

import Foundation

/// A movie in our domain model.
public struct Movie: Sendable, Equatable, Identifiable, Hashable {
    public let id: Int
    public let title: String
    public let overview: String
    public let posterPath: String?
    public let backdropPath: String?
    public let releaseDate: Date?
    public let voteAverage: Double
    public let voteCount: Int
    public let popularity: Double
    public let genreIds: [Int]

    public init(
        id: Int,
        title: String,
        overview: String,
        posterPath: String?,
        backdropPath: String?,
        releaseDate: Date?,
        voteAverage: Double,
        voteCount: Int,
        popularity: Double,
        genreIds: [Int]
    ) {
        self.id = id
        self.title = title
        self.overview = overview
        self.posterPath = posterPath
        self.backdropPath = backdropPath
        self.releaseDate = releaseDate
        self.voteAverage = voteAverage
        self.voteCount = voteCount
        self.popularity = popularity
        self.genreIds = genreIds
    }
}

// MARK: - Convenience

extension Movie {

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

    /// The vote average formatted with one decimal (e.g., "8.4").
    public var formattedVoteAverage: String {
        String(format: "%.1f", voteAverage)
    }
}
