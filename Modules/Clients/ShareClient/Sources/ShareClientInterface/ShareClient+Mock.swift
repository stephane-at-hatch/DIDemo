//
//  ShareClient+Mock.swift
//  ShareClientInterface
//
//  Created by Stephane Magne
//

import Foundation

extension ShareClient {

    /// Creates a mock client for testing and previews.
    public static func mock(
        shareMovie: (@Sendable (_ title: String, _ overview: String, _ movieId: Int) -> ShareContent)? = nil
    ) -> ShareClient {
        ShareClient(
            shareMovie: shareMovie ?? { title, _, _ in
                ShareContent(text: "Check out '\(title)'!", url: nil)
            }
        )
    }

    /// Creates a fixture client that returns realistic share content.
    public static var fixtureData: ShareClient {
        ShareClient(
            shareMovie: { title, overview, movieId in
                let truncated = String(overview.prefix(100))
                return ShareContent(
                    text: "Check out '\(title)' on TMDB!\n\n\(truncated)...",
                    url: URL(string: "https://www.themoviedb.org/movie/\(movieId)")
                )
            }
        )
    }
}
