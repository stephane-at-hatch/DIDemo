//
//  CreditsDTO+Mapping.swift
//  MovieDomain
//
//  Created by Stephane Magne
//

import Foundation
import MovieDomainInterface
import TMDBClientInterface

extension CreditsDTO {

    func toDomain() -> MovieCredits {
        MovieCredits(
            movieId: id,
            cast: cast.map { $0.toDomain() },
            crew: crew.map { $0.toDomain() }
        )
    }
}

extension CastMemberDTO {

    func toDomain() -> CastMember {
        CastMember(
            id: id,
            name: name,
            character: character,
            profilePath: profilePath,
            order: order
        )
    }
}

extension CrewMemberDTO {

    func toDomain() -> CrewMember {
        CrewMember(
            id: id,
            name: name,
            department: department,
            job: job,
            profilePath: profilePath
        )
    }
}
