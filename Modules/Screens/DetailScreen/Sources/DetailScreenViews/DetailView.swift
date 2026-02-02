//
//  DetailView.swift
//  DetailScreenViews
//
//  Created by Stephane Magne
//

import SwiftUI

/// The detail view displaying movie information.
public struct DetailView: View {
    let state: DetailViewState
    let imageBaseURL: URL
    let onAction: (DetailAction) -> Void
    
    public init(
        state: DetailViewState,
        imageBaseURL: URL,
        onAction: @escaping (DetailAction) -> Void
    ) {
        self.state = state
        self.imageBaseURL = imageBaseURL
        self.onAction = onAction
    }
    
    public var body: some View {
        content
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    watchlistButton
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
        case .loading:
            loadingView
        case .error(let message):
            errorView(message: message)
        case .idle:
            if let movie = state.movie {
                movieContent(movie)
            } else {
                loadingView
            }
        }
    }
    
    // MARK: - Loading
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading movie details...")
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
    
    // MARK: - Movie Content
    
    private func movieContent(_ movie: MovieDetailViewState) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                StretchyHeader(height: 250) {
                    backdropHeader(movie)
                }
                movieInfo(movie)
                    .padding(.horizontal)
            }
        }
        .ignoresSafeArea(edges: .top)
    }
    
    // MARK: - Backdrop Header
    
    private func backdropHeader(_ movie: MovieDetailViewState) -> some View {
        ZStack(alignment: .bottomLeading) {
            // Backdrop image
            if let backdropPath = movie.backdropPath {
                AsyncImage(url: backdropURL(for: backdropPath)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    default:
                        Rectangle()
                            .fill(Color(.systemGray5))
                    }
                }
            } else {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(height: 250)
            }
            
            // Gradient overlay
            LinearGradient(
                colors: [.clear, .black.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 250)
            
            // Title overlay
            VStack(alignment: .leading, spacing: 4) {
                Text(movie.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                
                if let tagline = movie.tagline, !tagline.isEmpty {
                    Text(tagline)
                        .font(.subheadline)
                        .italic()
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            .padding()
        }
    }
    
    // MARK: - Movie Info
    
    private func movieInfo(_ movie: MovieDetailViewState) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Quick stats
            quickStats(movie)
            
            // Genres
            if !movie.genres.isEmpty {
                genreChips(movie.genres)
            }
            
            // Overview
            overviewSection(movie.overview)
            
            // Credits
            if let credits = state.credits {
                creditsSection(credits)
            }
            
            // Box office
            if movie.budget != nil || movie.revenue != nil {
                boxOfficeSection(movie)
            }
        }
        .padding(.vertical)
    }
    
    private func quickStats(_ movie: MovieDetailViewState) -> some View {
        HStack(spacing: 16) {
            if let year = movie.releaseYear {
                statItem(icon: "calendar", value: year)
            }
            if let runtime = movie.runtime {
                statItem(icon: "clock", value: runtime)
            }
            statItem(icon: "star.fill", value: movie.rating, color: .orange)
            statItem(icon: "person.2", value: movie.voteCount)
        }
        .font(.subheadline)
    }
    
    private func statItem(icon: String, value: String, color: Color = .secondary) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(value)
                .foregroundStyle(.primary)
        }
    }
    
    private func genreChips(_ genres: [String]) -> some View {
        FlowLayout(spacing: 8) {
            ForEach(genres, id: \.self) { genre in
                Text(genre)
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray5))
                    .clipShape(Capsule())
            }
        }
    }
    
    private func overviewSection(_ overview: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Overview")
                .font(.headline)
            
            Text(overview)
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }
    
    private func creditsSection(_ credits: MovieCreditsViewState) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if !credits.directors.isEmpty {
                HStack {
                    Text("Director")
                        .font(.headline)
                    Spacer()
                    Text(credits.directors.joined(separator: ", "))
                        .foregroundStyle(.secondary)
                }
            }
            
            if !credits.cast.isEmpty {
                Text("Cast")
                    .font(.headline)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(credits.cast) { member in
                            castCard(member)
                        }
                    }
                }
                .scrollClipDisabled()
                .contentMargins(.horizontal, 0, for: .scrollContent)
            }
        }
    }
    
    private func castCard(_ member: CastMemberViewState) -> some View {
        VStack(spacing: 8) {
            AsyncImage(url: profileURL(for: member.profilePath)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                default:
                    Circle()
                        .fill(Color(.systemGray4))
                        .overlay {
                            Image(systemName: "person.fill")
                                .foregroundStyle(.secondary)
                        }
                }
            }
            .frame(width: 70, height: 70)
            .clipShape(Circle())
            
            VStack(spacing: 2) {
                Text(member.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(member.character)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(width: 80)
    }
    
    private func boxOfficeSection(_ movie: MovieDetailViewState) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Box Office")
                .font(.headline)
            
            HStack {
                if let budget = movie.budget {
                    VStack(alignment: .leading) {
                        Text("Budget")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(budget)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    Spacer()
                }
                
                if let revenue = movie.revenue {
                    VStack(alignment: .trailing) {
                        Text("Revenue")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(revenue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
            }
        }
    }
    
    // MARK: - Watchlist Button
    
    private var watchlistButton: some View {
        Button {
            onAction(.watchlistTapped)
        } label: {
            Image(systemName: state.isInWatchlist ? "bookmark.fill" : "bookmark")
                .foregroundStyle(state.isInWatchlist ? .yellow : .primary)
        }
    }
    
    // MARK: - Image URLs
    
    private func backdropURL(for path: String) -> URL? {
        imageBaseURL
            .appendingPathComponent("w780")
            .appendingPathComponent(path)
    }
    
    private func profileURL(for path: String?) -> URL? {
        guard let path else { return nil }
        return imageBaseURL
            .appendingPathComponent("w185")
            .appendingPathComponent(path)
    }
}

// MARK: - Preview

#Preview("Loaded") {
    DetailView(
        state: DetailViewState(
            loadState: .idle,
            movie: MovieDetailViewState(
                id: 550,
                title: "Fight Club",
                tagline: "Mischief. Mayhem. Soap.",
                overview: "A depressed man suffering from insomnia meets a strange soap salesman and soon finds himself living in his squalid house after his perfectly good apartment is destroyed.",
                releaseYear: "1999",
                runtime: "2h 19m",
                rating: "8.4",
                voteCount: "29.7K",
                posterPath: "/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg",
                backdropPath: "/hZkgoQYus5vegHoetLkCJzb17zJ.jpg",
                genres: ["Drama", "Thriller", "Comedy"],
                budget: "$63,000,000",
                revenue: "$100,853,753"
            ),
            credits: MovieCreditsViewState(
                directors: ["David Fincher"],
                cast: [
                    CastMemberViewState(id: 819, name: "Edward Norton", character: "The Narrator", profilePath: nil),
                    CastMemberViewState(id: 287, name: "Brad Pitt", character: "Tyler Durden", profilePath: nil),
                    CastMemberViewState(id: 1283, name: "Helena Bonham Carter", character: "Marla Singer", profilePath: nil)
                ]
            ),
            isInWatchlist: false
        ),
        imageBaseURL: URL(string: "https://image.tmdb.org/t/p")!,
        onAction: { _ in }
    )
}

#Preview("Loading") {
    DetailView(
        state: DetailViewState(
            loadState: .loading,
            movie: nil,
            credits: nil,
            isInWatchlist: false
        ),
        imageBaseURL: URL(string: "https://image.tmdb.org/t/p")!,
        onAction: { _ in }
    )
}

#Preview("Error") {
    DetailView(
        state: DetailViewState(
            loadState: .error(message: "Failed to load movie details. Please try again."),
            movie: nil,
            credits: nil,
            isInWatchlist: false
        ),
        imageBaseURL: URL(string: "https://image.tmdb.org/t/p")!,
        onAction: { _ in }
    )
}
