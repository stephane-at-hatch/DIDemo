//
//  DiscoverRootView.swift
//  DiscoverScreen
//
//  Created by Stephane Magne
//

import SwiftUI
import DiscoverScreenViews

/// Root view that wires the DiscoverView to the DiscoverViewModel.
public struct DiscoverRootView: View {
    @State private var viewModel: DiscoverViewModel

    private let onMovieSelected: (Int) -> Void

    public init(
        viewModel: DiscoverViewModel,
        onMovieSelected: @escaping (Int) -> Void
    ) {
        self._viewModel = State(initialValue: viewModel)
        self.onMovieSelected = onMovieSelected
    }

    public var body: some View {
        DiscoverView(
            state: viewModel.viewState,
            imageBaseURL: viewModel.imageBaseURLForView,
            onAction: { action in
                switch action {
                case .onAppear:
                    viewModel.handleOnAppear()

                case .searchQueryChanged(let query):
                    viewModel.handleSearchQueryChanged(query)

                case .movieTapped(let movieId):
                    onMovieSelected(movieId)

                case .retryTapped:
                    viewModel.handleRetry()
                }
            }
        )
    }
}

// MARK: - Preview

#Preview {
    DiscoverRootView(
        viewModel: DiscoverViewModel(
            movieRepository: .fixtureData,
            imageBaseURL: URL(string: "https://image.tmdb.org/t/p")!
        ),
        onMovieSelected: { movieId in
            print("Selected movie: \(movieId)")
        }
    )
}
