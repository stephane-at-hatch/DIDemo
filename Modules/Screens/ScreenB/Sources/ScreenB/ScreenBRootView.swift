import Foundation
import SwiftUI
import ScreenBViews
import TestClientInterface

/// RootView - bridges ViewModel to View
/// Owns the ViewModel, dispatches Actions to ViewModel methods
public struct ScreenBRootView: View {
    @State private var viewModel: ScreenBViewModel

    public init(viewModel: ScreenBViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }
    
    public var body: some View {
        ScreenBView(
            state: viewModel.viewState,
            onAction: { action in
                // Switch on Actions and dispatch to ViewModel methods
                switch action {
                case .addTapped:
                    Task {
                        await viewModel.addItem()
                    }
                case .itemTapped(let id):
                    viewModel.selectItem(id: id)
                }
            }
        )
        .task {
            await viewModel.loadItems()
        }
    }
}

#Preview("With Mock Client") {
    ScreenBRootView(
        viewModel: ScreenBViewModel(
            testClient: MockTestClient()
        )
    )
}
