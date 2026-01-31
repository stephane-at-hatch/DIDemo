//
//  TMDBClientTests.swift
//  TMDBClientTests
//
//  Created by Stephane Magne
//

import Testing
@testable import TMDBClient
import TMDBClientInterface

@Suite("TMDBClient Tests")
struct TMDBClientTests {

    @Test("Mock client can be configured with custom closures")
    func mockClientWithCustomClosures() async throws {
        let expectedResponse = MovieListResponseDTO.fixture

        let client = TMDBClient.mock(
            nowPlaying: { _ in expectedResponse }
        )

        let response = try await client.nowPlaying(1)

        #expect(response == expectedResponse)
        #expect(response.results.count == 2)
    }

    @Test("Mock client throws for unimplemented methods")
    func mockClientThrowsForUnimplemented() async {
        let client = TMDBClient.mock()

        await #expect(throws: Error.self) {
            _ = try await client.popular(1)
        }
    }

    @Test("Image URL builder constructs correct poster URL")
    func posterURLConstruction() {
        let baseURL = URL(string: "https://image.tmdb.org/t/p")!
        let posterPath = "/abc123.jpg"

        let url = TMDBImageURL.poster(path: posterPath, size: .w342, baseURL: baseURL)

        #expect(url?.absoluteString == "https://image.tmdb.org/t/p/w342/abc123.jpg")
    }

    @Test("Image URL builder returns nil for empty path")
    func posterURLNilForEmptyPath() {
        let baseURL = URL(string: "https://image.tmdb.org/t/p")!

        let url1 = TMDBImageURL.poster(path: nil, baseURL: baseURL)
        let url2 = TMDBImageURL.poster(path: "", baseURL: baseURL)

        #expect(url1 == nil)
        #expect(url2 == nil)
    }

    @Test("Configuration has sensible defaults")
    func configurationDefaults() {
        let config = TMDBConfiguration(apiReadAccessToken: "test-token")

        #expect(config.apiBaseURL.absoluteString == "https://api.themoviedb.org/3")
        #expect(config.imageBaseURL.absoluteString == "https://image.tmdb.org/t/p")
        #expect(config.region == "US")
        #expect(config.language == "en-US")
    }

    @Test("MovieListItemDTO decodes from JSON")
    func movieListItemDecoding() throws {
        let json = """
        {
            "id": 550,
            "title": "Fight Club",
            "original_title": "Fight Club",
            "overview": "A movie about fight clubs.",
            "poster_path": "/poster.jpg",
            "backdrop_path": "/backdrop.jpg",
            "release_date": "1999-10-15",
            "vote_average": 8.4,
            "vote_count": 29696,
            "popularity": 134.463,
            "adult": false,
            "video": false,
            "genre_ids": [18, 53],
            "original_language": "en"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let movie = try decoder.decode(MovieListItemDTO.self, from: json)

        #expect(movie.id == 550)
        #expect(movie.title == "Fight Club")
        #expect(movie.posterPath == "/poster.jpg")
        #expect(movie.genreIds == [18, 53])
    }
}
