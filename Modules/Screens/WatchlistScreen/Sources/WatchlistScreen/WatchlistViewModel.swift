//
//  WatchlistViewModel.swift
//  WatchlistScreen
//
//  Created by Stephane Magne
//

import Foundation
import ModularNavigation
import ShareComponent
import WatchlistDomainInterface
import WatchlistScreenViews

@MainActor @Observable
public final class WatchlistViewModel {

    // MARK: - Private State

    private var items: [WatchlistItem] = []
    private var loadState: LoadState = .idle
    private var hasAppeared = false

    // MARK: - Dependencies

    private let watchlistRepository: WatchlistRepository
    private let shareButtonBuilder: ShareComponent.Builder
    private let imageBaseURL: URL
    private let navigationClient: NavigationClient<WatchlistScreen.Destination>

    // MARK: - Computed ViewState

    public var viewState: WatchlistViewState {
        WatchlistViewState(
            loadState: loadState,
            items: items.map { mapToViewState($0) }
        )
    }

    public var imageBaseURLForView: URL {
        imageBaseURL
    }

    // MARK: - Init

    public init(
        watchlistRepository: WatchlistRepository,
        shareButtonBuilder: ShareComponent.Builder,
        imageBaseURL: URL,
        navigationClient: NavigationClient<WatchlistScreen.Destination>
    ) {
        self.watchlistRepository = watchlistRepository
        self.shareButtonBuilder = shareButtonBuilder
        self.imageBaseURL = imageBaseURL
        self.navigationClient = navigationClient
    }

    // MARK: - Public Methods

    public func handleOnAppear() {
        // Always reload on appear — the list may have changed
        // from the detail screen's bookmark button
        Task {
            await loadItems()
        }
    }

    public func handleRetry() {
        Task {
            await loadItems()
        }
    }

    public func handleMovieSelected(_ movieId: Int) {
        navigationClient.push(
            .external(
                .detail(
                    .detail(movieId: movieId)
                )
            )
        )
    }

    public func handleRemove(_ movieId: Int) {
        Task {
            await removeItem(movieId)
        }
    }

    public func makeShareButton(for item: WatchlistItemViewState) -> ShareButtonRootView {
        shareButtonBuilder.makeShareButton(
            title: item.title,
            overview: item.overview,
            movieId: item.id
        )
    }

    // MARK: - Private Methods

    private func loadItems() async {
        if items.isEmpty {
            loadState = .loading
        }

        do {
            items = try await watchlistRepository.all()
            loadState = .idle
        } catch {
            loadState = .error(message: error.localizedDescription)
        }
    }

    private func removeItem(_ movieId: Int) async {
        // Optimistic removal
        let removedItem = items.first { $0.id == movieId }
        let removedIndex = items.firstIndex { $0.id == movieId }
        items.removeAll { $0.id == movieId }

        do {
            try await watchlistRepository.remove(movieId)
        } catch {
            // Revert on failure
            if let removedItem, let removedIndex {
                items.insert(removedItem, at: min(removedIndex, items.count))
            }
        }
    }

    // MARK: - Mapping

    private func mapToViewState(_ item: WatchlistItem) -> WatchlistItemViewState {
        WatchlistItemViewState(
            id: item.id,
            title: item.title,
            overview: item.overview,
            posterPath: item.posterPath,
            releaseYear: item.releaseYear,
            rating: item.formattedVoteAverage,
            dateAdded: item.formattedDateAdded
        )
    }
}
