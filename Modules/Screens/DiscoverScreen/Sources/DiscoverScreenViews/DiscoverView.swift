//
//  DiscoverView.swift
//  DiscoverScreenViews
//
//  Created by Stephane Magne
//

import SwiftUI

/// The discover view for browsing and searching movies.
public struct DiscoverView: View {
    let state: DiscoverViewState
    let imageBaseURL: URL
    let onAction: (DiscoverAction) -> Void

    @State private var searchText: String = ""

    public init(
        state: DiscoverViewState,
        imageBaseURL: URL,
        onAction: @escaping (DiscoverAction) -> Void
    ) {
        self.state = state
        self.imageBaseURL = imageBaseURL
        self.onAction = onAction
    }

    public var body: some View {
        content
            .navigationTitle("Discover")
            .searchable(text: $searchText, prompt: "Search movies...")
            .onChange(of: searchText) { _, newValue in
                onAction(.searchQueryChanged(newValue))
            }
            .onAppear {
                onAction(.onAppear)
            }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if state.isSearchActive {
            searchResultsView
        } else {
            categoriesView
        }
    }

    // MARK: - Search Results

    @ViewBuilder
    private var searchResultsView: some View {
        switch state.searchLoadState {
        case .loading:
            loadingView
        case .error(let message):
            errorView(message: message)
        case .idle, .refreshing:
            if state.searchResults.isEmpty {
                emptySearchView
            } else {
                searchResultsList
            }
        }
    }

    private var searchResultsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(state.searchResults) { movie in
                    SearchResultCard(
                        movie: movie,
                        imageBaseURL: imageBaseURL
                    )
                    .onTapGesture {
                        onAction(.movieTapped(movieId: movie.id))
                    }
                }
            }
            .padding()
        }
    }

    private var emptySearchView: some View {
        ContentUnavailableView.search(text: state.searchQuery)
    }

    // MARK: - Categories

    @ViewBuilder
    private var categoriesView: some View {
        switch state.loadState {
        case .loading:
            loadingView
        case .error(let message):
            errorView(message: message)
        case .idle, .refreshing:
            categoriesList
        }
    }

    private var categoriesList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                ForEach(state.categories) { category in
                    CategorySection(
                        category: category,
                        imageBaseURL: imageBaseURL,
                        onMovieTapped: { movieId in
                            onAction(.movieTapped(movieId: movieId))
                        }
                    )
                }
            }
            .padding(.vertical)
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading...")
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
}

// MARK: - Category Section

private struct CategorySection: View {
    let category: CategoryViewState
    let imageBaseURL: URL
    let onMovieTapped: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(category.title)
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(category.movies) { movie in
                        CompactMovieCard(
                            movie: movie,
                            imageBaseURL: imageBaseURL
                        )
                        .onTapGesture {
                            onMovieTapped(movie.id)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Compact Movie Card (for horizontal carousels)

private struct CompactMovieCard: View {
    let movie: MovieCardViewState
    let imageBaseURL: URL

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Poster
            AsyncImage(url: posterURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                default:
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .overlay {
                            Image(systemName: "film")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                        }
                }
            }
            .frame(width: 120, height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Title
            Text(movie.title)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(2)
                .frame(width: 120, alignment: .leading)

            // Rating
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .foregroundStyle(.orange)
                Text(movie.rating)
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
    }

    private var posterURL: URL? {
        guard let posterPath = movie.posterPath else { return nil }
        return imageBaseURL
            .appendingPathComponent("w342")
            .appendingPathComponent(posterPath)
    }
}

// MARK: - Search Result Card

private struct SearchResultCard: View {
    let movie: MovieCardViewState
    let imageBaseURL: URL

    var body: some View {
        HStack(spacing: 12) {
            // Poster
            AsyncImage(url: posterURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                default:
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .overlay {
                            Image(systemName: "film")
                                .foregroundStyle(.secondary)
                        }
                }
            }
            .frame(width: 60, height: 90)
            .clipShape(RoundedRectangle(cornerRadius: 6))

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(movie.title)
                    .font(.headline)
                    .lineLimit(2)

                if let year = movie.releaseYear {
                    Text(year)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.orange)
                    Text(movie.rating)
                }
                .font(.caption)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var posterURL: URL? {
        guard let posterPath = movie.posterPath else { return nil }
        return imageBaseURL
            .appendingPathComponent("w154")
            .appendingPathComponent(posterPath)
    }
}

// MARK: - Preview

#Preview("Categories") {
    NavigationStack {
        DiscoverView(
            state: DiscoverViewState(
                searchQuery: "",
                isSearchActive: false,
                searchLoadState: .idle,
                searchResults: [],
                categories: [
                    CategoryViewState(
                        id: "trending",
                        title: "Trending This Week",
                        movies: [
                            MovieCardViewState(id: 1, title: "Movie One", releaseYear: "2024", rating: "8.5", posterPath: nil, overview: ""),
                            MovieCardViewState(id: 2, title: "Movie Two", releaseYear: "2024", rating: "7.2", posterPath: nil, overview: ""),
                            MovieCardViewState(id: 3, title: "Movie Three With a Long Title", releaseYear: "2023", rating: "9.0", posterPath: nil, overview: "")
                        ]
                    ),
                    CategoryViewState(
                        id: "popular",
                        title: "Popular",
                        movies: [
                            MovieCardViewState(id: 4, title: "Popular Movie", releaseYear: "2024", rating: "8.0", posterPath: nil, overview: "")
                        ]
                    )
                ],
                loadState: .idle
            ),
            imageBaseURL: URL(string: "https://image.tmdb.org/t/p")!,
            onAction: { _ in }
        )
    }
}

#Preview("Search Results") {
    NavigationStack {
        DiscoverView(
            state: DiscoverViewState(
                searchQuery: "inception",
                isSearchActive: true,
                searchLoadState: .idle,
                searchResults: [
                    MovieCardViewState(id: 1, title: "Inception", releaseYear: "2010", rating: "8.8", posterPath: nil, overview: "A thief who steals corporate secrets..."),
                    MovieCardViewState(id: 2, title: "Inception: The Cobol Job", releaseYear: "2010", rating: "7.2", posterPath: nil, overview: "A prequel comic...")
                ],
                categories: [],
                loadState: .idle
            ),
            imageBaseURL: URL(string: "https://image.tmdb.org/t/p")!,
            onAction: { _ in }
        )
    }
}

#Preview("Loading") {
    NavigationStack {
        DiscoverView(
            state: DiscoverViewState(
                searchQuery: "",
                isSearchActive: false,
                searchLoadState: .idle,
                searchResults: [],
                categories: [],
                loadState: .loading
            ),
            imageBaseURL: URL(string: "https://image.tmdb.org/t/p")!,
            onAction: { _ in }
        )
    }
}
