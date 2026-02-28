//
//  BoxOfficeViewModel.swift
//  BoxOfficeScreen
//
//  Created by Stephane Magne
//

import Foundation
import MovieDomainInterface
import ModularNavigation
// import ShareComponent
import BoxOfficeScreenViews

@MainActor @Observable
final class BoxOfficeViewModel {

    // MARK: - Private State

    private var movies: [Movie] = []
    private var loadState: LoadState = .idle
    private var currentPage: Int = 1
    private var totalPages: Int = 1
    private var lastUpdatedDate: Date?
    private var hasAppeared = false

    // MARK: - Dependencies

    private let movieRepository: MovieRepository
    // SHARE FEATURE: Uncomment to add share button builder
    // private let shareButtonBuilder: ShareComponent.Builder
    private let imageBaseURL: URL
    private let navigationClient: NavigationClient<BoxOfficeScreen.Destination>

    // MARK: - Computed ViewState

    var viewState: BoxOfficeViewState {
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

    var imageBaseURLForView: URL {
        imageBaseURL
    }

    // SHARE FEATURE: Uncomment to expose share button building
    // func makeShareButton(for movie: MovieCardViewState) -> ShareButtonRootView {
    //     shareButtonBuilder.makeShareButton(
    //         title: movie.title,
    //         overview: movie.overview,
    //         movieId: movie.id
    //     )
    // }

    // MARK: - Init

    init(
        movieRepository: MovieRepository,
        // shareButtonBuilder: ShareComponent.Builder,
        imageBaseURL: URL,
        navigationClient: NavigationClient<BoxOfficeScreen.Destination>
    ) {
        self.movieRepository = movieRepository
        // self.shareButtonBuilder = shareButtonBuilder
        self.imageBaseURL = imageBaseURL
        self.navigationClient = navigationClient
    }

    // MARK: - Methods

    func handleOnAppear() {
        guard !hasAppeared else { return }
        hasAppeared = true
        Task {
            await loadMovies()
        }
    }

    func handleRefresh() async {
        loadState = .refreshing
        currentPage = 1
        await loadMovies(isRefresh: true)
    }

    func handleLoadMore() {
        guard !loadState.isLoading, currentPage < totalPages else { return }
        Task {
            await loadNextPage()
        }
    }

    func handleRetry() {
        Task {
            await loadMovies()
        }
    }

    func movieId(at index: Int) -> Int? {
        guard index < movies.count else { return nil }
        return movies[index].id
    }

    func movieSelected(_ movieId: Int) {
        navigationClient.push(
            .external(
                .detail(
                    .detail(movieId: movieId)
                )
            )
        )
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
