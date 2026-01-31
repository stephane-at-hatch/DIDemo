//
//  TMDBConfiguration.swift
//  TMDBClientInterface
//
//  Created by Stephane Magne
//

import Foundation

/// Configuration for the TMDB API client.
public struct TMDBConfiguration: Sendable {

    /// The API read access token (v4 auth style, used as Bearer token).
    public let apiReadAccessToken: String

    /// The base URL for API requests.
    public let apiBaseURL: URL

    /// The base URL for image assets.
    public let imageBaseURL: URL

    /// The default region for localized content (ISO 3166-1 code, e.g., "US").
    public let region: String

    /// The default language for content (ISO 639-1 code, e.g., "en-US").
    public let language: String

    public init(
        apiReadAccessToken: String,
        apiBaseURL: URL = URL(string: "https://api.themoviedb.org/3")!,
        imageBaseURL: URL = URL(string: "https://image.tmdb.org/t/p")!,
        region: String = "US",
        language: String = "en-US"
    ) {
        self.apiReadAccessToken = apiReadAccessToken
        self.apiBaseURL = apiBaseURL
        self.imageBaseURL = imageBaseURL
        self.region = region
        self.language = language
    }
}
