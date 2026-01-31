# ModularNavigation Cookbook

A practical guide to common navigation patterns in modular iOS apps.

## Table of Contents

1. [Adding Navigation to a Module](#1-adding-navigation-to-a-module)
2. [Connecting Two Modules](#2-connecting-two-modules)
3. [Setting Up Tab Navigation](#3-setting-up-tab-navigation)
4. [Using NavigationClient in ViewModels](#4-using-navigationclient-in-viewmodels)
5. [Testing Navigation](#5-testing-navigation)
6. [SwiftUI Previews](#6-swiftui-previews)

---

## 1. Adding Navigation to a Module

Follow these steps to add ModularNavigation to a new feature module.

### Step 1: Create the Module Namespace

```swift
// Sources/MyModule/MyModule.swift

/// Namespace for MyModule
public enum MyModule { }
```

### Step 2: Define Your Destination Enum

Create a `Navigation` folder in your module's `Sources` directory:

```swift
// Sources/MyModule/Navigation/MyModuleDestination.swift
import ModularNavigation
import SwiftUI

public extension MyModule {
    struct Destination: Hashable {
        /// Destinations exposed to external modules
        public enum Public: Hashable {
            case main
            case settings
        }
        
        /// Destinations only accessible within this module
        enum Internal: Hashable {
            case detail(id: String)
            case editForm
        }
        
        /// Destinations that navigate to other modules
        enum External: Hashable {
            case otherModule
        }
        
        enum DestinationType: Hashable {
            case `public`(Public)
            case `internal`(Internal)
            case external(External)
        }
        
        var type: DestinationType
        
        // Public initializer only accepts Public destinations
        public init(_ destination: Public) {
            self.type = .public(destination)
        }
        
        init(_ destination: Internal) {
            self.type = .internal(destination)
        }
        
        init(_ destination: External) {
            self.type = .external(destination)
        }
        
        public static func `public`(_ destination: Public) -> Self {
            self.init(destination)
        }
        
        static func `internal`(_ destination: Internal) -> Self {
            self.init(destination)
        }
        
        static func external(_ destination: External) -> Self {
            self.init(destination)
        }
    }
}

// MARK: - Entry Point

public extension MyModule {
    typealias Entry = ModuleEntry<Destination, DestinationView>
}
```

### Step 3: Create the ViewState Enum

```swift
// Sources/MyModule/Navigation/MyModuleDestinationViewState.swift
import ModularNavigation
import OtherModule

extension MyModule {
    enum DestinationViewState {
        // Public destinations
        case main(MainViewModel)
        case settings(SettingsViewModel)
        
        // Internal destinations
        case detail(DetailViewModel)
        case editForm(EditFormViewModel)
        
        // External destinations (hold the entry to other modules)
        case otherModule(OtherModule.Entry)
    }
}
```

### Step 4: Create the DestinationView

```swift
// Sources/MyModule/Navigation/MyModuleDestinationView.swift
import ModularNavigation
import OtherModule
import SwiftUI

public extension MyModule {
    struct DestinationView: View {
        let viewState: DestinationViewState
        let mode: NavigationMode
        let client: NavigationClient<Destination>
        
        init(
            viewState: DestinationViewState,
            mode: NavigationMode,
            client: NavigationClient<Destination>
        ) {
            self.viewState = viewState
            self.mode = mode
            self.client = client
        }
        
        public var body: some View {
            switch viewState {
            // Public destinations
            case .main(let viewModel):
                MainRootView(viewModel: viewModel)
            case .settings(let viewModel):
                SettingsRootView(viewModel: viewModel)
                
            // Internal destinations
            case .detail(let viewModel):
                DetailRootView(viewModel: viewModel)
            case .editForm(let viewModel):
                EditFormRootView(viewModel: viewModel)
                
            // External destinations - use NavigationDestinationView
            case .otherModule(let entry):
                NavigationDestinationView(
                    previousClient: client,
                    mode: mode,
                    entry: entry
                )
            }
        }
    }
}
```

### Step 5: Create the Live Entry

```swift
// Sources/MyModule/Navigation/MyModuleDestination+Live.swift
import ModularNavigation
import OtherModule
import SwiftUI

public extension MyModule {
    @MainActor
    static func liveEntry(
        at publicDestination: Destination.Public,
        dependencies: Dependencies
    ) -> Entry {
        Entry(
            entryDestination: .public(publicDestination),
            builder: { destination, mode, navigationClient in
                let viewState: DestinationViewState
                
                switch destination.type {
                case .public(let publicDestination):
                    switch publicDestination {
                    case .main:
                        viewState = .main(
                            MainViewModel(
                                navigationClient: navigationClient,
                                dataClient: dependencies.dataClient
                            )
                        )
                    case .settings:
                        viewState = .settings(
                            SettingsViewModel(
                                navigationClient: navigationClient
                            )
                        )
                    }
                    
                case .internal(let internalDestination):
                    switch internalDestination {
                    case .detail(let id):
                        viewState = .detail(
                            DetailViewModel(
                                id: id,
                                navigationClient: navigationClient,
                                dataClient: dependencies.dataClient
                            )
                        )
                    case .editForm:
                        viewState = .editForm(
                            EditFormViewModel(navigationClient: navigationClient)
                        )
                    }
                    
                case .external(let externalDestination):
                    switch externalDestination {
                    case .otherModule:
                        let otherDeps = dependencies.buildChild(OtherModule.Dependencies.self)
                        let entry = OtherModule.liveEntry(at: .main, dependencies: otherDeps)
                        viewState = .otherModule(entry)
                    }
                }
                
                return DestinationView(
                    viewState: viewState,
                    mode: mode,
                    client: navigationClient
                )
            }
        )
    }
}
```

### Step 6: Create the Mock Entry

```swift
// Sources/MyModule/Navigation/MyModuleDestination+Mock.swift
import ModularNavigation
import OtherModule
import SwiftUI

public extension MyModule {
    @MainActor
    static func mockEntry(
        at publicDestination: Destination.Public = .main
    ) -> Entry {
        Entry(
            entryDestination: .public(publicDestination),
            builder: { destination, mode, navigationClient in
                let viewState: DestinationViewState
                
                switch destination.type {
                case .public(let publicDestination):
                    switch publicDestination {
                    case .main:
                        viewState = .main(
                            MainViewModel(
                                navigationClient: navigationClient,
                                dataClient: MockDataClient()
                            )
                        )
                    case .settings:
                        viewState = .settings(
                            SettingsViewModel(navigationClient: navigationClient)
                        )
                    }
                    
                case .internal(let internalDestination):
                    switch internalDestination {
                    case .detail(let id):
                        viewState = .detail(
                            DetailViewModel(
                                id: id,
                                navigationClient: navigationClient,
                                dataClient: MockDataClient()
                            )
                        )
                    case .editForm:
                        viewState = .editForm(
                            EditFormViewModel(navigationClient: navigationClient)
                        )
                    }
                    
                case .external(let externalDestination):
                    switch externalDestination {
                    case .otherModule:
                        let entry = OtherModule.mockEntry()
                        viewState = .otherModule(entry)
                    }
                }
                
                return DestinationView(
                    viewState: viewState,
                    mode: mode,
                    client: navigationClient
                )
            }
        )
    }
}
```

---

## 2. Connecting Two Modules

When ScreenA needs to navigate to ScreenB:

### In ScreenA's Destination

```swift
// ScreenA's Destination enum includes:
enum External: Hashable {
    case screenB
}
```

### In ScreenA's ViewState

```swift
enum DestinationViewState {
    case main(ScreenAViewModel)
    case screenB(ScreenB.Entry)  // Hold ScreenB's entry
}
```

### In ScreenA's Live Entry Builder

```swift
case .external(let externalDestination):
    switch externalDestination {
    case .screenB:
        let screenBDependencies = dependencies.buildChild(ScreenB.Dependencies.self)
        let entry = ScreenB.liveEntry(at: .main, dependencies: screenBDependencies)
        viewState = .screenB(entry)
    }
```

### In ScreenA's DestinationView

```swift
case .screenB(let entry):
    NavigationDestinationView(
        previousClient: client,
        mode: mode,
        entry: entry
    )
```

### Triggering Navigation from ScreenA's ViewModel

```swift
func navigateToScreenB() {
    navigationClient.presentSheet(.external(.screenB))
}
```

---

## 3. Setting Up Tab Navigation

### Define the Tab Coordinator

```swift
// TabCoordinator/Navigation/TabCoordinatorDestination.swift
public extension TabCoordinator {
    struct Destination: Hashable {
        enum External: Hashable {
            case firstTab
            case secondTab
            case thirdTab
        }
        
        enum DestinationType: Hashable {
            case external(External)
        }
        
        var type: DestinationType
        
        init(_ destination: External) {
            self.type = .external(destination)
        }
        
        static func external(_ destination: External) -> Self {
            self.init(destination)
        }
    }
}

public extension TabCoordinator {
    typealias Builder = DestinationBuilder<Destination, DestinationView>
}
```

### Create the Tab Builder

```swift
// TabCoordinator/Navigation/TabCoordinatorDestination+Live.swift
public extension TabCoordinator {
    @MainActor
    static func liveBuilder(dependencies: Dependencies) -> Builder {
        { destination, mode, navigationClient in
            let viewState: DestinationViewState
            
            switch destination.type {
            case .external(let externalDestination):
                switch externalDestination {
                case .firstTab:
                    let deps = dependencies.buildChild(ScreenA.Dependencies.self)
                    viewState = .firstTab(ScreenA.liveEntry(at: .main, dependencies: deps))
                case .secondTab:
                    let deps = dependencies.buildChild(ScreenB.Dependencies.self)
                    viewState = .secondTab(ScreenB.liveEntry(at: .main, dependencies: deps))
                case .thirdTab:
                    let deps = dependencies.buildChild(ScreenC.Dependencies.self)
                    viewState = .thirdTab(ScreenC.liveEntry(at: .main, dependencies: deps))
                }
            }
            
            return DestinationView(
                viewState: viewState,
                mode: mode,
                client: navigationClient
            )
        }
    }
}
```

### Create the Tab View

```swift
// TabCoordinator/TabCoordinatorRootView.swift
public struct TabCoordinatorRootView: View {
    @State private var viewModel: TabCoordinatorViewModel
    
    public var body: some View {
        NavigationTabView(
            selectedTab: $viewModel.currentTab,
            rootClient: viewModel.navigationClient,
            builder: viewModel.builder,
            tabModels: [
                NavigationTabModel(
                    label: Label("First", systemImage: "1.circle"),
                    destination: .external(.firstTab),
                    tab: .first
                ),
                NavigationTabModel(
                    label: Label("Second", systemImage: "2.circle"),
                    destination: .external(.secondTab),
                    tab: .second
                ),
                NavigationTabModel(
                    label: Label("Third", systemImage: "3.circle"),
                    destination: .external(.thirdTab),
                    tab: .third
                )
            ]
        )
    }
}
```

---

## 4. Using NavigationClient in ViewModels

The `NavigationClient` provides a testable interface for navigation:

```swift
@MainActor
@Observable
final class MyViewModel {
    private let navigationClient: NavigationClient<MyModule.Destination>
    
    init(navigationClient: NavigationClient<MyModule.Destination>) {
        self.navigationClient = navigationClient
    }
    
    // Push navigation (adds to navigation stack)
    func showDetail(id: String) {
        navigationClient.push(.internal(.detail(id: id)))
    }
    
    // Sheet presentation
    func showSettings() {
        navigationClient.presentSheet(.public(.settings))
    }
    
    // Full screen cover
    func showOnboarding() {
        navigationClient.presentFullScreenCover(.internal(.onboarding))
    }
    
    // Navigate to another module
    func showOtherModule() {
        navigationClient.push(.external(.otherModule))
    }
    
    // Dismiss current screen
    func dismiss() {
        navigationClient.dismiss()
    }
    
    // Close entire modal flow
    func close() {
        navigationClient.close()
    }
    
    // Pop to root of navigation stack
    func popToRoot() {
        navigationClient.popToRoot()
    }
}
```

### NavigationClient Methods

| Method | Behavior |
|--------|----------|
| `push(_:)` | Adds destination to navigation stack |
| `presentSheet(_:detents:)` | Shows destination as modal sheet |
| `presentFullScreenCover(_:)` | Shows destination as full screen cover |
| `dismiss()` | Smart dismiss: sheet/cover → pop → parent |
| `close()` | Always dismisses entire modal context |
| `popToRoot()` | Clears navigation stack to root |

---

## 5. Testing Navigation

### Testing ViewModel Navigation Calls

```swift
import Testing
@testable import MyModule

@Test
func testNavigatesToDetail() async throws {
    var capturedDestination: MyModule.Destination?
    var capturedMode: NavigationMode?
    
    let mockClient = NavigationClient<MyModule.Destination>.mock(
        present: { destination, mode in
            capturedDestination = destination
            capturedMode = mode
        }
    )
    
    let viewModel = MyViewModel(navigationClient: mockClient)
    
    viewModel.showDetail(id: "123")
    
    #expect(capturedDestination == .internal(.detail(id: "123")))
    #expect(capturedMode == .push)
}

@Test
func testDismiss() async throws {
    var dismissCalled = false
    
    let mockClient = NavigationClient<MyModule.Destination>.mock(
        dismiss: { dismissCalled = true }
    )
    
    let viewModel = MyViewModel(navigationClient: mockClient)
    
    viewModel.dismiss()
    
    #expect(dismissCalled)
}
```

### Creating Mock NavigationClient

```swift
let mockClient = NavigationClient<MyModule.Destination>.mock(
    present: { destination, mode in /* capture or verify */ },
    dismiss: { /* capture or verify */ },
    popToRoot: { /* capture or verify */ },
    close: { /* capture or verify */ }
)
```

---

## 6. SwiftUI Previews

### Preview a Single Module

```swift
#Preview {
    let entry = MyModule.mockEntry()
    let rootClient = NavigationClient<RootDestination>.root()
    
    NavigationDestinationView(
        previousClient: rootClient,
        mode: .root,
        entry: entry
    )
}
```

### Preview a Specific Destination

```swift
#Preview("Settings Screen") {
    let entry = MyModule.mockEntry(at: .settings)
    let rootClient = NavigationClient<RootDestination>.root()
    
    NavigationDestinationView(
        previousClient: rootClient,
        mode: .root,
        entry: entry
    )
}
```

### Preview with Custom Mock Views

For testing navigation flow without full implementations:

```swift
struct MockMyModuleDestinationView: View {
    let destination: MyModule.Destination
    
    var body: some View {
        switch destination.type {
        case .public(let pub):
            switch pub {
            case .main: Color.blue.overlay(Text("Main"))
            case .settings: Color.green.overlay(Text("Settings"))
            }
        case .internal(let int):
            switch int {
            case .detail(let id): Color.orange.overlay(Text("Detail: \(id)"))
            case .editForm: Color.purple.overlay(Text("Edit Form"))
            }
        case .external(let ext):
            switch ext {
            case .otherModule: Color.red.overlay(Text("Other Module"))
            }
        }
    }
}

#Preview("Navigation Flow") {
    let mockBuilder: DestinationBuilder<MyModule.Destination, MockMyModuleDestinationView> = { destination, _, _ in
        MockMyModuleDestinationView(destination: destination)
    }
    
    let entry = ModuleEntry(
        entryDestination: .public(.main),
        builder: mockBuilder
    )
    
    let rootClient = NavigationClient<RootDestination>.root()
    
    NavigationDestinationView(
        previousClient: rootClient,
        mode: .root,
        entry: entry
    )
}
```

---

## Quick Reference

### Module Public API Surface

```swift
public extension MyModule {
    // Types
    struct Destination { ... }
    struct DestinationView: View { ... }
    typealias Entry = ModuleEntry<Destination, DestinationView>
    
    // Entry factories
    @MainActor static func liveEntry(at:dependencies:) -> Entry
    @MainActor static func mockEntry(at:) -> Entry
}
```

### File Structure

```
MyModule/
├── Sources/
│   └── MyModule/
│       ├── MyModule.swift                    # Namespace
│       ├── Dependencies/
│       │   └── MyModuleDependencies.swift
│       ├── Navigation/
│       │   ├── MyModuleDestination.swift          # Destination enum + Entry typealias
│       │   ├── MyModuleDestination+Live.swift     # liveEntry factory
│       │   ├── MyModuleDestination+Mock.swift     # mockEntry factory
│       │   ├── MyModuleDestinationView.swift      # DestinationView
│       │   └── MyModuleDestinationViewState.swift # ViewState enum
│       ├── MyModuleRootView.swift
│       └── MyModuleViewModel.swift
└── Tests/
    └── ...
```

### Destination Type Categories

| Category | Purpose | Visibility |
|----------|---------|------------|
| `Public` | Entry points for external modules | Public enum |
| `Internal` | Navigation within the module | Internal enum |
| `External` | Navigation to other modules | Internal enum |

---

## Common Patterns

### Passing Data Between Screens

Use associated values in your destination enum:

```swift
enum Internal: Hashable {
    case detail(id: String)
    case edit(item: Item)
    case preview(url: URL)
}
```

### Conditional Navigation

Handle in your ViewModel:

```swift
func handleAction() {
    if isAuthenticated {
        navigationClient.push(.internal(.dashboard))
    } else {
        navigationClient.presentSheet(.internal(.login))
    }
}
```

### Dismissing After Action

```swift
func save() async {
    await saveData()
    navigationClient.dismiss()
}
```
