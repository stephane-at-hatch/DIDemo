//
//  PaginatedResponseDTO.swift
//  TMDBClientInterface
//
//  Created by Stephane Magne
//

import Foundation

/// A paginated response wrapper for list endpoints.
public struct PaginatedResponseDTO<T: Codable & Sendable & Equatable>: Codable, Sendable, Equatable {
    public let page: Int
    public let results: [T]
    public let totalPages: Int
    public let totalResults: Int

    public init(page: Int, results: [T], totalPages: Int, totalResults: Int) {
        self.page = page
        self.results = results
        self.totalPages = totalPages
        self.totalResults = totalResults
    }

    private enum CodingKeys: String, CodingKey {
        case page
        case results
        case totalPages = "total_pages"
        case totalResults = "total_results"
    }
}

/// Type alias for paginated movie list responses.
public typealias MovieListResponseDTO = PaginatedResponseDTO<MovieListItemDTO>
