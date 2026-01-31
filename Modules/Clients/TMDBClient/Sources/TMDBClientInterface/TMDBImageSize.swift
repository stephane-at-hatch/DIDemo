//
//  TMDBImageSize.swift
//  TMDBClientInterface
//
//  Created by Stephane Magne
//

import Foundation

/// Available poster image sizes from TMDB CDN.
public enum TMDBPosterSize: String, Sendable, CaseIterable {
    case w92
    case w154
    case w185
    case w342
    case w500
    case w780
    case original
}

/// Available backdrop image sizes from TMDB CDN.
public enum TMDBBackdropSize: String, Sendable, CaseIterable {
    case w300
    case w780
    case w1280
    case original
}

/// Available profile image sizes from TMDB CDN.
public enum TMDBProfileSize: String, Sendable, CaseIterable {
    case w45
    case w185
    case h632
    case original
}
