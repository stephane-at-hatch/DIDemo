//
//  CreditsDTO.swift
//  TMDBClientInterface
//
//  Created by Stephane Magne
//

import Foundation

/// Credits (cast and crew) for a movie.
public struct CreditsDTO: Codable, Sendable, Equatable {
    public let id: Int
    public let cast: [CastMemberDTO]
    public let crew: [CrewMemberDTO]

    public init(id: Int, cast: [CastMemberDTO], crew: [CrewMemberDTO]) {
        self.id = id
        self.cast = cast
        self.crew = crew
    }
}

public struct CastMemberDTO: Codable, Sendable, Equatable, Identifiable {
    public let id: Int
    public let name: String
    public let originalName: String
    public let character: String
    public let profilePath: String?
    public let order: Int
    public let castId: Int?
    public let creditId: String
    public let gender: Int?
    public let knownForDepartment: String?
    public let popularity: Double
    public let adult: Bool

    public init(
        id: Int,
        name: String,
        originalName: String,
        character: String,
        profilePath: String?,
        order: Int,
        castId: Int?,
        creditId: String,
        gender: Int?,
        knownForDepartment: String?,
        popularity: Double,
        adult: Bool
    ) {
        self.id = id
        self.name = name
        self.originalName = originalName
        self.character = character
        self.profilePath = profilePath
        self.order = order
        self.castId = castId
        self.creditId = creditId
        self.gender = gender
        self.knownForDepartment = knownForDepartment
        self.popularity = popularity
        self.adult = adult
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case originalName = "original_name"
        case character
        case profilePath = "profile_path"
        case order
        case castId = "cast_id"
        case creditId = "credit_id"
        case gender
        case knownForDepartment = "known_for_department"
        case popularity
        case adult
    }
}

public struct CrewMemberDTO: Codable, Sendable, Equatable, Identifiable {
    public let id: Int
    public let name: String
    public let originalName: String
    public let department: String
    public let job: String
    public let profilePath: String?
    public let creditId: String
    public let gender: Int?
    public let knownForDepartment: String?
    public let popularity: Double
    public let adult: Bool

    public init(
        id: Int,
        name: String,
        originalName: String,
        department: String,
        job: String,
        profilePath: String?,
        creditId: String,
        gender: Int?,
        knownForDepartment: String?,
        popularity: Double,
        adult: Bool
    ) {
        self.id = id
        self.name = name
        self.originalName = originalName
        self.department = department
        self.job = job
        self.profilePath = profilePath
        self.creditId = creditId
        self.gender = gender
        self.knownForDepartment = knownForDepartment
        self.popularity = popularity
        self.adult = adult
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case originalName = "original_name"
        case department
        case job
        case profilePath = "profile_path"
        case creditId = "credit_id"
        case gender
        case knownForDepartment = "known_for_department"
        case popularity
        case adult
    }
}
