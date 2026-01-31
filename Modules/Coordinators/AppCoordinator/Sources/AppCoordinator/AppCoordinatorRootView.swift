import Foundation
import SwiftUI
import TabCoordinator

/// RootView - bridges ViewModel to View and provides screen implementations
public struct AppCoordinatorRootView: View {
    @State private var viewModel: AppCoordinatorViewModel
    
    public init(
        viewModel: AppCoordinatorViewModel
    ) {
        self._viewModel = State(initialValue: viewModel)
    }
    
    public var body: some View {
        TabCoordinatorRootView(viewModel: viewModel.tabCoordinatorViewModel)
    }
}

#Preview {
    AppCoordinatorRootView(
        viewModel: AppCoordinatorViewModel(
            tabBuilder: TabCoordinator.mockBuilder()
        )
    )
}
