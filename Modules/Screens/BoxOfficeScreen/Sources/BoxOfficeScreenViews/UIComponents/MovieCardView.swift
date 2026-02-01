//
//  MovieCardView.swift
//  BoxOfficeScreenViews
//
//  Created by Stephane Magne
//

import SwiftUI

/// A card view displaying a movie's poster, title, and basic info.
public struct MovieCardView: View {
    let state: MovieCardViewState
    let posterURL: URL?
    let onAction: (MovieCardAction) -> Void

    public init(
        state: MovieCardViewState,
        posterURL: URL?,
        onAction: @escaping (MovieCardAction) -> Void
    ) {
        self.state = state
        self.posterURL = posterURL
        self.onAction = onAction
    }

    public var body: some View {
        Button {
            onAction(.tapped)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                posterImage
                movieInfo
                Spacer(minLength: 0)
            }
            .padding(12)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
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
        .frame(width: 80, height: 120)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var posterPlaceholder: some View {
        Rectangle()
            .fill(Color(.tertiarySystemBackground))
            .frame(width: 80, height: 120)
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
                .lineLimit(3)
                .padding(.top, 4)
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

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        MovieCardView(
            state: MovieCardViewState(
                id: 550,
                title: "Fight Club",
                releaseYear: "1999",
                rating: "8.4",
                posterPath: "/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg",
                overview: "A depressed man suffering from insomnia meets a strange soap salesman."
            ),
            posterURL: URL(string: "https://image.tmdb.org/t/p/w185/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg"),
            onAction: { _ in }
        )

        MovieCardView(
            state: MovieCardViewState(
                id: 27205,
                title: "Inception",
                releaseYear: "2010",
                rating: "8.4",
                posterPath: nil,
                overview: "A thief who steals corporate secrets through dream-sharing technology."
            ),
            posterURL: nil,
            onAction: { _ in }
        )
    }
    .padding()
}
