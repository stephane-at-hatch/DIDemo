//
//  AppCoordinatorViewModel.swift
//  AppCoordinator
//
//  Created by Stephane Magne on 2026-01-31.
//

import TMDBClientInterface
import TabCoordinator
import SwiftUI

/// ViewModel for AppCoordinator
/// Manages navigation state between screens
@MainActor
@Observable
public final class AppCoordinatorViewModel {
    // MARK: Dependencies

    let tabCoordinatorViewModel: TabCoordinatorViewModel

    // MARK: - Init

    public init(
        dependencies: AppCoordinator.Dependencies
    ) {
        let tabCoordinatorDependencies = dependencies.buildChild(TabCoordinator.Dependencies.self, configure: { builder in
            let tmdbConfiguration = TMDBConfiguration(apiReadAccessToken: "YOUR_API_KEY_HERE")
            builder.provideInput(TMDBConfiguration.self, tmdbConfiguration)
        })
        self.tabCoordinatorViewModel = TabCoordinatorViewModel.live(dependencies: tabCoordinatorDependencies)
    }
}
