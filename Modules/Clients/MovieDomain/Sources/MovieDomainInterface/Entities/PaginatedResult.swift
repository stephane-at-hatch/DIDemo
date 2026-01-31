//
//  PaginatedResult.swift
//  MovieDomainInterface
//
//  Created by Stephane Magne
//

import Foundation

/// A paginated result containing items and pagination metadata.
public struct PaginatedResult<T: Sendable & Equatable>: Sendable, Equatable {
    public let items: [T]
    public let page: Int
    public let totalPages: Int
    public let totalResults: Int

    public init(items: [T], page: Int, totalPages: Int, totalResults: Int) {
        self.items = items
        self.page = page
        self.totalPages = totalPages
        self.totalResults = totalResults
    }

    /// Whether there are more pages available.
    public var hasMorePages: Bool {
        page < totalPages
    }

    /// The next page number, or nil if this is the last page.
    public var nextPage: Int? {
        hasMorePages ? page + 1 : nil
    }
}

/// Type alias for paginated movie results.
public typealias PaginatedMovies = PaginatedResult<Movie>
