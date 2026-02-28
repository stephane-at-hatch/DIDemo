//
//  ShareClient.swift
//  ShareClientInterface
//
//  Created by Stephane Magne
//

import Foundation

/// Client for generating shareable content for movies.
///
/// Uses closure-based dependency injection for testability.
public struct ShareClient: Sendable {

    /// Generates share content for a movie.
    /// - Parameters:
    ///   - title: The movie title
    ///   - overview: The movie overview
    ///   - movieId: The TMDB movie ID
    public var shareMovie: @Sendable (_ title: String, _ overview: String, _ movieId: Int) -> ShareContent

    public init(
        shareMovie: @escaping @Sendable (_ title: String, _ overview: String, _ movieId: Int) -> ShareContent
    ) {
        self.shareMovie = shareMovie
    }
}

/// Content ready to share via the system share sheet.
public struct ShareContent: Sendable, Equatable {
    public let text: String
    public let url: URL?

    public init(text: String, url: URL?) {
        self.text = text
        self.url = url
    }
}
