//
//  WatchlistItem.swift
//  WatchlistDomainInterface
//
//  Created by Stephane Magne
//

import Foundation

/// A movie saved to the user's watchlist.
///
/// Stores enough data to render a list row without a network round-trip.
public struct WatchlistItem: Sendable, Equatable, Identifiable, Hashable, Codable {
    public let id: Int
    public let title: String
    public let overview: String
    public let posterPath: String?
    public let releaseYear: String?
    public let voteAverage: Double
    public let dateAdded: Date

    public init(
        id: Int,
        title: String,
        overview: String,
        posterPath: String?,
        releaseYear: String?,
        voteAverage: Double,
        dateAdded: Date
    ) {
        self.id = id
        self.title = title
        self.overview = overview
        self.posterPath = posterPath
        self.releaseYear = releaseYear
        self.voteAverage = voteAverage
        self.dateAdded = dateAdded
    }
}

// MARK: - Convenience

extension WatchlistItem {

    /// The vote average formatted with one decimal (e.g., "8.4").
    public var formattedVoteAverage: String {
        String(format: "%.1f", voteAverage)
    }

    /// The date added, formatted for display.
    public var formattedDateAdded: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: dateAdded, relativeTo: Date())
    }
}
