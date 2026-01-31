import UIComponents

/// Immutable snapshot of the UI's current display state
/// Contains only data the View needs to render - no business logic
@Copyable
public struct ScreenCViewState: Equatable {
    public let title: String
    public let isLoading: Bool
    public let errorMessage: String?
    
    public init(
        title: String = "ScreenC",
        isLoading: Bool = false,
        errorMessage: String? = nil
    ) {
        self.title = title
        self.isLoading = isLoading
        self.errorMessage = errorMessage
    }
}

/// All possible user actions from this view
public enum ScreenCAction {
    case onAppear
    case refreshTapped
    case dismissErrorTapped
}
