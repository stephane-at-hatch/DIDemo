//
//  Movie+Fixtures.swift
//  MovieDomainInterface
//
//  Created by Stephane Magne
//

import Foundation

// MARK: - Preview/Test Fixtures

extension Movie {

    /// A sample movie for previews and tests.
    public static var fixture: Movie {
        Movie(
            id: 550,
            title: "Fight Club",
            overview: "A depressed man suffering from insomnia meets a strange soap salesman and soon finds himself living in his squalid house after his inefficient apartment burns down.",
            posterPath: "/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg",
            backdropPath: "/hZkgoQYus5vegHoetLkCJzb17zJ.jpg",
            releaseDate: DateComponents(calendar: .current, year: 1999, month: 10, day: 15).date,
            voteAverage: 8.4,
            voteCount: 29696,
            popularity: 134.463,
            genreIds: [18, 53, 35]
        )
    }

    /// A second sample movie for previews and tests.
    public static var fixture2: Movie {
        Movie(
            id: 27205,
            title: "Inception",
            overview: "A thief who steals corporate secrets through dream-sharing technology is given the task of planting an idea into the mind of a CEO.",
            posterPath: "/oYuLEt3zVCKq57qu2F8dT7NIa6f.jpg",
            backdropPath: "/8ZTVqvKDQ8emSGUEMjsS4yHAwrp.jpg",
            releaseDate: DateComponents(calendar: .current, year: 2010, month: 7, day: 16).date,
            voteAverage: 8.4,
            voteCount: 35421,
            popularity: 98.234,
            genreIds: [28, 878, 12]
        )
    }

    /// A third sample movie for previews and tests.
    public static var fixture3: Movie {
        Movie(
            id: 238,
            title: "The Godfather",
            overview: "The aging patriarch of an organized crime dynasty transfers control to his reluctant son.",
            posterPath: "/3bhkrj58Vtu7enYsRolD1fZdja1.jpg",
            backdropPath: "/tmU7GeKVybMWFButWEGl2M4GeiP.jpg",
            releaseDate: DateComponents(calendar: .current, year: 1972, month: 3, day: 14).date,
            voteAverage: 8.7,
            voteCount: 19500,
            popularity: 112.456,
            genreIds: [18, 80]
        )
    }

    /// A collection of sample movies for list previews.
    public static var fixtures: [Movie] {
        [.fixture, .fixture2, .fixture3]
    }
}

extension MovieDetails {

    /// A sample movie details for previews and tests.
    public static var fixture: MovieDetails {
        MovieDetails(
            id: 550,
            title: "Fight Club",
            overview: "A depressed man suffering from insomnia meets a strange soap salesman and soon finds himself living in his squalid house after his inefficient apartment burns down.",
            tagline: "Mischief. Mayhem. Soap.",
            posterPath: "/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg",
            backdropPath: "/hZkgoQYus5vegHoetLkCJzb17zJ.jpg",
            releaseDate: DateComponents(calendar: .current, year: 1999, month: 10, day: 15).date,
            voteAverage: 8.4,
            voteCount: 29696,
            popularity: 134.463,
            runtime: 139,
            budget: 63_000_000,
            revenue: 100_853_753,
            status: "Released",
            genres: [
                Genre(id: 18, name: "Drama"),
                Genre(id: 53, name: "Thriller"),
                Genre(id: 35, name: "Comedy")
            ],
            homepage: "http://www.foxmovies.com/movies/fight-club",
            imdbId: "tt0137523"
        )
    }
}

extension MovieCredits {

    /// A sample credits for previews and tests.
    public static var fixture: MovieCredits {
        MovieCredits(
            movieId: 550,
            cast: [
                CastMember(
                    id: 819,
                    name: "Edward Norton",
                    character: "The Narrator",
                    profilePath: "/5XBzD5WuTyVQZeS4II6gs1nn5P6.jpg",
                    order: 0
                ),
                CastMember(
                    id: 287,
                    name: "Brad Pitt",
                    character: "Tyler Durden",
                    profilePath: "/cckcYc2v0yh1tc9QjRelptcOBko.jpg",
                    order: 1
                ),
                CastMember(
                    id: 1283,
                    name: "Helena Bonham Carter",
                    character: "Marla Singer",
                    profilePath: "/DDeITcCpnBd0CkAIRPhggy9bt5.jpg",
                    order: 2
                )
            ],
            crew: [
                CrewMember(
                    id: 7467,
                    name: "David Fincher",
                    department: "Directing",
                    job: "Director",
                    profilePath: "/tpEczFclQZeKAiCeKZZ0adRvtfz.jpg"
                ),
                CrewMember(
                    id: 7468,
                    name: "Jim Uhls",
                    department: "Writing",
                    job: "Screenplay",
                    profilePath: nil
                )
            ]
        )
    }
}

extension PaginatedMovies {

    /// A sample paginated result for previews and tests.
    public static var fixture: PaginatedMovies {
        PaginatedMovies(
            items: Movie.fixtures,
            page: 1,
            totalPages: 10,
            totalResults: 200
        )
    }
}
