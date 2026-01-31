//
//  MovieDomainTests.swift
//  MovieDomainTests
//
//  Created by Stephane Magne
//

import Testing
@testable import MovieDomain
import MovieDomainInterface
import TMDBClientInterface

@Suite("MovieDomain Tests")
struct MovieDomainTests {

    // MARK: - Repository Tests

    @Test("Mock repository can be configured with custom closures")
    func mockRepositoryWithCustomClosures() async throws {
        let expectedMovies = PaginatedMovies.fixture

        let repository = MovieRepository.mock(
            nowPlaying: { _ in expectedMovies }
        )

        let result = try await repository.nowPlaying(1)

        #expect(result == expectedMovies)
        #expect(result.items.count == 3)
    }

    @Test("Fixture data repository returns fixture data")
    func fixtureDataRepository() async throws {
        let repository = MovieRepository.fixtureData

        let nowPlaying = try await repository.nowPlaying(1)
        let details = try await repository.details(550)
        let credits = try await repository.credits(550)

        #expect(nowPlaying.items.count == 3)
        #expect(details.title == "Fight Club")
        #expect(credits.cast.count == 3)
    }

    // MARK: - Entity Tests

    @Test("Movie release year is formatted correctly")
    func movieReleaseYear() {
        let movie = Movie.fixture

        #expect(movie.releaseYear == "1999")
    }

    @Test("Movie rating is formatted correctly")
    func movieRatingFormat() {
        let movie = Movie.fixture

        #expect(movie.formattedRating == "84%")
        #expect(movie.formattedVoteAverage == "8.4")
    }

    @Test("MovieDetails runtime is formatted correctly")
    func movieDetailsRuntime() {
        let details = MovieDetails.fixture

        #expect(details.formattedRuntime == "2h 19m")
    }

    @Test("MovieDetails budget and revenue are formatted correctly")
    func movieDetailsBudgetRevenue() {
        let details = MovieDetails.fixture

        #expect(details.formattedBudget == "$63,000,000")
        #expect(details.formattedRevenue == "$100,853,753")
    }

    @Test("MovieCredits directors are extracted correctly")
    func movieCreditsDirectors() {
        let credits = MovieCredits.fixture

        let directors = credits.directors

        #expect(directors.count == 1)
        #expect(directors.first?.name == "David Fincher")
    }

    @Test("MovieCredits top cast respects limit")
    func movieCreditsTopCast() {
        let credits = MovieCredits.fixture

        let top2 = credits.topCast(limit: 2)

        #expect(top2.count == 2)
        #expect(top2[0].name == "Edward Norton")
        #expect(top2[1].name == "Brad Pitt")
    }

    // MARK: - Pagination Tests

    @Test("PaginatedResult hasMorePages works correctly")
    func paginatedResultHasMorePages() {
        let page1 = PaginatedMovies(items: [], page: 1, totalPages: 5, totalResults: 100)
        let lastPage = PaginatedMovies(items: [], page: 5, totalPages: 5, totalResults: 100)

        #expect(page1.hasMorePages == true)
        #expect(page1.nextPage == 2)
        #expect(lastPage.hasMorePages == false)
        #expect(lastPage.nextPage == nil)
    }

    // MARK: - Mapping Tests

    @Test("MovieListItemDTO maps to Movie correctly")
    func movieListItemMapping() {
        let dto = MovieListItemDTO(
            id: 123,
            title: "Test Movie",
            originalTitle: "Test Movie Original",
            overview: "A test movie",
            posterPath: "/poster.jpg",
            backdropPath: "/backdrop.jpg",
            releaseDate: "2024-06-15",
            voteAverage: 7.5,
            voteCount: 1000,
            popularity: 50.0,
            adult: false,
            video: false,
            genreIds: [28, 12],
            originalLanguage: "en"
        )

        let movie = dto.toDomain()

        #expect(movie.id == 123)
        #expect(movie.title == "Test Movie")
        #expect(movie.posterPath == "/poster.jpg")
        #expect(movie.releaseYear == "2024")
        #expect(movie.genreIds == [28, 12])
    }

    @Test("MovieDetailDTO maps to MovieDetails correctly")
    func movieDetailMapping() {
        let dto = MovieDetailDTO(
            id: 456,
            title: "Detailed Movie",
            originalTitle: "Detailed Movie Original",
            overview: "A detailed test movie",
            posterPath: "/poster.jpg",
            backdropPath: "/backdrop.jpg",
            releaseDate: "2023-12-25",
            voteAverage: 8.0,
            voteCount: 5000,
            popularity: 100.0,
            adult: false,
            video: false,
            originalLanguage: "en",
            budget: 50_000_000,
            revenue: 200_000_000,
            runtime: 150,
            status: "Released",
            tagline: "A great tagline",
            homepage: "https://example.com",
            imdbId: "tt1234567",
            genres: [GenreDTO(id: 28, name: "Action")],
            productionCompanies: [],
            productionCountries: [],
            spokenLanguages: []
        )

        let details = dto.toDomain()

        #expect(details.id == 456)
        #expect(details.title == "Detailed Movie")
        #expect(details.tagline == "A great tagline")
        #expect(details.runtime == 150)
        #expect(details.formattedRuntime == "2h 30m")
        #expect(details.genres.count == 1)
        #expect(details.genres.first?.name == "Action")
    }
}
