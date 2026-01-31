import Foundation
import SwiftUI
import ScreenDViews

/// RootView - bridges ViewModel to View
/// Owns the ViewModel, dispatches Actions to ViewModel methods
public struct ScreenDRootView: View {
    @State private var viewModel: ScreenDViewModel

    public init(viewModel: ScreenDViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }
    
    public var body: some View {
        ScreenDView(
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
    ScreenDRootView(
        viewModel: ScreenDViewModel()
    )
}
