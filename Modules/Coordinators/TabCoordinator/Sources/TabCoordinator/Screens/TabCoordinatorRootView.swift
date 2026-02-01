//
//  TabCoordinatorRootView.swift
//  TabCoordinator
//
//  Created by Stephane Magne on 2026-01-31.
//

import Foundation
import ModularNavigation
import SwiftUI

/// RootView - bridges ViewModel to View and provides screen implementations
public struct TabCoordinatorRootView: View {
    @State private var viewModel: TabCoordinatorViewModel

    public init(
        viewModel: TabCoordinatorViewModel
    ) {
        self._viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        NavigationTabView(
            selectedTab: $viewModel.currentTab,
            rootClient: viewModel.navigationClient,
            builder: viewModel.tabEntry.builder,
            tabModels: [
                NavigationTabModel(
                    label: Label("Box Office", systemImage: "bell.fill"),
                    destination: .tab(.boxOffice),
                    tab: .boxOffice
                ),
                NavigationTabModel(
                    label: Label("Discover", systemImage: "cat.fill"),
                    destination: .tab(.discover),
                    tab: .discover
                ),
                NavigationTabModel(
                    label: Label("Watchlist", systemImage: "moon.fill"),
                    destination: .tab(.watchlist),
                    tab: .watchlist
                )
            ]
        )
    }
}

#Preview {
    let rootClient = NavigationClient<RootDestination>.root()
    let entry = TabCoordinator.mockEntry()

    let viewModel = TabCoordinatorViewModel(
        tabEntry: entry,
        navigationClient: rootClient
    )

    TabCoordinatorRootView(
        viewModel: viewModel
    )
}
