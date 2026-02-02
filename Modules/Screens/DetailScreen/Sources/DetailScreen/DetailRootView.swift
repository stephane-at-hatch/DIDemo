//
//  DetailRootView.swift
//  DetailScreen
//
//  Created by Stephane Magne
//

import SwiftUI
import DetailScreenViews

/// Root view that wires the DetailView to the DetailViewModel.
public struct DetailRootView: View {
    @State private var viewModel: DetailViewModel

    private let onBack: () -> Void

    public init(
        viewModel: DetailViewModel,
        onBack: @escaping () -> Void
    ) {
        self._viewModel = State(initialValue: viewModel)
        self.onBack = onBack
    }

    public var body: some View {
        DetailView(
            state: viewModel.viewState,
            imageBaseURL: viewModel.imageBaseURLForView,
            onAction: { action in
                switch action {
                case .onAppear:
                    viewModel.handleOnAppear()

                case .retryTapped:
                    viewModel.handleRetry()

                case .watchlistTapped:
                    viewModel.handleWatchlistTapped()

                case .backTapped:
                    onBack()
                }
            }
        )
    }
}

// MARK: - Preview

#Preview {
    DetailRootView(
        viewModel: DetailViewModel(
            movieId: 550,
            movieRepository: .fixtureData,
            imageBaseURL: URL(string: "https://image.tmdb.org/t/p")!
        ),
        onBack: {}
    )
}
