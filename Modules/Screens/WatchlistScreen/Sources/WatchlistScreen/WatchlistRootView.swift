//
//  WatchlistRootView.swift
//  WatchlistScreen
//
//  Created by Stephane Magne
//

import SwiftUI
import WatchlistScreenViews

/// Root view that wires the WatchlistView to the WatchlistViewModel.
public struct WatchlistRootView: View {
    @State private var viewModel: WatchlistViewModel

    public init(
        viewModel: WatchlistViewModel
    ) {
        self._viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        WatchlistView(
            state: viewModel.viewState,
            imageBaseURL: viewModel.imageBaseURLForView,
            onAction: { action in
                switch action {
                case .onAppear:
                    viewModel.handleOnAppear()

                case .movieTapped(let movieId):
                    viewModel.handleMovieSelected(movieId)

                case .removeTapped(let movieId):
                    viewModel.handleRemove(movieId)

                case .retryTapped:
                    viewModel.handleRetry()
                }
            }
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        WatchlistRootView(
            viewModel: WatchlistViewModel(
                watchlistRepository: .fixtureData,
                imageBaseURL: URL(string: "https://image.tmdb.org/t/p")!,
                navigationClient: .mock()
            )
        )
    }
}
