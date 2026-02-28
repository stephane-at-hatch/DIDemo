//
//  ShareButtonViewState.swift
//  ShareComponentViews
//
//  Created by Stephane Magne
//

import Foundation

// MARK: - View State

public struct ShareButtonViewState: Equatable, Sendable {
    public let title: String
    public let shareContent: ShareContentViewState?

    public init(
        title: String,
        shareContent: ShareContentViewState?
    ) {
        self.title = title
        self.shareContent = shareContent
    }
}

public struct ShareContentViewState: Equatable, Sendable {
    public let text: String
    public let url: URL?

    public init(text: String, url: URL?) {
        self.text = text
        self.url = url
    }
}

// MARK: - Actions

public enum ShareButtonAction: Equatable, Sendable {
    case missingShareContent(title: String)
}
