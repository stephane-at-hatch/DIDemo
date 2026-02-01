//
//  BoxOfficeViewModel.swift
//  BoxOfficeScreen
//
//  Created by Stephane Magne
//

import Foundation
import MovieDomainInterface
import BoxOfficeScreenViews

@MainActor @Observable
public final class BoxOfficeViewModel {

    // MARK: - Private State

    private var movies: [Movie] = []
    private var loadState: LoadState = .idle
    private var currentPage: Int = 1
    private var totalPages: Int = 1
    private var lastUpdatedDate: Date?
    private var hasAppeared = false

    // MARK: - Dependencies

    private let movieRepository: MovieRepository
    private let imageBaseURL: URL

    // MARK: - Computed ViewState

    public var viewState: BoxOfficeViewState {
        BoxOfficeViewState(
            loadState: loadState,
            movies: movies.map { movie in
                MovieCardViewState(
                    id: movie.id,
                    title: movie.title,
                    releaseYear: movie.releaseYear,
                    rating: movie.formattedVoteAverage,
                    posterPath: movie.posterPath,
                    overview: movie.overview
                )
            },
            lastUpdated: formattedLastUpdated
        )
    }

    public var imageBaseURLForView: URL {
        imageBaseURL
    }

    // MARK: - Init

    public init(
        movieRepository: MovieRepository,
        imageBaseURL: URL
    ) {
        self.movieRepository = movieRepository
        self.imageBaseURL = imageBaseURL
    }

    // MARK: - Public Methods

    public func handleOnAppear() {
        guard !hasAppeared else { return }
        hasAppeared = true
        Task {
            await loadMovies()
        }
    }

    public func handleRefresh() async {
        loadState = .refreshing
        currentPage = 1
        await loadMovies(isRefresh: true)
    }

    public func handleLoadMore() {
        guard !loadState.isLoading, currentPage < totalPages else { return }
        Task {
            await loadNextPage()
        }
    }

    public func handleRetry() {
        Task {
            await loadMovies()
        }
    }

    public func movieId(at index: Int) -> Int? {
        guard index < movies.count else { return nil }
        return movies[index].id
    }

    // MARK: - Private Methods

    private func loadMovies(isRefresh: Bool = false) async {
        if !isRefresh {
            loadState = .loading
        }

        do {
            let result = try await movieRepository.nowPlaying(1)
            movies = result.items
            currentPage = result.page
            totalPages = result.totalPages
            lastUpdatedDate = Date()
            loadState = .idle
        } catch {
            loadState = .error(message: error.localizedDescription)
        }
    }

    private func loadNextPage() async {
        loadState = .loading
        let nextPage = currentPage + 1

        do {
            let result = try await movieRepository.nowPlaying(nextPage)
            movies.append(contentsOf: result.items)
            currentPage = result.page
            totalPages = result.totalPages
            loadState = .idle
        } catch {
            loadState = .error(message: error.localizedDescription)
        }
    }

    private var formattedLastUpdated: String? {
        guard let lastUpdatedDate else { return nil }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastUpdatedDate, relativeTo: Date())
    }
}
