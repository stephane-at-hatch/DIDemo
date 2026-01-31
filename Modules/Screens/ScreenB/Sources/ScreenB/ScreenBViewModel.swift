import Foundation
import SwiftUI
import TestClientInterface
import ScreenBViews

/// ViewModel for ScreenB
/// Uses computed ViewState pattern (DreamState default)
/// Private domain state, public computed viewState
@MainActor
@Observable
public final class ScreenBViewModel {
    // MARK: - Private Dependencies
    
    private let testClient: TestClientProtocol
    
    // MARK: - Private Domain State
    
    private var items: [TestClientData] = []
    private var isLoading = false
    private var errorMessage: String?
    
    // MARK: - Computed ViewState (automatically updates when domain state changes)
    
    public var viewState: ScreenBViewState {
        ScreenBViewState(
            items: items.map { domainItem in
                ScreenBViewState.ItemState(
                    id: domainItem.id,
                    title: domainItem.title,
                    formattedTimestamp: domainItem.timestamp.formatted()
                )
            },
            isLoading: isLoading,
            errorMessage: errorMessage
        )
    }
    
    // MARK: - Init
    
    public init(testClient: TestClientProtocol) {
        self.testClient = testClient
    }
    
    // MARK: - Public Methods (called by RootView in response to Actions)
    
    public func loadItems() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Simulate loading multiple items
            let item = try await testClient.fetchData()
            items = [item]
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    public func addItem() async {
        let newItem = TestClientData(
            id: UUID().uuidString,
            title: "New Item \(items.count + 1)"
        )
        
        do {
            try await testClient.saveData(newItem)
            items.append(newItem)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    public func selectItem(id: String) {
        // Handle item selection - could navigate, show detail, etc.
        print("Selected item: \(id)")
    }
}
