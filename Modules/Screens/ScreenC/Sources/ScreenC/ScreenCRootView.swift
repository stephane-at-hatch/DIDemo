import Foundation
import SwiftUI
import ScreenCViews

/// RootView - bridges ViewModel to View
/// Owns the ViewModel, dispatches Actions to ViewModel methods
public struct ScreenCRootView: View {
    @State private var viewModel: ScreenCViewModel

    public init(viewModel: ScreenCViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }
    
    public var body: some View {
        ScreenCView(
            state: viewModel.viewState,
            onAction: { action in
                switch action {
                case .onAppear:
                    Task {
                        await viewModel.loadData()
                    }
                case .refreshTapped:
                    Task {
                        await viewModel.loadData()
                    }
                case .dismissErrorTapped:
                    viewModel.dismissError()
                }
            }
        )
    }
}

#Preview {
    ScreenCRootView(
        viewModel: ScreenCViewModel()
    )
}
