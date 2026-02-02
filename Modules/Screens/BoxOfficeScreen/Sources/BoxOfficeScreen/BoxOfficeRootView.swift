//
//  BoxOfficeRootView.swift
//  BoxOfficeScreen
//
//  Created by Stephane Magne
//

import SwiftUI
import BoxOfficeScreenViews

/// Root view that wires the BoxOfficeView to the BoxOfficeViewModel.
struct BoxOfficeRootView: View {
    @State private var viewModel: BoxOfficeViewModel

    init(
        viewModel: BoxOfficeViewModel
    ) {
        self._viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        BoxOfficeView(
            state: viewModel.viewState,
            imageBaseURL: viewModel.imageBaseURLForView,
            onAction: { action in
                switch action {
                case .onAppear:
                    viewModel.handleOnAppear()

                case .refresh:
                    Task {
                        await viewModel.handleRefresh()
                    }

                case .loadMore:
                    viewModel.handleLoadMore()

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
    BoxOfficeRootView(
        viewModel: BoxOfficeViewModel(
            movieRepository: .fixtureData,
            imageBaseURL: URL(string: "https://image.tmdb.org/t/p")!,
            navigationClient: .mock()
        )
    )
}
