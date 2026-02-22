//
//  WatchlistView.swift
//  WatchlistScreenViews
//
//  Created by Stephane Magne
//

import SwiftUI

/// The main Watchlist view displaying saved movies.
public struct WatchlistView: View {
    let state: WatchlistViewState
    let imageBaseURL: URL
    let onAction: (WatchlistAction) -> Void

    public init(
        state: WatchlistViewState,
        imageBaseURL: URL,
        onAction: @escaping (WatchlistAction) -> Void
    ) {
        self.state = state
        self.imageBaseURL = imageBaseURL
        self.onAction = onAction
    }

    public var body: some View {
        content
            .navigationTitle("Watchlist")
            .onAppear {
                onAction(.onAppear)
            }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch state.loadState {
        case .loading where state.items.isEmpty:
            loadingView
        case .error(let message) where state.items.isEmpty:
            errorView(message: message)
        default:
            if state.items.isEmpty {
                emptyView
            } else {
                itemList
            }
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading watchlist...")
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

    // MARK: - Empty

    private var emptyView: some View {
        ContentUnavailableView {
            Label("No Movies Saved", systemImage: "bookmark")
        } description: {
            Text("Movies you bookmark will appear here.")
        }
    }

    // MARK: - Item List

    private var itemList: some View {
        List {
            ForEach(state.items) { item in
                WatchlistItemRow(
                    state: item,
                    posterURL: posterURL(for: item.posterPath)
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    onAction(.movieTapped(movieId: item.id))
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        onAction(.removeTapped(movieId: item.id))
                    } label: {
                        Label("Remove", systemImage: "bookmark.slash")
                    }
                }
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Helpers

    private func posterURL(for path: String?) -> URL? {
        guard let path else { return nil }
        return imageBaseURL
            .appendingPathComponent("w185")
            .appendingPathComponent(path)
    }
}

// MARK: - Watchlist Item Row

private struct WatchlistItemRow: View {
    let state: WatchlistItemViewState
    let posterURL: URL?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            posterImage
            movieInfo
            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Subviews

    @ViewBuilder
    private var posterImage: some View {
        AsyncImage(url: posterURL) { phase in
            switch phase {
            case .empty:
                posterPlaceholder
                    .overlay {
                        ProgressView()
                    }
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            case .failure:
                posterPlaceholder
                    .overlay {
                        Image(systemName: "film")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
            @unknown default:
                posterPlaceholder
            }
        }
        .frame(width: 60, height: 90)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private var posterPlaceholder: some View {
        Rectangle()
            .fill(Color(.tertiarySystemBackground))
            .frame(width: 60, height: 90)
    }

    private var movieInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(state.title)
                .font(.headline)
                .lineLimit(2)
                .foregroundStyle(.primary)

            HStack(spacing: 8) {
                if let year = state.releaseYear {
                    Text(year)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                ratingBadge
            }

            Text(state.overview)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .padding(.top, 2)

            Text("Added \(state.dateAdded)")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.top, 2)
        }
    }

    private var ratingBadge: some View {
        HStack(spacing: 2) {
            Image(systemName: "star.fill")
                .font(.caption2)
            Text(state.rating)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundStyle(.orange)
    }
}

// MARK: - Previews

#Preview("Loaded") {
    NavigationStack {
        WatchlistView(
            state: WatchlistViewState(
                loadState: .idle,
                items: [
                    WatchlistItemViewState(
                        id: 550,
                        title: "Fight Club",
                        overview: "A depressed man suffering from insomnia meets a strange soap salesman.",
                        posterPath: "/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg",
                        releaseYear: "1999",
                        rating: "8.4",
                        dateAdded: "1d ago"
                    ),
                    WatchlistItemViewState(
                        id: 27205,
                        title: "Inception",
                        overview: "A thief who steals corporate secrets through dream-sharing technology.",
                        posterPath: "/oYuLEt3zVCKq57qu2F8dT7NIa6f.jpg",
                        releaseYear: "2010",
                        rating: "8.4",
                        dateAdded: "3d ago"
                    )
                ]
            ),
            imageBaseURL: URL(string: "https://image.tmdb.org/t/p")!,
            onAction: { _ in }
        )
    }
}

#Preview("Empty") {
    NavigationStack {
        WatchlistView(
            state: WatchlistViewState(
                loadState: .idle,
                items: []
            ),
            imageBaseURL: URL(string: "https://image.tmdb.org/t/p")!,
            onAction: { _ in }
        )
    }
}

#Preview("Loading") {
    NavigationStack {
        WatchlistView(
            state: WatchlistViewState(
                loadState: .loading,
                items: []
            ),
            imageBaseURL: URL(string: "https://image.tmdb.org/t/p")!,
            onAction: { _ in }
        )
    }
}
