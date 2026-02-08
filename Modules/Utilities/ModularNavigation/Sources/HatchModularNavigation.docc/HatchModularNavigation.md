# ``HatchModularNavigation``

HatchModularNavigation - Modular SwiftUI Navigation System (RFC)
**Authors:** [Stephane Magne](mailto:stephane@hatch.co)
**Created:** Nov 06, 2024

## About Document

This RFC (Request for Comments) documents the HatchModularNavigation system that has been developed for the Hatch iOS app. This document serves as both:
1. **Technical specification** for the implemented navigation architecture
2. **Reference guide** for engineers working with the system
3. **Onboarding resource** for understanding navigation patterns

Note: While this is written in RFC format, the system has already been implemented. This document captures the architecture, patterns, and design decisions for future reference and maintenance.

## Background & Motivation

- The Hatch iOS app uses a tab-based navigation structure with three main sections (Home, Routine, Library)
- Each tab needs independent navigation state while supporting deep linking across the entire app
- SwiftUI's native navigation tools (NavigationStack, sheets, full-screen covers) need to work together seamlessly
- We require a testable, dependency-injectable navigation system that integrates with our builder pattern architecture
- The navigation system must support deep linking with type-safe routes across multiple navigation contexts

## Problem

**What problem are we solving?**
- Managing navigation state across multiple tabs, nested modals, and navigation stacks in SwiftUI
- Providing type-safe navigation that prevents runtime errors from invalid routes
- Supporting deep linking that can navigate through multiple contexts (tab → feature → detail view)
- Enabling testable ViewModels that can trigger navigation without direct view dependencies
- Maintaining independent navigation state per tab while sharing a common infrastructure

**Risks and Mitigations:**
- **Technical Risk:** Complex coordinator hierarchy could lead to memory leaks
  - *Mitigation:* Use `@MainActor`, weak references where needed, and struct-based coordinators
- **Feasibility Risk:** Deep linking across multiple destination types requires careful type erasure
  - *Mitigation:* `AnyRoute` and `AnySteps` provide type-erased containers while maintaining type safety at boundaries
- **Maintenance Risk:** Developers might not follow patterns correctly without good documentation
  - *Mitigation:* Comprehensive documentation, clear examples, and consistent patterns across features

## Glossary

- **NavigationCoordinator:** Core class that owns and manages navigation state for a specific destination type
- **NavigationClient:** Closure-based interface for dependency injection, providing navigation operations to ViewModels
- **Destination:** An enum representing all possible screens/views within a navigation context
- **Builder:** Generic struct that creates views for destinations with proper dependencies
- **NavigationMode:** Enum defining how a destination is presented (root, push, sheet, cover)
- **Deep Link Route:** Type-erased array of navigation steps that can span multiple destination types
- **AnyRoute:** Type-erased container for heterogeneous navigation routes across different contexts
- **Client Pattern:** Point-Free architectural pattern where dependencies are passed as structured values with closures

## Solution

### Architecture Overview

The HatchModularNavigation system is built around three core concepts:

1. **NavigationCoordinator<Destination>** - Owns navigation state for a specific destination type
2. **NavigationClient<Destination>** - Provides a testable interface for ViewModels to trigger navigation
3. **Destination Builders** - Create views with proper dependencies for each destination

**High-Level Module Structure:**

```
┌───────────────────────────────────────────────────────────────────────────────────────────────┐
│                                        HatchAdultScreen                                       │
│             ┌───────────────────────────────────────────────────────────┐                     │
│             │  AdultScreen (Root)                                       │                     │
│             │  ├─ TabView with 3 tabs                                   │                     │
│             │  │  ├─ Tab 1: Sleep                                       │                     │
│             │  │  ├─ Tab 2: Routine                                     │                     │
│             │  │  └─ Tab 3: Library                                     │                     │
│             │  └─ AdultScreenDestination enum (sleep, routine, library) │                     │
│             └───────────────────────────────────────────────────────────┘                     │
│              ▼                                   ▼                            ▼               │
├────────────────────────────────┬──────────────────────────────┬───────────────────────────────┤
│     HatchAdultSleepFeature     │    HatchAdultRoutineFeature  │   HatchAdultLibraryFeature    │
│ ┌────────────────────────────┐ │ ┌──────────────────────────┐ │ ┌──────────────────────────┐  │
│ │ AdultSleepDestination      │ │ │ AdultRoutineDestination  │ │ │ AdultLibraryDestination  │  │
│ │ - .landingPage             │ │ │ - .routine               │ │ │ - .library               │  │
│ └────────────────────────────┘ │ └──────────────────────────┘ │ └──────────────────────────┘  │
└────────────────────────────────┴──────────────────────────────┴───────────────────────────────┘
                          ▲
                          │
          ┌───────────────┴───────────────┐
          │  HatchModularNavigation       │
          │  - NavigationCoordinator      │
          │  - NavigationClient           │
          │  - NavigationDestinationView  │
          │  - NavigationRootView         │
          │  - NavigationTabView          │
          └───────────────────────────────┘
```

### Setting Up a Feature Module

Each feature module defines three key components:

**1. Destination Enum:**

```swift
// In HatchAdultRoutineFeature/Sources/Navigation/AdultRoutineDestination.swift
public enum AdultRoutineDestination: Hashable {
    case routine
    // Add more destinations as the feature grows
}
```

**2. Destination Builder:**

```swift
// Generic builder that creates views for destinations
@MainActor
public struct AdultRoutineDestinationBuilder<DestinationView: View> {
    public let buildDestination: DestinationBuilder<AdultRoutineDestination, DestinationView>    
}
```

**3. Live and Mock Builders:**

```swift
// Live builder with real dependencies
extension AdultRoutineDestination {
    public static func liveBuilder(
        macAddress: String,
        coordinator: any RoutineCoordinating,
        favoritesClient: FavoritesClient,
        contentClient: ContentClient,
        visualAssetsClient: VisualAssetsClient,
        subscriptionClient: SubscriptionClient
    ) -> AdultRoutineDestinationBuilder<AdultRoutineDestinationView> {
        AdultRoutineDestinationBuilder { destination, mode, navigationClient in
            let viewModel: AdultRoutineDestinationViewModel = switch destination {
            case .routine:
                .routine(
                    AdultRoutineRoutineDestinationViewModel(
                        routineViewModel: AdultRoutineViewModel(
                            coordinator: coordinator,
                            macAddress: macAddress,
                            favoritesClient: favoritesClient,
                            contentClient: contentClient,
                            visualAssetsClient: visualAssetsClient,
                            subscriptionClient: subscriptionClient,
                            navigationClient: navigationClient
                        ),
                        visualAssetsClient: visualAssetsClient
                    )
                )
            }
            return AdultRoutineDestinationView(
                viewModel: viewModel,
                mode: mode,
                client: navigationClient
            )
        }
    }
}

// Mock builder for testing/previews
extension AdultRoutineDestination {
    public static func mockBuilder() -> AdultRoutineDestinationBuilder<AdultRoutineDestinationView> {
        AdultRoutineDestinationBuilder { destination, mode, navigationClient in
            // Create view models with mock dependencies
            // ...
        }
    }
}
```

### Connecting Modules Together

Parent modules connect to child feature modules through their builders:

```swift
// In HatchAdultScreen/Sources/Navigation/AdultScreenDestination+Live.swift
extension AdultScreenDestination {
    public static func liveBuilder(
        macAddress: String,
        coordinator: any RoutineCoordinating,
        // ... other dependencies
    ) -> AdultScreenTabDestinationBuilder<AdultScreenDestinationView> {
        AdultScreenTabDestinationBuilder { destination, mode, navigationClient in
            let viewModel: AdultScreenDestinationViewModel = switch destination {
            case .routine:
                .routine(
                    AdultScreenRoutineDestinationViewModel(
                        // Connect to child feature's builder
                        buildDestination: AdultRoutineDestination.liveBuilder(
                            macAddress: macAddress,
                            coordinator: coordinator,
                            favoritesClient: favoritesClient,
                            contentClient: contentClient,
                            visualAssetsClient: visualAssetsClient,
                            subscriptionClient: subscriptionClient
                        ).buildDestination
                    )
                )
            // ... other tabs
            }
            return AdultScreenDestinationView(
                viewModel: viewModel,
                mode: mode,
                client: navigationClient
            )
        }
    }
}
```

### Core Navigation Classes

#### NavigationClient (Interface)

The `NavigationClient` is a closure-based interface for triggering navigation from ViewModels:

```swift
@MainActor
public struct NavigationClient<Destination: Hashable> {
    /// Navigate to a destination with a specific presentation mode
    public let present: (Destination, NavigationMode) -> Void
    /// Dismiss the current screen
    public let dismiss: () -> Void
    /// Close the entire presentation context
    public let close: () -> Void
    
    // Convenience methods
    public func push(_ destination: Destination)
    public func presentSheet(_ destination: Destination)
    public func presentFullScreenCover(_ destination: Destination)
}
```

**Usage in ViewModels:**

```swift
struct MyViewModel {
    let navigationClient: NavigationClient<MyDestination>
    
    func handleButtonTap() {
        navigationClient.push(.detailScreen)
    }
    
    func handleDismiss() {
        navigationClient.dismiss()
    }
}
```

**Testing:**

```swift
func testNavigation() {
    var capturedDestination: MyDestination?
    var capturedMode: NavigationMode?
    
    let client = NavigationClient<MyDestination>(
        present: { dest, mode in
            capturedDestination = dest
            capturedMode = mode
        },
        dismiss: {},
        close: {}
    )
    
    let viewModel = MyViewModel(navigationClient: client)
    viewModel.handleButtonTap()
    
    XCTAssertEqual(capturedDestination, .detailScreen)
    XCTAssertEqual(capturedMode, .push)
}
```

#### NavigationCoordinator (Implementation)

The `NavigationCoordinator` is the concrete implementation (internal to HatchModularNavigation) that owns navigation state:

```swift
@MainActor
public final class NavigationCoordinator<Destination: Hashable>: Hashable {
    // Navigation state
    var rootPath: Binding<NavigationPath>?
    private(set) var chainedPath: Binding<NavigationPath>?
    var presented: PresentedBindings
    
    // Deep linking
    let deepLinkRoute: DeepLinkRoute
    
    // Context
    let isRoot: Bool
    var presentationMode: NavigationMode
    let dismissParent: () -> Void
    
    // Methods
    public func push(_ destination: Destination)
    public func presentSheet(_ destination: Destination)
    public func presentFullScreenCover(_ destination: Destination)
    public func dismiss() // Smart dismiss: sheet/cover → pop → dismiss parent
    public func close()   // Always dismisses the modal flow
}
```

**Key Features:**
- **Owns navigation state** for a specific destination type
- **Smart dismissal** - tries sheet/cover first, then navigation pop, then parent dismissal
- **Deep link support** - processes initial route steps on appearance
- **Path inheritance** - nested contexts can share or create their own navigation paths

#### Navigation Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│  NavigationRootView                                             │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  NavigationStack                                          │  │
│  │  ├─ Root View (destination from builder)                  │  │
│  │  │  └─ .destinationHandler (wires up navigation)          │  │
│  │  │     ├─ .navigationDestination (for push)               │  │
│  │  │     ├─ .sheet (for modal sheets)                       │  │
│  │  │     └─ .fullScreenCover (for covers)                   │  │
│  │  │                                                        │  │
│  │  └─ Navigation Path (owned by coordinator)                │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                 │
│  NavigationCoordinator manages:                                 │
│  - Push destinations → appended to NavigationPath               │
│  - Sheet presentations → @Observable presented.sheet            │
│  - Cover presentations → @Observable presented.fullScreenCover  │
└─────────────────────────────────────────────────────────────────┘
```

### Deep Linking

Deep linking works through type-erased routes that can span multiple destination types:

**Creating a Deep Link Route:**

```swift
	// Route: Library Tab → Some other library view
   let route: AnyRoute = [
		AnySteps.steps(for: AdultScreenDestination.self, order: [
		    .destination(.library, as: .root)
		]),
			
		AnySteps.steps(for: AdultLibraryDestination.self, order: [
		    .destination(.other, as: .push),
		])
    ]
```

The important thing to note here is that we need the groupings of steps to follow the structure of the app. So, we start with the destination type representing the tab bar (`AdultScreenDestination`) which will select the relevant tab, and then we push on a new destination for the new module context (`AdultLibraryDestination`).

The reason we jump from `AdultScreenDestination` to `AdultLibraryDestination` is because the root view for the `library` tab is created from the `AdultLibraryFeature` module, so we must now continue from the new context. We can either push destinations that exist within the `AdultLibraryFeature` module, or any modules that it imports, but it must be downstream.

**How Deep Linking Works:**
1. Root coordinator receives the full route
2. Each coordinator checks if the first route segment matches its destination type
3. If it matches, the coordinator consumes those steps and passes remaining route to child
4. If it doesn't match, the route is passed through untouched
5. Process repeats recursively through the navigation hierarchy

### Tab Navigation

Tab navigation uses `NavigationTabView` to manage independent navigation state per tab:

```swift
public struct NavigationTabView<Tab: Hashable & CaseIterable, Destination: Hashable, Content: View>: View {
    @Binding private var selectedTab: Tab
    private let coordinator: NavigationCoordinator<Destination>
    private let tabModels: [NavigationTabModel<Destination, Content>]
    
    // Each tab gets its own coordinator for independent navigation state
    // Deep link routes automatically select and navigate to the correct tab
}
```

**Usage:**

```swift
NavigationTabView<AdultTab, AdultScreenDestination, AdultScreenDestinationView>(
    selectedTab: $selectedTab,
    coordinator: coordinator,
    builder: tabDestinationBuilder.buildDestination,
    tabModels: [
        NavigationTabModel(label: Label("Home", systemImage: "house.fill"), destination: .home),
        NavigationTabModel(label: Label("Routine", systemImage: "arrow.3.trianglepath"), destination: .routine),
        NavigationTabModel(label: Label("Library", systemImage: "book.fill"), destination: .library)
    ]
)
```

### Alternatives Considered

**Option 1: NavigationStack with path binding only**
- ✅ Pros: Simple, native SwiftUI
- ❌ Cons: Doesn't support sheets/covers well, difficult to test, no type safety across contexts
- **Rejected:** Insufficient for complex navigation requirements

**Option 2: Coordinator pattern with UIKit-style protocols**
- ✅ Pros: Familiar pattern, explicit
- ❌ Cons: Requires many protocols, difficult to mock, doesn't leverage SwiftUI's native tools
- **Rejected:** Too heavyweight, doesn't fit SwiftUI paradigm

**Option 3: Third-party navigation library (FlowStacks, swift-navigation)**
- ✅ Pros: Battle-tested, feature-rich
- ❌ Cons: External dependency, may not fit our specific needs, learning curve
- **Rejected:** Prefer lightweight, custom solution tailored to our architecture

**Option 4: Current implementation (HatchModularNavigation)**
- ✅ Pros: Type-safe, testable, integrates with builder pattern, supports all presentation modes, deep linking
- ✅ Fits existing architecture patterns (Client pattern, dependency injection)
- ✅ Lightweight - no external dependencies
- **Selected:** Best fit for our requirements

## Security

**Data Flow Security:**
- Navigation state contains only enum cases and primitive values - no sensitive data in navigation paths
- Deep link routes are validated at each boundary - invalid destination types are rejected
- Navigation coordinators are `@MainActor` isolated, preventing race conditions

**Dependency Injection Security:**
- Clients (networking, authentication, etc.) are injected at app startup, not stored in navigation state
- Sensitive dependencies (API keys, tokens) never pass through navigation system
- Mock builders prevent accidental production code in test/preview contexts

**Deep Linking Security:**
- Deep link routes must pass through app-level validation before being processed
- Type-safe destination enums prevent navigation to non-existent or unauthorized screens
- Each module validates its own destination before processing deep link steps

## Effort

**Size:** Already implemented (historical estimate: XL - ~8 weeks)

**Breakdown:**
- Core navigation infrastructure (NavigationCoordinator, NavigationClient): 2 weeks
- Deep linking system (AnyRoute, type erasure): 2 weeks
- Tab navigation support: 1 week
- Integration with existing features: 2 weeks
- Testing and refinement: 1 week
- **Total:** ~8 weeks

**Current State:**
- ✅ Core navigation system implemented
- ✅ Tab navigation working
- ✅ Deep linking functional
- ✅ Integrated across 3 main features (Home, Routine, Library)
- ✅ Comprehensive documentation added

## Impact

**Developer Productivity:**
- **Reduced navigation boilerplate:** Builder pattern eliminates repetitive navigation setup
- **Improved testability:** NavigationClient enables easy mocking of navigation in ViewModels
- **Type safety:** Compile-time guarantees prevent invalid navigation paths
- **Faster feature development:** Clear patterns make adding new screens straightforward

**Code Quality:**
- **Modularity:** Each feature owns its navigation destinations and builders
- **Maintainability:** Consistent patterns across all features reduce cognitive load
- **Testability:** 100% testable navigation logic through dependency injection

**User Experience:**
- **Deep linking:** Users can navigate directly to any screen in the app from external links
- **Independent tab state:** Each tab maintains its own navigation stack
- **Proper dismissal:** Smart dismiss logic provides intuitive back navigation

**Metrics:**
- Time to add new destination: ~10-15 minutes (define destination case, update builder)
- ViewModel test coverage: Significantly improved with mockable NavigationClient
- Navigation-related bugs: Reduced through type-safe destination enums

## Reviewers

| Required Reviewers | Where Feedback Was Left | Review Completion Date |
| :---- | :---- | :---- |
| iOS Architecture Team | Code Review | Oct 31, 2024 |
| iOS Platform Team | Implementation Review | Nov 1, 2024 |
| QA Team | Testing & Documentation | Nov 5, 2024 |

---

## Appendix: Code Examples

### Complete Feature Setup Example

Here's a complete example of setting up a new feature with navigation:

**1. Define Destination:**

```swift
// Sources/Navigation/MyFeatureDestination.swift
import HatchModularNavigation
import SwiftUI

public struct MyFeatureDestination: Hashable {
    public enum Public: Hashable {
        case landing
    }
    
    enum Internal: Hashable {
        case detail(id: String)
    }
    
    enum DestinationType: Hashable {
        case `public`(Public)
        case `internal`(Internal)
    }
    
    var type: DestinationType
    
    init(_ destination: Public) {
        self.type = .public(destination)
    }
    
    init(_ destination: Internal) {
        self.type = .internal(destination)
    }
    
    public static func `public`(_ destination: Public) -> Self {
        self.init(destination)
    }
    
    static func `internal`(_ destination: Internal) -> Self {
        self.init(destination)
    }
}

@MainActor
public struct MyFeatureDestinationBuilder<DestinationView: View> {
    public let buildDestination: DestinationBuilder<MyFeatureDestination, DestinationView> 
}
```

**2. Create Builders:**

```swift
// Sources/Navigation/MyFeatureDestination+Live.swift
extension MyFeatureDestination {
    public static func liveBuilder(
        dataClient: DataClient
    ) -> MyFeatureDestinationBuilder<MyFeatureDestinationView> {
        MyFeatureDestinationBuilder { destination, mode, navigationClient in
            let viewModel: MyFeatureDestinationViewModel = switch destination.type {
            case .public(let publicDestination):
                switch publicDestination {
                case .landing:
                    .landing(
                        MyFeatureLandingDestinationViewModel(
                            myViewModel: MyViewModel(
                                navigationClient: navigationClient,
                                dataClient: dataClient
                            )
                        )
                    )
                }
            case .internal(let internalDestination):
                switch internalDestination {
                case .detail(let id):
                    .detail(
                        MyFeatureDetailDestinationViewModel(
                            detailViewModel: DetailViewModel(
                                id: id,
                                navigationClient: navigationClient,
                                dataClient: dataClient
                            )
                        )
                    )
                }
            }
            return MyFeatureDestinationView(
                viewModel: viewModel,
                mode: mode,
                client: navigationClient
            )
        }
    }
}
```

**3. Create DestinationView:**

```swift
// Sources/Navigation/MyFeatureDestinationView.swift
public struct MyFeatureDestinationView: View {
    let viewModel: MyFeatureDestinationViewModel
    let mode: NavigationMode
    let client: NavigationClient<MyFeatureDestination>
    
    public var body: some View {
        switch viewModel {
        case .landing(let vm):
            MyLandingView(viewModel: vm.myViewModel)
        case .detail(let vm):
            DetailView(viewModel: vm.detailViewModel)
        }
    }
}
```

**4. Use in ViewModels:**

```swift
// Sources/ViewModels/MyViewModel.swift
struct MyViewModel {
    let navigationClient: NavigationClient<MyFeatureDestination>
    let dataClient: DataClient
    
    func navigateToDetail(id: String) {
        navigationClient.push(.internal(.detail(id: id)))
    }
    
    func dismiss() {
        navigationClient.dismiss()
    }
}
```

### Testing Example

```swift
@Test func testNavigationToDetail() async throws {
    var capturedDestination: MyFeatureDestination?
    
    let navigationClient = NavigationClient<MyFeatureDestination>(
        present: { dest, _ in capturedDestination = dest },
        dismiss: {},
        close: {}
    )
    
    let viewModel = MyViewModel(
        navigationClient: navigationClient,
        dataClient: .mock
    )
    
    viewModel.navigateToDetail(id: "123")
    
    #expect(capturedDestination == .detail(id: "123"))
}
```

