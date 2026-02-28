//
//  BoxOfficeView.swift
//  BoxOfficeScreenViews
//
//  Created by Stephane Magne
//

import SwiftUI

/// The main Box Office view displaying currently playing movies.
public struct BoxOfficeView<ShareButton: View>: View {
    let state: BoxOfficeViewState
    let imageBaseURL: URL
    let shareButton: (MovieCardViewState) -> ShareButton
    let onAction: (BoxOfficeAction) -> Void

    public init(
        state: BoxOfficeViewState,
        imageBaseURL: URL,
        shareButton: @escaping (MovieCardViewState) -> ShareButton,
        onAction: @escaping (BoxOfficeAction) -> Void
    ) {
        self.state = state
        self.imageBaseURL = imageBaseURL
        self.shareButton = shareButton
        self.onAction = onAction
    }

    public var body: some View {
        content
            .navigationTitle("Box Office")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if state.loadState == .refreshing {
                        ProgressView()
                    }
                }
            }
        .onAppear {
            onAction(.onAppear)
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch state.loadState {
        case .loading where state.movies.isEmpty:
            loadingView
        case .error(let message) where state.movies.isEmpty:
            errorView(message: message)
        default:
            movieList
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading movies...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Error

    private func errorView(message: String) -> some View {
        ContentUnavailableView {
            Label("Unable to Load", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            Button("Try Again") {
                onAction(.retryTapped)
            }
            .buttonStyle(.bordered)
        }
    }

    // MARK: - Movie List

    private var movieList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if let lastUpdated = state.lastUpdated {
                    Text("Updated \(lastUpdated)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                }

                ForEach(state.movies) { movie in
                    HStack(alignment: .top) {
                        MovieCardView(
                            state: movie,
                            posterURL: posterURL(for: movie.posterPath),
                            onAction: { action in
                                switch action {
                                case .tapped:
                                    onAction(.movieTapped(movieId: movie.id))
                                }
                            }
                        )
                        shareButton(movie)
                    }
                    .padding(.horizontal)
                }

                if state.loadState.isLoading && !state.movies.isEmpty {
                    ProgressView()
                        .padding()
                }
            }
            .padding(.vertical)
        }
        .refreshable {
            onAction(.refresh)
        }
    }

    // MARK: - Helpers

    private func posterURL(for path: String?) -> URL? {
        guard let path else { return nil }
        return imageBaseURL
            .appendingPathComponent("w185")
            .appendingPathComponent(path)
    }
}

// MARK: - Preview

#Preview("Loaded") {
    BoxOfficeView(
        state: BoxOfficeViewState(
            loadState: .idle,
            movies: [
                MovieCardViewState(
                    id: 550,
                    title: "Fight Club",
                    releaseYear: "1999",
                    rating: "8.4",
                    posterPath: "/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg",
                    overview: "A depressed man suffering from insomnia meets a strange soap salesman."
                ),
                MovieCardViewState(
                    id: 27205,
                    title: "Inception",
                    releaseYear: "2010",
                    rating: "8.4",
                    posterPath: "/oYuLEt3zVCKq57qu2F8dT7NIa6f.jpg",
                    overview: "A thief who steals corporate secrets through dream-sharing technology."
                )
            ],
            lastUpdated: "Just now"
        ),
        imageBaseURL: URL(string: "https://image.tmdb.org/t/p")!,
        shareButton: { _ in EmptyView() },
        onAction: { _ in }
    )
}

#Preview("Loading") {
    BoxOfficeView(
        state: BoxOfficeViewState(
            loadState: .loading,
            movies: [],
            lastUpdated: nil
        ),
        imageBaseURL: URL(string: "https://image.tmdb.org/t/p")!,
        shareButton: { _ in EmptyView() },
        onAction: { _ in }
    )
}

#Preview("Error") {
    BoxOfficeView(
        state: BoxOfficeViewState(
            loadState: .error(message: "Network connection unavailable. Please check your internet and try again."),
            movies: [],
            lastUpdated: nil
        ),
        imageBaseURL: URL(string: "https://image.tmdb.org/t/p")!,
        shareButton: { _ in EmptyView() },
        onAction: { _ in }
    )
}
