import TestClientInterface
import UIComponents

/// Immutable snapshot of the UI's current display state
/// Contains only data the View needs to render - no business logic
@Copyable
public struct ScreenAViewState: Equatable {
    public let title: String
    public let data: DataState?
    public let isLoading: Bool
    public let errorMessage: String?
    
    public init(
        title: String = "Screen A",
        data: DataState? = nil,
        isLoading: Bool = false,
        errorMessage: String? = nil
    ) {
        self.title = title
        self.data = data
        self.isLoading = isLoading
        self.errorMessage = errorMessage
    }
    
    /// Presentation-ready data state
    public struct DataState: Equatable {
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
public enum ScreenAAction {
    case loadDataTapped
    case presentSheet
}
