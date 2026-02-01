//
//  DetailViewState.swift
//  DetailScreenViews
//
//  Created by Stephane Magne
//

import Foundation

// MARK: - View State

public struct DetailViewState: Equatable, Sendable {
    public let loadState: DetailLoadState
    public let movie: MovieDetailViewState?
    public let credits: MovieCreditsViewState?
    public let isInWatchlist: Bool

    public init(
        loadState: DetailLoadState,
        movie: MovieDetailViewState?,
        credits: MovieCreditsViewState?,
        isInWatchlist: Bool
    ) {
        self.loadState = loadState
        self.movie = movie
        self.credits = credits
        self.isInWatchlist = isInWatchlist
    }
}

// MARK: - Load State

public enum DetailLoadState: Equatable, Sendable {
    case idle
    case loading
    case error(message: String)
}

// MARK: - Movie Detail View State

public struct MovieDetailViewState: Equatable, Sendable, Identifiable {
    public let id: Int
    public let title: String
    public let tagline: String?
    public let overview: String
    public let releaseYear: String?
    public let runtime: String?
    public let rating: String
    public let voteCount: String
    public let posterPath: String?
    public let backdropPath: String?
    public let genres: [String]
    public let budget: String?
    public let revenue: String?

    public init(
        id: Int,
        title: String,
        tagline: String?,
        overview: String,
        releaseYear: String?,
        runtime: String?,
        rating: String,
        voteCount: String,
        posterPath: String?,
        backdropPath: String?,
        genres: [String],
        budget: String?,
        revenue: String?
    ) {
        self.id = id
        self.title = title
        self.tagline = tagline
        self.overview = overview
        self.releaseYear = releaseYear
        self.runtime = runtime
        self.rating = rating
        self.voteCount = voteCount
        self.posterPath = posterPath
        self.backdropPath = backdropPath
        self.genres = genres
        self.budget = budget
        self.revenue = revenue
    }
}

// MARK: - Credits View State

public struct MovieCreditsViewState: Equatable, Sendable {
    public let directors: [String]
    public let cast: [CastMemberViewState]

    public init(directors: [String], cast: [CastMemberViewState]) {
        self.directors = directors
        self.cast = cast
    }
}

public struct CastMemberViewState: Equatable, Sendable, Identifiable {
    public let id: Int
    public let name: String
    public let character: String
    public let profilePath: String?

    public init(id: Int, name: String, character: String, profilePath: String?) {
        self.id = id
        self.name = name
        self.character = character
        self.profilePath = profilePath
    }
}

// MARK: - Actions

public enum DetailAction: Equatable, Sendable {
    case onAppear
    case retryTapped
    case watchlistTapped
    case backTapped
}
