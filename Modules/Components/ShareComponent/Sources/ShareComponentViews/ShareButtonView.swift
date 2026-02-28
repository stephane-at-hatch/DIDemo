//
//  ShareButtonView.swift
//  ShareComponentViews
//
//  Created by Stephane Magne
//

import SwiftUI

/// A share button that presents the system share sheet.
public struct ShareButtonView: View {

    let state: ShareButtonViewState
    let onAction: (ShareButtonAction) -> Void

    public init(
        state: ShareButtonViewState,
        onAction: @escaping (ShareButtonAction) -> Void
    ) {
        self.state = state
        self.onAction = onAction
    }

    public var body: some View {
        if let content = state.shareContent {
            ShareLink(
                item: content.url ?? URL(string: "https://www.themoviedb.org")!,
                subject: Text(state.title),
                message: Text(content.text)
            ) {
                Image(systemName: "square.and.arrow.up")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        } else {
            Button {
                onAction(.missingShareContent(title: state.title))
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Preview

#Preview {
    ShareButtonView(
        state: ShareButtonViewState(
            title: "Fight Club",
            shareContent: ShareContentViewState(
                text: "Check out 'Fight Club' on TMDB!",
                url: URL(string: "https://www.themoviedb.org/movie/550")
            )
        ),
        onAction: { _ in }
    )
}
