import Foundation
import ModularNavigation
import SwiftUI
import ScreenAViews
import TestClientInterface

/// RootView - bridges ViewModel to View
/// Owns the ViewModel, dispatches Actions to ViewModel methods
struct ScreenARootView: View {
    @State private var viewModel: ScreenAViewModel

    init(viewModel: ScreenAViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }
    
    var body: some View {
        ScreenAView(
            state: viewModel.viewState,
            onAction: { action in
                // Switch on Actions and dispatch to ViewModel methods
                switch action {
                case .loadDataTapped:
                    Task {
                        await viewModel.loadData()
                    }
                case .presentSheet:
                    viewModel.presentSheet()
                }
            }
        )
        .task {
            await viewModel.loadData()
        }
    }
}

#Preview("With Mock Client") {
    let entry = ScreenA.mockEntry()
    let rootClient = NavigationClient<RootDestination>.root()

    NavigationDestinationView(
        previousClient: rootClient,
        mode: .root,
        entry: entry
    )
}
