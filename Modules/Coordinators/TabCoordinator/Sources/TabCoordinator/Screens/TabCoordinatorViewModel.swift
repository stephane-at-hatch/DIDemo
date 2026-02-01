//
//  TabCoordinatorViewModel.swift
//  TabCoordinator
//
//  Created by Stephane Magne on 2026-01-31.
//

import ModularNavigation
import SwiftUI

@MainActor
@Observable
public final class TabCoordinatorViewModel {

    var currentTab: Tab = .boxOffice

    let tabEntry: TabCoordinator.Entry

    let navigationClient: NavigationClient<RootDestination>

    public static func live(
        dependencies: TabCoordinator.Dependencies
    ) -> TabCoordinatorViewModel {
        self.init(
            tabEntry: TabCoordinator.liveEntry(
                dependencies: dependencies
            ),
            navigationClient: .root()
        )
    }

    public init(
        tabEntry: TabCoordinator.Entry,
        navigationClient: NavigationClient<RootDestination>
    ) {
        self.tabEntry = tabEntry
        self.navigationClient = navigationClient
    }
}
