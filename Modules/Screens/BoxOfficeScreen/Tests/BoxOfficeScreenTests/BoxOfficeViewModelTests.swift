//
//  BoxOfficeViewModelTests.swift
//  BoxOfficeScreenTests
//
//  Created by Stephane Magne
//

import Testing
@testable import BoxOfficeScreen
import MovieDomainInterface

@Suite("BoxOfficeViewModel Tests")
struct BoxOfficeViewModelTests {

    @MainActor
    @Test("Initial state is idle with empty movies")
    func initialState() {
        let viewModel = BoxOfficeViewModel(
            movieRepository: .mock(),
            imageBaseURL: URL(string: "https://example.com")!
        )

        #expect(viewModel.viewState.loadState == .idle)
        #expect(viewModel.viewState.movies.isEmpty)
        #expect(viewModel.viewState.lastUpdated == nil)
    }

    @MainActor
    @Test("handleOnAppear loads movies")
    func handleOnAppearLoadsMovies() async throws {
        let expectedMovies = PaginatedMovies.fixture

        let viewModel = BoxOfficeViewModel(
            movieRepository: .mock(
                nowPlaying: { _ in expectedMovies }
            ),
            imageBaseURL: URL(string: "https://example.com")!
        )

        viewModel.handleOnAppear()

        // Allow async task to complete
        try await Task.sleep(for: .milliseconds(100))

        #expect(viewModel.viewState.movies.count == 3)
        #expect(viewModel.viewState.loadState == .idle)
        #expect(viewModel.viewState.lastUpdated != nil)
    }

    @MainActor
    @Test("handleOnAppear only loads once")
    func handleOnAppearOnlyOnce() async throws {
        var loadCount = 0
        let viewModel = BoxOfficeViewModel(
            movieRepository: .mock(
                nowPlaying: { _ in
                    loadCount += 1
                    return .fixture
                }
            ),
            imageBaseURL: URL(string: "https://example.com")!
        )

        viewModel.handleOnAppear()
        viewModel.handleOnAppear()
        viewModel.handleOnAppear()

        try await Task.sleep(for: .milliseconds(100))

        #expect(loadCount == 1)
    }

    @MainActor
    @Test("Error state is set when loading fails")
    func errorStateOnFailure() async throws {
        let viewModel = BoxOfficeViewModel(
            movieRepository: .mock(
                nowPlaying: { _ in
                    throw TestError.networkFailed
                }
            ),
            imageBaseURL: URL(string: "https://example.com")!
        )

        viewModel.handleOnAppear()

        try await Task.sleep(for: .milliseconds(100))

        if case .error = viewModel.viewState.loadState {
            // Expected
        } else {
            Issue.record("Expected error state")
        }
    }

    @MainActor
    @Test("Movie card view state maps correctly from domain")
    func movieCardViewStateMapping() async throws {
        let movie = Movie.fixture

        let viewModel = BoxOfficeViewModel(
            movieRepository: .mock(
                nowPlaying: { _ in
                    PaginatedMovies(items: [movie], page: 1, totalPages: 1, totalResults: 1)
                }
            ),
            imageBaseURL: URL(string: "https://example.com")!
        )

        viewModel.handleOnAppear()
        try await Task.sleep(for: .milliseconds(100))

        let cardState = viewModel.viewState.movies.first
        #expect(cardState?.id == movie.id)
        #expect(cardState?.title == movie.title)
        #expect(cardState?.releaseYear == movie.releaseYear)
        #expect(cardState?.rating == movie.formattedVoteAverage)
        #expect(cardState?.posterPath == movie.posterPath)
    }

    @MainActor
    @Test("handleRefresh reloads movies")
    func handleRefreshReloadsMovies() async throws {
        var loadCount = 0
        let viewModel = BoxOfficeViewModel(
            movieRepository: .mock(
                nowPlaying: { _ in
                    loadCount += 1
                    return .fixture
                }
            ),
            imageBaseURL: URL(string: "https://example.com")!
        )

        viewModel.handleOnAppear()
        try await Task.sleep(for: .milliseconds(100))

        await viewModel.handleRefresh()

        #expect(loadCount == 2)
    }
}

// MARK: - Test Helpers

private enum TestError: Error {
    case networkFailed
}
