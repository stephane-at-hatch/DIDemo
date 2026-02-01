//
//  BoxOfficeViewState.swift
//  BoxOfficeScreenViews
//
//  Created by Stephane Magne
//

import Foundation

// MARK: - View State

public struct BoxOfficeViewState: Equatable, Sendable {
    public let loadState: LoadState
    public let movies: [MovieCardViewState]
    public let lastUpdated: String?

    public init(
        loadState: LoadState,
        movies: [MovieCardViewState],
        lastUpdated: String?
    ) {
        self.loadState = loadState
        self.movies = movies
        self.lastUpdated = lastUpdated
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

public enum BoxOfficeAction: Equatable, Sendable {
    case onAppear
    case refresh
    case loadMore
    case movieTapped(movieId: Int)
    case retryTapped
}
