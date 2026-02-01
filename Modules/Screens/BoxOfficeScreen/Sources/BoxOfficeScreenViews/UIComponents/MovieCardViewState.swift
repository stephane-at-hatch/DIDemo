//
//  MovieCardViewState.swift
//  BoxOfficeScreenViews
//
//  Created by Stephane Magne
//

import Foundation

/// View state for a movie card in a list.
public struct MovieCardViewState: Equatable, Sendable, Identifiable {
    public let id: Int
    public let title: String
    public let releaseYear: String?
    public let rating: String
    public let posterPath: String?
    public let overview: String

    public init(
        id: Int,
        title: String,
        releaseYear: String?,
        rating: String,
        posterPath: String?,
        overview: String
    ) {
        self.id = id
        self.title = title
        self.releaseYear = releaseYear
        self.rating = rating
        self.posterPath = posterPath
        self.overview = overview
    }
}

// MARK: - Actions

public enum MovieCardAction: Equatable, Sendable {
    case tapped
}
