//
//  WatchlistViewState.swift
//  WatchlistScreenViews
//
//  Created by Stephane Magne
//

import Foundation

// MARK: - View State

public struct WatchlistViewState: Equatable, Sendable {
    public let loadState: LoadState
    public let items: [WatchlistItemViewState]

    public init(
        loadState: LoadState,
        items: [WatchlistItemViewState]
    ) {
        self.loadState = loadState
        self.items = items
    }
}

// MARK: - Watchlist Item View State

public struct WatchlistItemViewState: Equatable, Sendable, Identifiable {
    public let id: Int
    public let title: String
    public let overview: String
    public let posterPath: String?
    public let releaseYear: String?
    public let rating: String
    public let dateAdded: String

    public init(
        id: Int,
        title: String,
        overview: String,
        posterPath: String?,
        releaseYear: String?,
        rating: String,
        dateAdded: String
    ) {
        self.id = id
        self.title = title
        self.overview = overview
        self.posterPath = posterPath
        self.releaseYear = releaseYear
        self.rating = rating
        self.dateAdded = dateAdded
    }
}

// MARK: - Load State

public enum LoadState: Equatable, Sendable {
    case idle
    case loading
    case error(message: String)

    public var isLoading: Bool {
        switch self {
        case .loading:
            return true
        case .idle, .error:
            return false
        }
    }
}

// MARK: - Actions

public enum WatchlistAction: Equatable, Sendable {
    case onAppear
    case movieTapped(movieId: Int)
    case removeTapped(movieId: Int)
    case retryTapped
}
