import SwiftUI

/// Lightweight view for ScreenD
/// Pure presentation - no business logic, no ViewModel knowledge
/// Accepts state + onAction closure (DreamState pattern)
public struct ScreenDView: View {
    public let state: ScreenDViewState
    public let onAction: (ScreenDAction) -> Void

    public init(
        state: ScreenDViewState,
        onAction: @escaping (ScreenDAction) -> Void = { _ in }
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
    ScreenDView(state: ScreenDViewState())
}

#Preview("Loading") {
    ScreenDView(state: ScreenDViewState(isLoading: true))
}

#Preview("Error") {
    ScreenDView(state: ScreenDViewState(errorMessage: "Something went wrong"))
}
