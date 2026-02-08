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

    public init(
        viewModel: DiscoverViewModel
    ) {
        self._viewModel = State(initialValue: viewModel)
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
                    viewModel.movieSelected(movieId)

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
            imageBaseURL: URL(string: "https://image.tmdb.org/t/p")!,
            navigationClient: .mock()
        )
    )
}
