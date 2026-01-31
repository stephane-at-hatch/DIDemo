import Foundation
import ModularNavigation
import SwiftUI
import ScreenA
import ScreenC
import ScreenD

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
            builder: viewModel.builder,
            tabModels: [
                NavigationTabModel(
                    label: Label("First", systemImage: "bell.fill"),
                    destination: .tab(.first),
                    tab: .first
                ),
                NavigationTabModel(
                    label: Label("Second", systemImage: "cat.fill"),
                    destination: .tab(.second),
                    tab: .second
                ),
                NavigationTabModel(
                    label: Label("Third", systemImage: "moon.fill"),
                    destination: .tab(.third),
                    tab: .third
                )
            ]
        )
    }
}

#Preview {
    let rootClient = NavigationClient<RootDestination>.root()
    let builder = TabCoordinator.mockBuilder()

    let viewModel = TabCoordinatorViewModel(
        navigationClient: rootClient,
        builder: builder
    )

    TabCoordinatorRootView(
        viewModel: viewModel
    )
}
