import Foundation
import ModularNavigation
import SwiftUI
import TestClientInterface
import ScreenAViews

/// ViewModel for ScreenA
/// Uses computed ViewState pattern (DreamState default)
/// Private domain state, computed viewState
@MainActor
@Observable
final class ScreenAViewModel {
    // MARK: - Private Dependencies
    
    private let testClient: TestClientProtocol
    private let navigationClient: NavigationClient<ScreenA.Destination>

    // MARK: - Private Domain State
    
    private var data: TestClientData?
    private var isLoading = false
    private var errorMessage: String?
    
    // MARK: - Computed ViewState (automatically updates when domain state changes)
    
    var viewState: ScreenAViewState {
        ScreenAViewState(
            title: "Screen A",
            data: data.map { domainData in
                ScreenAViewState.DataState(
                    id: domainData.id,
                    title: domainData.title,
                    formattedTimestamp: domainData.timestamp.formatted()
                )
            },
            isLoading: isLoading,
            errorMessage: errorMessage
        )
    }
    
    // MARK: - Init
    
    init(
        navigationClient: NavigationClient<ScreenA.Destination>,
        testClient: TestClientProtocol
    ) {
        self.navigationClient = navigationClient
        self.testClient = testClient
    }
    
    // MARK: - Methods (called by RootView in response to Actions)
    
    func loadData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            data = try await testClient.fetchData()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }

    func presentSheet() {
        navigationClient.presentSheet(.external(.screenB))
    }
}
