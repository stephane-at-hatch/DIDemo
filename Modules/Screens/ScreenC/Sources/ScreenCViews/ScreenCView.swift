import SwiftUI

/// Lightweight view for ScreenC
/// Pure presentation - no business logic, no ViewModel knowledge
/// Accepts state + onAction closure (DreamState pattern)
public struct ScreenCView: View {
    public let state: ScreenCViewState
    public let onAction: (ScreenCAction) -> Void

    public init(
        state: ScreenCViewState,
        onAction: @escaping (ScreenCAction) -> Void = { _ in }
    ) {
        self.state = state
        self.onAction = onAction
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            Text(state.title)
                .font(.largeTitle)
                .bold()
            
            if state.isLoading {
                ProgressView()
            } else if let errorMessage = state.errorMessage {
                VStack {
                    Text("Error: \(errorMessage)")
                        .foregroundStyle(.red)
                    Button("Dismiss") {
                        onAction(.dismissErrorTapped)
                    }
                }
            } else {
                // TODO: Add your content here
                Text("Content goes here")
            }
            
            Button("Refresh") {
                onAction(.refreshTapped)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .onAppear {
            onAction(.onAppear)
        }
    }
}

// MARK: - Previews

#Preview("Default") {
    ScreenCView(state: ScreenCViewState())
}

#Preview("Loading") {
    ScreenCView(state: ScreenCViewState(isLoading: true))
}

#Preview("Error") {
    ScreenCView(state: ScreenCViewState(errorMessage: "Something went wrong"))
}
