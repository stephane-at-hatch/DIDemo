import Foundation
import SwiftUI
import ScreenDViews

/// ViewModel for ScreenD
/// Uses computed ViewState pattern (DreamState default)
/// Private domain state, public computed viewState
@MainActor
@Observable
public final class ScreenDViewModel {
    // MARK: - Private Domain State
    
    private var isLoading = false
    private var errorMessage: String?
    
    // MARK: - Computed ViewState (automatically updates when domain state changes)
    
    public var viewState: ScreenDViewState {
        ScreenDViewState(
            title: "ScreenD",
            isLoading: isLoading,
            errorMessage: errorMessage
        )
    }
    
    // MARK: - Init
    
    public init() {}
    
    // MARK: - Public Methods (called by RootView in response to Actions)
    
    public func loadData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // TODO: Load data from dependencies
            try await Task.sleep(for: .milliseconds(500))
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    public func dismissError() {
        errorMessage = nil
    }
}
