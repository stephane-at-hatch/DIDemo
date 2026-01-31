//
//  AppCoordinatorViewModel.swift
//  AppCoordinator
//
//  Created by Stephane Magne on 2026-01-31.
//

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
        let tabCoordinatorDependencies = dependencies.buildChild(TabCoordinator.Dependencies.self)
        self.tabCoordinatorViewModel = TabCoordinatorViewModel(dependencies: tabCoordinatorDependencies)
    }
}
