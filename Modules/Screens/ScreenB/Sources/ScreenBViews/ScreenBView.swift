import SwiftUI

/// Lightweight view for ScreenB
/// Pure presentation - no business logic, no ViewModel knowledge
/// Accepts state + onAction closure (DreamState pattern)
public struct ScreenBView: View {
    public let state: ScreenBViewState
    public let onAction: (ScreenBAction) -> Void

    public init(
        state: ScreenBViewState,
        onAction: @escaping (ScreenBAction) -> Void = { _ in }
    ) {
        self.state = state
        self.onAction = onAction
    }
    
    public var body: some View {
        NavigationStack {
            VStack {
                if state.isLoading {
                    ProgressView()
                } else if let errorMessage = state.errorMessage {
                    Text("Error: \(errorMessage)")
                        .foregroundStyle(.red)
                } else if state.items.isEmpty {
                    ContentUnavailableView(
                        "No Items",
                        systemImage: "tray",
                        description: Text("Tap + to add an item")
                    )
                } else {
                    List(state.items) { item in
                        Button {
                            onAction(.itemTapped(id: item.id))
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title)
                                    .font(.headline)
                                Text(item.id)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(item.formattedTimestamp)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("Screen B")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        onAction(.addTapped)
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Empty State") {
    ScreenBView(state: ScreenBViewState())
}

#Preview("Loading State") {
    ScreenBView(state: ScreenBViewState(isLoading: true))
}

#Preview("With Items") {
    ScreenBView(
        state: ScreenBViewState(
            items: [
                ScreenBViewState.ItemState(id: "1", title: "Item 1", formattedTimestamp: "Dec 21, 2025"),
                ScreenBViewState.ItemState(id: "2", title: "Item 2", formattedTimestamp: "Dec 20, 2025"),
                ScreenBViewState.ItemState(id: "3", title: "Item 3", formattedTimestamp: "Dec 19, 2025")
            ]
        )
    )
}

#Preview("Error State") {
    ScreenBView(
        state: ScreenBViewState(errorMessage: "Failed to load items")
    )
}

#Preview("Interactive") {
    @Previewable @State var viewState = ScreenBViewState(
        items: [
            ScreenBViewState.ItemState(id: "1", title: "Item 1", formattedTimestamp: Date().formatted())
        ]
    )
    
    ScreenBView(
        state: viewState,
        onAction: { action in
            switch action {
            case .addTapped:
                let newId = UUID().uuidString
                let newItems = viewState.items + [
                    ScreenBViewState.ItemState(
                        id: newId,
                        title: "Item \(viewState.items.count + 1)",
                        formattedTimestamp: Date().formatted()
                    )
                ]
                viewState = ScreenBViewState(items: newItems)
            case .itemTapped(let id):
                print("Tapped item: \(id)")
            }
        }
    )
}
