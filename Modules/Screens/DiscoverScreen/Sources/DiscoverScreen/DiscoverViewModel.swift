//
//  DiscoverViewModel.swift
//  DiscoverScreen
//
//  Created by Stephane Magne
//

import Foundation
import ModularNavigation
import MovieDomainInterface
import DiscoverScreenViews

@MainActor @Observable
public final class DiscoverViewModel {

    // MARK: - Private State

    private var searchQuery: String = ""
    private var searchResults: [Movie] = []
    private var isSearching: Bool = false
    
    private var trendingMovies: [Movie] = []
    private var popularMovies: [Movie] = []
    private var topRatedMovies: [Movie] = []
    private var upcomingMovies: [Movie] = []
    
    private var loadState: LoadState = .idle
    private var searchLoadState: LoadState = .idle
    private var hasAppeared = false

    // MARK: - Dependencies

    private let movieRepository: MovieRepository
    private let imageBaseURL: URL
    private let navigationClient: NavigationClient<DiscoverScreen.Destination>

    // MARK: - Computed ViewState

    public var viewState: DiscoverViewState {
        DiscoverViewState(
            searchQuery: searchQuery,
            isSearchActive: !searchQuery.isEmpty,
            searchLoadState: searchLoadState,
            searchResults: searchResults.map { mapToCardState($0) },
            categories: buildCategories(),
            loadState: loadState
        )
    }

    public var imageBaseURLForView: URL {
        imageBaseURL
    }

    // MARK: - Init

    public init(
        movieRepository: MovieRepository,
        imageBaseURL: URL,
        navigationClient: NavigationClient<DiscoverScreen.Destination>
    ) {
        self.movieRepository = movieRepository
        self.imageBaseURL = imageBaseURL
        self.navigationClient = navigationClient
    }

    // MARK: - Public Methods

    public func handleOnAppear() {
        guard !hasAppeared else { return }
        hasAppeared = true
        Task {
            await loadCategories()
        }
    }

    public func handleSearchQueryChanged(_ query: String) {
        searchQuery = query
        
        if query.isEmpty {
            searchResults = []
            searchLoadState = .idle
        } else {
            Task {
                await performSearch(query: query)
            }
        }
    }

    public func handleRetry() {
        Task {
            await loadCategories()
        }
    }

    public func movieId(for cardId: Int) -> Int {
        cardId
    }

    public func movieSelected(_ movieId: Int) {
        navigationClient.push(
            .external(
                .detail(
                    .detail(movieId: movieId))
                )
            )

    }

    // MARK: - Private Methods

    private func loadCategories() async {
        loadState = .loading

        do {
            async let trendingTask = movieRepository.trending(.week, 1)
            async let popularTask = movieRepository.popular(1)
            async let topRatedTask = movieRepository.topRated(1)
            async let upcomingTask = movieRepository.upcoming(1)

            let (trending, popular, topRated, upcoming) = try await (
                trendingTask,
                popularTask,
                topRatedTask,
                upcomingTask
            )

            trendingMovies = trending.items
            popularMovies = popular.items
            topRatedMovies = topRated.items
            upcomingMovies = upcoming.items
            loadState = .idle
        } catch {
            loadState = .error(message: error.localizedDescription)
        }
    }

    private func performSearch(query: String) async {
        // Debounce: only search if query hasn't changed
        let capturedQuery = query
        try? await Task.sleep(for: .milliseconds(300))
        
        guard searchQuery == capturedQuery else { return }
        
        searchLoadState = .loading

        do {
            let results = try await movieRepository.search(query, 1)
            
            // Only update if query is still the same
            if searchQuery == capturedQuery {
                searchResults = results.items
                searchLoadState = .idle
            }
        } catch {
            if searchQuery == capturedQuery {
                searchLoadState = .error(message: error.localizedDescription)
            }
        }
    }

    private func buildCategories() -> [CategoryViewState] {
        var categories: [CategoryViewState] = []

        if !trendingMovies.isEmpty {
            categories.append(CategoryViewState(
                id: "trending",
                title: "Trending This Week",
                movies: trendingMovies.prefix(10).map { mapToCardState($0) }
            ))
        }

        if !popularMovies.isEmpty {
            categories.append(CategoryViewState(
                id: "popular",
                title: "Popular",
                movies: popularMovies.prefix(10).map { mapToCardState($0) }
            ))
        }

        if !topRatedMovies.isEmpty {
            categories.append(CategoryViewState(
                id: "topRated",
                title: "Top Rated",
                movies: topRatedMovies.prefix(10).map { mapToCardState($0) }
            ))
        }

        if !upcomingMovies.isEmpty {
            categories.append(CategoryViewState(
                id: "upcoming",
                title: "Coming Soon",
                movies: upcomingMovies.prefix(10).map { mapToCardState($0) }
            ))
        }

        return categories
    }

    private func mapToCardState(_ movie: Movie) -> MovieCardViewState {
        MovieCardViewState(
            id: movie.id,
            title: movie.title,
            releaseYear: movie.releaseYear,
            rating: movie.formattedVoteAverage,
            posterPath: movie.posterPath,
            overview: movie.overview
        )
    }
}
