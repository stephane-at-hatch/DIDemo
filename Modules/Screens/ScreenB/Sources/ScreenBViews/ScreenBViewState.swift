import UIComponents

/// Immutable snapshot of the UI's current display state
/// Contains only data the View needs to render - no business logic
@Copyable
public struct ScreenBViewState: Equatable {
    public let items: [ItemState]
    public let isLoading: Bool
    public let errorMessage: String?
    
    public init(
        items: [ItemState] = [],
        isLoading: Bool = false,
        errorMessage: String? = nil
    ) {
        self.items = items
        self.isLoading = isLoading
        self.errorMessage = errorMessage
    }
    
    /// Presentation-ready item state
    public struct ItemState: Equatable, Identifiable {
        public let id: String
        public let title: String
        public let formattedTimestamp: String
        
        public init(id: String, title: String, formattedTimestamp: String) {
            self.id = id
            self.title = title
            self.formattedTimestamp = formattedTimestamp
        }
    }
}

/// All possible user actions from this view
public enum ScreenBAction {
    case addTapped
    case itemTapped(id: String)
}
