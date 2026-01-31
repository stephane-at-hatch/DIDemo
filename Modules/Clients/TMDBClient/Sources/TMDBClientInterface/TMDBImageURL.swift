//
//  TMDBImageURL.swift
//  TMDBClientInterface
//
//  Created by Stephane Magne
//

import Foundation

/// Helper for constructing TMDB image URLs.
public enum TMDBImageURL {

    /// Constructs a full poster image URL.
    /// - Parameters:
    ///   - path: The poster path from the API (e.g., "/abc123.jpg")
    ///   - size: The desired poster size
    ///   - baseURL: The image base URL from configuration
    /// - Returns: The full URL to the poster image, or nil if path is nil/empty
    public static func poster(
        path: String?,
        size: TMDBPosterSize = .w342,
        baseURL: URL
    ) -> URL? {
        guard let path, !path.isEmpty else { return nil }
        return baseURL
            .appendingPathComponent(size.rawValue)
            .appendingPathComponent(path)
    }

    /// Constructs a full backdrop image URL.
    /// - Parameters:
    ///   - path: The backdrop path from the API (e.g., "/xyz789.jpg")
    ///   - size: The desired backdrop size
    ///   - baseURL: The image base URL from configuration
    /// - Returns: The full URL to the backdrop image, or nil if path is nil/empty
    public static func backdrop(
        path: String?,
        size: TMDBBackdropSize = .w780,
        baseURL: URL
    ) -> URL? {
        guard let path, !path.isEmpty else { return nil }
        return baseURL
            .appendingPathComponent(size.rawValue)
            .appendingPathComponent(path)
    }

    /// Constructs a full profile image URL.
    /// - Parameters:
    ///   - path: The profile path from the API (e.g., "/def456.jpg")
    ///   - size: The desired profile size
    ///   - baseURL: The image base URL from configuration
    /// - Returns: The full URL to the profile image, or nil if path is nil/empty
    public static func profile(
        path: String?,
        size: TMDBProfileSize = .w185,
        baseURL: URL
    ) -> URL? {
        guard let path, !path.isEmpty else { return nil }
        return baseURL
            .appendingPathComponent(size.rawValue)
            .appendingPathComponent(path)
    }
}
