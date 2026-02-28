//
//  ShareButtonRootView.swift
//  ShareComponent
//
//  Created by Stephane Magne
//

import ShareComponentViews
import SwiftUI

/// Public root view that wires the ShareButtonView to the ShareButtonViewModel.
public struct ShareButtonRootView: View {

    @State private var viewModel: ShareButtonViewModel

    public init(viewModel: ShareButtonViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        ShareButtonView(
            state: viewModel.viewState,
            onAction: { action in
                switch action {
                case .missingShareContent(let title):
                    viewModel.missingShareContent(title)
                }
            }
        )
    }
}

// MARK: - Preview

#Preview {
    ShareButtonRootView(
        viewModel: ShareButtonViewModel(
            shareClient: .fixtureData,
            title: "Fight Club",
            overview: "A depressed man suffering from insomnia meets a strange soap salesman.",
            movieId: 550
        )
    )
}
