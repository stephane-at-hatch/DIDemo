//
//  NavigationTabView.swift
//
//  Created by Stephane Magne on 2025-11-09.
//  Copyright hatch.co, 2025.
//

import SwiftUI

// MARK: - Navigation Tab Model

/// Model representing a single tab in a tab-based navigation setup.
///
/// Each tab combines a visual label (shown in the tab bar), a destination to navigate to,
/// and a tab identifier for selection binding.
public struct NavigationTabModel<Tab: Hashable, Destination: Hashable, Content: View>: Equatable {
    /// The label shown in the tab bar
    let label: Label<Text, Image>
    /// The destination to navigate to when this tab is selected
    let destination: Destination
    /// The tab identifier used in the selection binding
    let tab: Tab

    /// Optional custom image paths for active/inactive states
    let customActiveImageName: String?
    let customInactiveImageName: String?
    let customImageBundle: Bundle?
    let customTitle: String?

    /// Initialize a navigation tab model with an SF Symbol or single image.
    /// - Parameters:
    ///   - label: The label shown in the tab bar
    ///   - destination: The destination to navigate to when this tab is selected
    ///   - tab: The tab identifier
    public init(
        label: Label<Text, Image>,
        destination: Destination,
        tab: Tab
    ) {
        self.label = label
        self.destination = destination
        self.tab = tab
        self.customActiveImageName = nil
        self.customInactiveImageName = nil
        self.customImageBundle = nil
        self.customTitle = nil
    }

    /// Initialize a navigation tab model with custom active/inactive images.
    /// - Parameters:
    ///   - title: The text title shown in the tab bar
    ///   - activeImageName: The name of the image asset to show when tab is selected
    ///   - inactiveImageName: The name of the image asset to show when tab is not selected
    ///   - bundle: The bundle containing the image assets (typically .module for SPM)
    ///   - destination: The destination to navigate to when this tab is selected
    ///   - tab: The tab identifier
    public init(
        title: String,
        activeImageName: String,
        inactiveImageName: String,
        bundle: Bundle,
        destination: Destination,
        tab: Tab
    ) {
        // Create label with active image as default (will be overridden by tabItem modifier)
        self.label = Label(title, image: activeImageName)
        self.destination = destination
        self.tab = tab
        self.customActiveImageName = activeImageName
        self.customInactiveImageName = inactiveImageName
        self.customImageBundle = bundle
        self.customTitle = title
    }
    
    /// Equality based on destination only (labels and tabs are part of configuration)
    public static func == (lhs: NavigationTabModel<Tab, Destination, Content>, rhs: NavigationTabModel<Tab, Destination, Content>) -> Bool {
        lhs.destination == rhs.destination
    }
}

// MARK: - Navigation Tab View

/// TabView wrapper that integrates with the NavigationCoordinator system.
///
/// This view creates a standard SwiftUI TabView with navigation coordinator integration:
/// - Each tab gets its own independent coordinator and navigation state
/// - Deep linking automatically selects the correct tab and navigates within it
/// - Tab state persists when switching between tabs
///
/// Example:
/// ```swift
/// NavigationTabView(
///     selectedTab: $selectedTab,
///     rootClient: rootClient,
///     builder: buildDestination,
///     tabModels: [
///         NavigationTabModel(
///             label: Label("Home", systemImage: "house"),
///             destination: .home,
///             tab: .home
///         ),
///         NavigationTabModel(
///             label: Label("Library", systemImage: "music.note"),
///             destination: .library,
///             tab: .library
///         )
///     ]
/// )
/// ```
public struct NavigationTabView<Tab: Hashable, Destination: Hashable, Content: View>: View {
    /// The currently selected tab
    @Binding private var selectedTab: Tab

    /// Tracks which tab should be selected for deep link routing
    @StateObject private var deeplinkTab = DeepLinkTab<Tab>()

    /// Builder function to create views for destinations
    private let builder: DestinationBuilder<Destination, Content>
    
    /// Models defining each tab's label, destination, and identifier
    private let tabModels: [NavigationTabModel<Tab, Destination, Content>]
    
    /// Independent coordinator for each tab to maintain separate navigation state
    private let tabCoordinators: [NavigationCoordinator<Destination>]
    
    /// Initialize a navigation tab view.
    ///
    /// Creates independent coordinators for each tab. The deep link route from the root client
    /// is only given to the tab whose destination matches the first step of the route.
    ///
    /// - Parameters:
    ///   - selectedTab: Binding to the currently selected tab
    ///   - rootClient: The root navigation client (typically from `NavigationClient.root()`)
    ///   - builder: Closure to build views for destinations
    ///   - tabModels: Array of tab models defining each tab's appearance and destination
    public init(
        selectedTab: Binding<Tab>,
        rootClient: NavigationClient<RootDestination>,
        builder: @escaping DestinationBuilder<Destination, Content>,
        tabModels: [NavigationTabModel<Tab, Destination, Content>]
    ) {
        self._selectedTab = selectedTab
        self.builder = builder
        self.tabModels = tabModels
        
        // Create a coordinator from the root client
        let coordinator: NavigationCoordinator<Destination> = rootClient.coordinator.newCoordinator(
            monitor: DestinationMonitor(mode: .root)
        )
        
        // Create a coordinator for each tab, with deep link route only for the matching tab
        self.tabCoordinators = (0..<tabModels.count).map { index in
            let isDeepLink = coordinator.matchesDeepLinkRoute(for: tabModels[index].destination)
            return coordinator.copy(useDeepLinkRoute: isDeepLink)
        }
    }

    public var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(0..<tabModels.count, id: \.self) { index in
                let tabModel = tabModels[index]
                let tab = tabModel.tab
                let tabCoordinator = tabCoordinators[index]
                let isDeeplinkRoute = tabCoordinator.matchesDeepLinkRoute(for: tabModel.destination)
                
                // Mark the tab that should be selected for deep linking
                if isDeeplinkRoute {
                    deeplinkTab.value = tab
                }
                
                return TabContentView(
                    destination: tabModel.destination,
                    coordinator: tabCoordinator,
                    builder: builder
                )
                .equatable()
                .tabItem {
                    if let activeImageName = tabModel.customActiveImageName,
                       let inactiveImageName = tabModel.customInactiveImageName,
                       let bundle = tabModel.customImageBundle,
                       let title = tabModel.customTitle {
                        // Use custom images with state-based selection
                        let isSelected = selectedTab == tab
                        let imageName = isSelected ? activeImageName : inactiveImageName
                        Label {
                            Text(title)
                        } icon: {
                            Image(imageName, bundle: bundle)
                        }
                    } else {
                        // Fall back to default label (SF Symbol or single image)
                        tabModel.label
                    }
                }
                .tag(tab)
            }
        }
        .onAppear {
            // Switch to the deep link tab if needed
            if let tab = deeplinkTab.value {
                if selectedTab != tab {
                    selectedTab = tab
                }
                deeplinkTab.value = nil
            }
        }
    }
}

// MARK: - Tab Content View

/// Isolates each tab's content to prevent unnecessary rebuilds when selectedTab changes.
///
/// Each tab maintains its own navigation state independently. This view prevents SwiftUI from
/// recreating tab content when switching between tabs, preserving navigation history.
struct TabContentView<Destination: Hashable, Content: View>: View, Equatable {
    /// The root destination for this tab
    let destination: Destination
    /// The coordinator managing this tab's navigation
    let coordinator: NavigationCoordinator<Destination>
    /// Builder function to create views for destinations
    let builder: DestinationBuilder<Destination, Content>
    
    /// Initialize tab content view.
    /// - Parameters:
    ///   - destination: The destination to display for this tab
    ///   - coordinator: The coordinator managing this tab's navigation
    ///   - builder: Closure to build views for destinations
    init(
        destination: Destination,
        coordinator: NavigationCoordinator<Destination>,
        builder: @escaping DestinationBuilder<Destination, Content>
    ) {
        self.destination = destination
        self.coordinator = coordinator
        self.builder = builder
    }
    
    var body: some View {
        NavigationDestinationView(
            previousCoordinator: coordinator,
            monitor: DestinationMonitor(mode: .root),
            destination: destination,
            builder: builder
        )
    }
    
    static func == (lhs: TabContentView, rhs: TabContentView) -> Bool {
        lhs.destination == rhs.destination
    }
}

// MARK: - Deep Link Tab

/// Simple reference type wrapper for tracking which tab should be selected for deep linking.
///
/// Uses a class to avoid value semantics that would cause TabView to lose track of
/// which tab to select during deep linking.
private final class DeepLinkTab<T: Equatable>: ObservableObject, Equatable {
    /// The tab to select, or nil if no deep link is active
    var value: T?
    
    init(value: T? = nil) {
        self.value = value
    }
    
    /// Equality based on the wrapped value
    static func == (lhs: DeepLinkTab<T>, rhs: DeepLinkTab<T>) -> Bool {
        lhs.value == rhs.value
    }
}

// MARK: - Coordinator Helpers

extension NavigationCoordinator {
    /// Check if this coordinator's deep link route matches the given destination.
    ///
    /// Used during tab setup to determine which tab should receive the deep link route.
    fileprivate func matchesDeepLinkRoute(for destination: Destination) -> Bool {
        if deepLinkRoute.initialSteps.first?.destination == destination {
            true
        } else {
            false
        }
    }
    
    /// Create a copy of this coordinator, optionally with or without the deep link route.
    ///
    /// Used to distribute a single deep link route to only the tab that matches,
    /// while other tabs get coordinators without deep linking.
    fileprivate func copy(useDeepLinkRoute: Bool) -> NavigationCoordinator<Destination> {
        if useDeepLinkRoute {
            self
        } else {
            copyWithoutDeeplink()
        }
    }
    
    /// Creates a copy of the coordinator without any deep link route.
    /// Used for tabs that shouldn't process the initial deep link.
    private func copyWithoutDeeplink() -> NavigationCoordinator<Destination> {
        NavigationCoordinator(
            type: .nested(path: chainedPath),
            presentationMode: presentationMode,
            route: [],
            didConsumeRoute: didConsumeRoute,
            dismissParent: dismissParent
        )
    }
}
