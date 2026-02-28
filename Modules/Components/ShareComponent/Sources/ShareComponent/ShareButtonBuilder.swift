//
//  ShareButtonBuilder.swift
//  ShareComponent
//
//  Created by Stephane Magne
//

import ShareClientInterface
import SwiftUI

extension ShareComponent {

    /// Builds share button views using the resolved dependencies.
    @MainActor
    public struct Builder {

        private let shareClient: ShareClient

        public init(dependencies: Dependencies) {
            self.shareClient = dependencies.shareClient
        }

        private init(shareClient: ShareClient) {
            self.shareClient = shareClient
        }

        public func makeShareButton(
            title: String,
            overview: String,
            movieId: Int
        ) -> ShareButtonRootView {
            let viewModel = ShareButtonViewModel(
                shareClient: shareClient,
                title: title,
                overview: overview,
                movieId: movieId
            )
            return ShareButtonRootView(viewModel: viewModel)
        }

        public static func mock() -> Builder {
            Builder(shareClient: .fixtureData)
        }
    }
}
