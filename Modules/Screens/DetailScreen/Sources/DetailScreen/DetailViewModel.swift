//
//  DetailViewModel.swift
//  DetailScreen
//
//  Created by Stephane Magne
//

import Foundation
import MovieDomainInterface
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
        imageBaseURL: URL
    ) {
        self.movieId = movieId
        self.movieRepository = movieRepository
        self.imageBaseURL = imageBaseURL
    }

    // MARK: - Public Methods

    public func handleOnAppear() {
        guard !hasAppeared else { return }
        hasAppeared = true
        Task {
            await loadDetails()
        }
    }

    public func handleRetry() {
        Task {
            await loadDetails()
        }
    }

    public func handleWatchlistTapped() {
        isInWatchlist.toggle()
        // TODO: Persist to WatchlistDomain
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
