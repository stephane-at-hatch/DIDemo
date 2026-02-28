//
//  ShareClient+Live.swift
//  ShareClient
//
//  Created by Stephane Magne
//

import Foundation
import ShareClientInterface

public extension ShareClient {

    /// Creates a live client that formats share content with TMDB links.
    static func live() -> ShareClient {
        ShareClient(
            shareMovie: { title, overview, movieId in
                let truncated = String(overview.prefix(140))
                let text = "Check out '\(title)' on TMDB!\n\n\(truncated)..."
                let url = URL(string: "https://www.themoviedb.org/movie/\(movieId)")
                return ShareContent(text: text, url: url)
            }
        )
    }
}
