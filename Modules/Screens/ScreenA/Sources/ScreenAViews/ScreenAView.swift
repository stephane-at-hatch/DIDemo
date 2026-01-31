import SwiftUI

/// Lightweight view for ScreenA
/// Pure presentation - no business logic, no ViewModel knowledge
/// Accepts state + onAction closure (DreamState pattern)
public struct ScreenAView: View {
    public let state: ScreenAViewState
    public let onAction: (ScreenAAction) -> Void

    public init(
        state: ScreenAViewState,
        onAction: @escaping (ScreenAAction) -> Void = { _ in }
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
                Text("Error: \(errorMessage)")
                    .foregroundStyle(.red)
            } else if let data = state.data {
                VStack(alignment: .leading, spacing: 8) {
                    Text("ID: \(data.id)")
                        .font(.caption)
                    Text(data.title)
                        .font(.headline)
                    Text("Updated: \(data.formattedTimestamp)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
            
            Button("Load Data") {
                onAction(.loadDataTapped)
            }
            .buttonStyle(.borderedProminent)
            Button("Screen B") {
                onAction(.presentSheet)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

// MARK: - Previews

#Preview("Default State") {
    ScreenAView(state: ScreenAViewState())
}

#Preview("Loading State") {
    ScreenAView(state: ScreenAViewState(isLoading: true))
}

#Preview("With Data") {
    ScreenAView(
        state: ScreenAViewState(
            data: ScreenAViewState.DataState(
                id: "123",
                title: "Sample Data",
                formattedTimestamp: "Dec 21, 2025"
            )
        )
    )
}

#Preview("Error State") {
    ScreenAView(
        state: ScreenAViewState(errorMessage: "Something went wrong")
    )
}

#Preview("Interactive") {
    @Previewable @State var viewState = ScreenAViewState()

    ScreenAView(
        state: viewState,
        onAction: { action in
            switch action {
            case .loadDataTapped:
                viewState = ScreenAViewState(isLoading: true)
                // Simulate loading
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    viewState = ScreenAViewState(
                        data: .init(
                            id: UUID().uuidString,
                            title: "Loaded Data",
                            formattedTimestamp: Date().formatted()
                        )
                    )
                }
            case .presentSheet:
                break
            }
        }
    )
}
