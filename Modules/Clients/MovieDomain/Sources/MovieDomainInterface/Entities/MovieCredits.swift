//
//  MovieCredits.swift
//  MovieDomainInterface
//
//  Created by Stephane Magne
//

import Foundation

/// Credits (cast and crew) for a movie.
public struct MovieCredits: Sendable, Equatable {
    public let movieId: Int
    public let cast: [CastMember]
    public let crew: [CrewMember]

    public init(movieId: Int, cast: [CastMember], crew: [CrewMember]) {
        self.movieId = movieId
        self.cast = cast
        self.crew = crew
    }

    /// Returns the director(s) of the movie.
    public var directors: [CrewMember] {
        crew.filter { $0.job.lowercased() == "director" }
    }

    /// Returns the top-billed cast members.
    /// - Parameter limit: Maximum number of cast members to return
    public func topCast(limit: Int = 10) -> [CastMember] {
        Array(cast.prefix(limit))
    }
}

/// A cast member (actor) in a movie.
public struct CastMember: Sendable, Equatable, Identifiable, Hashable {
    public let id: Int
    public let name: String
    public let character: String
    public let profilePath: String?
    public let order: Int

    public init(
        id: Int,
        name: String,
        character: String,
        profilePath: String?,
        order: Int
    ) {
        self.id = id
        self.name = name
        self.character = character
        self.profilePath = profilePath
        self.order = order
    }
}

/// A crew member in a movie.
public struct CrewMember: Sendable, Equatable, Identifiable, Hashable {
    public let id: Int
    public let name: String
    public let department: String
    public let job: String
    public let profilePath: String?

    public init(
        id: Int,
        name: String,
        department: String,
        job: String,
        profilePath: String?
    ) {
        self.id = id
        self.name = name
        self.department = department
        self.job = job
        self.profilePath = profilePath
    }
}
