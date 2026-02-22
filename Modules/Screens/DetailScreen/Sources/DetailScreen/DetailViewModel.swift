//
//  DetailViewModel.swift
//  DetailScreen
//
//  Created by Stephane Magne
//

import Foundation
import MovieDomainInterface
import WatchlistDomainInterface
import DetailScreenViews

@MainActor @Observable
public final class DetailViewModel {

    // MARK: - Private State

    private var movieDetails: MovieDetails?
    private var credits: MovieCredits?
    private var loadState: DetailLoadState = .idle
    private var isInWatchlist: Bool = false
    private var hasAppeared = false

    // MARK: - Dependencies

    private let movieId: Int
    private let movieRepository: MovieRepository
    private let watchlistRepository: WatchlistRepository
    private let imageBaseURL: URL

    // MARK: - Computed ViewState

    public var viewState: DetailViewState {
        DetailViewState(
            loadState: loadState,
            movie: movieDetails.map { mapToViewState($0) },
            credits: credits.map { mapCreditsToViewState($0) },
            isInWatchlist: isInWatchlist
        )
    }

    public var imageBaseURLForView: URL {
        imageBaseURL
    }

    // MARK: - Init

    public init(
        movieId: Int,
        movieRepository: MovieRepository,
        watchlistRepository: WatchlistRepository,
        imageBaseURL: URL
    ) {
        self.movieId = movieId
        self.movieRepository = movieRepository
        self.watchlistRepository = watchlistRepository
        self.imageBaseURL = imageBaseURL
    }

    // MARK: - Public Methods

    public func handleOnAppear() {
        guard !hasAppeared else { return }
        hasAppeared = true
        Task {
            await loadDetails()
            await checkWatchlistStatus()
        }
    }

    public func handleRetry() {
        Task {
            await loadDetails()
        }
    }

    public func handleWatchlistTapped() {
        Task {
            await toggleWatchlist()
        }
    }

    // MARK: - Private Methods

    private func loadDetails() async {
        loadState = .loading

        do {
            async let detailsTask = movieRepository.details(movieId)
            async let creditsTask = movieRepository.credits(movieId)

            let (details, movieCredits) = try await (detailsTask, creditsTask)

            self.movieDetails = details
            self.credits = movieCredits
            loadState = .idle
        } catch {
            loadState = .error(message: error.localizedDescription)
        }
    }

    private func checkWatchlistStatus() async {
        do {
            isInWatchlist = try await watchlistRepository.contains(movieId)
        } catch {
            // Silently fail — default to not in watchlist
            isInWatchlist = false
        }
    }

    private func toggleWatchlist() async {
        let wasInWatchlist = isInWatchlist

        // Optimistic update
        isInWatchlist.toggle()

        do {
            if wasInWatchlist {
                try await watchlistRepository.remove(movieId)
            } else {
                guard let details = movieDetails else { return }
                let item = WatchlistItem(
                    id: details.id,
                    title: details.title,
                    overview: details.overview,
                    posterPath: details.posterPath,
                    releaseYear: details.releaseYear,
                    voteAverage: details.voteAverage,
                    dateAdded: Date()
                )
                try await watchlistRepository.add(item)
            }
        } catch {
            // Revert on failure
            isInWatchlist = wasInWatchlist
        }
    }

    // MARK: - Mapping

    private func mapToViewState(_ details: MovieDetails) -> MovieDetailViewState {
        MovieDetailViewState(
            id: details.id,
            title: details.title,
            tagline: details.tagline,
            overview: details.overview,
            releaseYear: details.releaseYear,
            runtime: details.formattedRuntime,
            rating: String(format: "%.1f", details.voteAverage),
            voteCount: formatVoteCount(details.voteCount),
            posterPath: details.posterPath,
            backdropPath: details.backdropPath,
            genres: details.genres.map(\.name),
            budget: details.formattedBudget,
            revenue: details.formattedRevenue
        )
    }

    private func mapCreditsToViewState(_ credits: MovieCredits) -> MovieCreditsViewState {
        MovieCreditsViewState(
            directors: credits.directors.map(\.name),
            cast: credits.topCast(limit: 10).map { member in
                CastMemberViewState(
                    id: member.id,
                    name: member.name,
                    character: member.character,
                    profilePath: member.profilePath
                )
            }
        )
    }

    private func formatVoteCount(_ count: Int) -> String {
        if count >= 1000 {
            return String(format: "%.1fK", Double(count) / 1000)
        }
        return "\(count)"
    }
}
