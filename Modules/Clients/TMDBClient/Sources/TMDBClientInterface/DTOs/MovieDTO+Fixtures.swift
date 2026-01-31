//
//  MovieDTO+Fixtures.swift
//  TMDBClientInterface
//
//  Created by Stephane Magne
//

import Foundation

// MARK: - Preview/Test Fixtures

extension MovieListItemDTO {

    /// A sample movie for previews and tests.
    public static var fixture: MovieListItemDTO {
        MovieListItemDTO(
            id: 550,
            title: "Fight Club",
            originalTitle: "Fight Club",
            overview: "A ticking-Loss time bomb of a movie about a depressed yuppie who finds release through underground fight clubs.",
            posterPath: "/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg",
            backdropPath: "/hZkgoQYus5vegHoetLkCJzb17zJ.jpg",
            releaseDate: "1999-10-15",
            voteAverage: 8.4,
            voteCount: 29696,
            popularity: 134.463,
            adult: false,
            video: false,
            genreIds: [18, 53, 35],
            originalLanguage: "en"
        )
    }

    /// A second sample movie for previews and tests.
    public static var fixture2: MovieListItemDTO {
        MovieListItemDTO(
            id: 27205,
            title: "Inception",
            originalTitle: "Inception",
            overview: "A thief who steals corporate secrets through dream-sharing technology is given the task of planting an idea into the mind of a CEO.",
            posterPath: "/oYuLEt3zVCKq57qu2F8dT7NIa6f.jpg",
            backdropPath: "/8ZTVqvKDQ8emSGUEMjsS4yHAwrp.jpg",
            releaseDate: "2010-07-16",
            voteAverage: 8.4,
            voteCount: 35421,
            popularity: 98.234,
            adult: false,
            video: false,
            genreIds: [28, 878, 12],
            originalLanguage: "en"
        )
    }

    /// A collection of sample movies for list previews.
    public static var fixtures: [MovieListItemDTO] {
        [.fixture, .fixture2]
    }
}

extension MovieDetailDTO {

    /// A sample detailed movie for previews and tests.
    public static var fixture: MovieDetailDTO {
        MovieDetailDTO(
            id: 550,
            title: "Fight Club",
            originalTitle: "Fight Club",
            overview: "A ticking-Loss time bomb of a movie about a depressed yuppie who finds release through underground fight clubs.",
            posterPath: "/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg",
            backdropPath: "/hZkgoQYus5vegHoetLkCJzb17zJ.jpg",
            releaseDate: "1999-10-15",
            voteAverage: 8.4,
            voteCount: 29696,
            popularity: 134.463,
            adult: false,
            video: false,
            originalLanguage: "en",
            budget: 63_000_000,
            revenue: 100_853_753,
            runtime: 139,
            status: "Released",
            tagline: "Mischief. Mayhem. Soap.",
            homepage: "http://www.foxmovies.com/movies/fight-club",
            imdbId: "tt0137523",
            genres: [
                GenreDTO(id: 18, name: "Drama"),
                GenreDTO(id: 53, name: "Thriller"),
                GenreDTO(id: 35, name: "Comedy")
            ],
            productionCompanies: [
                ProductionCompanyDTO(
                    id: 508,
                    name: "Regency Enterprises",
                    logoPath: "/7PzJdsLGlR7oW4J0J5Xcd0pHGRg.png",
                    originCountry: "US"
                )
            ],
            productionCountries: [
                ProductionCountryDTO(iso3166_1: "US", name: "United States of America")
            ],
            spokenLanguages: [
                SpokenLanguageDTO(iso639_1: "en", name: "English", englishName: "English")
            ]
        )
    }
}

extension MovieListResponseDTO {

    /// A sample paginated response for previews and tests.
    public static var fixture: MovieListResponseDTO {
        MovieListResponseDTO(
            page: 1,
            results: MovieListItemDTO.fixtures,
            totalPages: 10,
            totalResults: 200
        )
    }
}

extension CreditsDTO {

    /// A sample credits response for previews and tests.
    public static var fixture: CreditsDTO {
        CreditsDTO(
            id: 550,
            cast: [
                CastMemberDTO(
                    id: 819,
                    name: "Edward Norton",
                    originalName: "Edward Norton",
                    character: "The Narrator",
                    profilePath: "/5XBzD5WuTyVQZeS4II6gs1nn5P6.jpg",
                    order: 0,
                    castId: 4,
                    creditId: "52fe4250c3a36847f80149f3",
                    gender: 2,
                    knownForDepartment: "Acting",
                    popularity: 26.99,
                    adult: false
                ),
                CastMemberDTO(
                    id: 287,
                    name: "Brad Pitt",
                    originalName: "Brad Pitt",
                    character: "Tyler Durden",
                    profilePath: "/cckcYc2v0yh1tc9QjRelptcOBko.jpg",
                    order: 1,
                    castId: 5,
                    creditId: "52fe4250c3a36847f80149f7",
                    gender: 2,
                    knownForDepartment: "Acting",
                    popularity: 35.23,
                    adult: false
                )
            ],
            crew: [
                CrewMemberDTO(
                    id: 7467,
                    name: "David Fincher",
                    originalName: "David Fincher",
                    department: "Directing",
                    job: "Director",
                    profilePath: "/tpEczFclQZeKAiCeKZZ0adRvtfz.jpg",
                    creditId: "52fe4250c3a36847f8014a05",
                    gender: 2,
                    knownForDepartment: "Directing",
                    popularity: 18.67,
                    adult: false
                )
            ]
        )
    }
}
