//
//  DiscoverViewState.swift
//  DiscoverScreenViews
//
//  Created by Stephane Magne
//

import Foundation

// MARK: - View State

public struct DiscoverViewState: Equatable, Sendable {
    public let searchQuery: String
    public let isSearchActive: Bool
    public let searchLoadState: LoadState
    public let searchResults: [MovieCardViewState]
    public let categories: [CategoryViewState]
    public let loadState: LoadState

    public init(
        searchQuery: String,
        isSearchActive: Bool,
        searchLoadState: LoadState,
        searchResults: [MovieCardViewState],
        categories: [CategoryViewState],
        loadState: LoadState
    ) {
        self.searchQuery = searchQuery
        self.isSearchActive = isSearchActive
        self.searchLoadState = searchLoadState
        self.searchResults = searchResults
        self.categories = categories
        self.loadState = loadState
    }
}

// MARK: - Category View State

public struct CategoryViewState: Equatable, Sendable, Identifiable {
    public let id: String
    public let title: String
    public let movies: [MovieCardViewState]

    public init(
        id: String,
        title: String,
        movies: [MovieCardViewState]
    ) {
        self.id = id
        self.title = title
        self.movies = movies
    }
}

// MARK: - Movie Card View State

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

// MARK: - Load State

public enum LoadState: Equatable, Sendable {
    case idle
    case loading
    case refreshing
    case error(message: String)

    public var isLoading: Bool {
        switch self {
        case .loading, .refreshing:
            return true
        case .idle, .error:
            return false
        }
    }
}

// MARK: - Actions

public enum DiscoverAction: Equatable, Sendable {
    case onAppear
    case searchQueryChanged(String)
    case movieTapped(movieId: Int)
    case retryTapped
}
