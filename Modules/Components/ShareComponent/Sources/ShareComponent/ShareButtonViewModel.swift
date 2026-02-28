//
//  ShareButtonViewModel.swift
//  ShareComponent
//
//  Created by Stephane Magne
//

import Foundation
import ShareClientInterface
import ShareComponentViews

@MainActor @Observable
public final class ShareButtonViewModel {

    // MARK: - Dependencies

    private let shareClient: ShareClient

    // MARK: - Private State

    private let title: String
    private let overview: String
    private let movieId: Int

    // MARK: - Computed ViewState

    public var viewState: ShareButtonViewState {
        let content = shareClient.shareMovie(title, overview, movieId)
        return ShareButtonViewState(
            title: title,
            shareContent: ShareContentViewState(
                text: content.text,
                url: content.url
            )
        )
    }

    // MARK: - Init

    convenience init(
        dependencies: ShareComponent.Dependencies,
        title: String,
        overview: String,
        movieId: Int
    ) {
        self.init(
            shareClient: dependencies.shareClient,
            title: title,
            overview: overview,
            movieId: movieId
        )
    }

    public init(
        shareClient: ShareClient,
        title: String,
        overview: String,
        movieId: Int
    ) {
        self.shareClient = shareClient
        self.title = title
        self.overview = overview
        self.movieId = movieId
    }
    
    // MARK: - API
 
    func missingShareContent(_ title: String) {
        logger.error("Error: Missing share content for movie title: \(title)")
    }
}
