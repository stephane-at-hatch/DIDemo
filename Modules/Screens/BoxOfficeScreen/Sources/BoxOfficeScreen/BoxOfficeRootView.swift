//
//  BoxOfficeRootView.swift
//  BoxOfficeScreen
//
//  Created by Stephane Magne
//

import SwiftUI
import BoxOfficeScreenViews

/// Root view that wires the BoxOfficeView to the BoxOfficeViewModel.
public struct BoxOfficeRootView: View {
    @State private var viewModel: BoxOfficeViewModel

    private let onMovieSelected: (Int) -> Void

    public init(
        viewModel: BoxOfficeViewModel,
        onMovieSelected: @escaping (Int) -> Void
    ) {
        self._viewModel = State(initialValue: viewModel)
        self.onMovieSelected = onMovieSelected
    }

    public var body: some View {
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
    BoxOfficeRootView(
        viewModel: BoxOfficeViewModel(
            movieRepository: .fixtureData,
            imageBaseURL: URL(string: "https://image.tmdb.org/t/p")!
        ),
        onMovieSelected: { movieId in
            print("Selected movie: \(movieId)")
        }
    )
}
