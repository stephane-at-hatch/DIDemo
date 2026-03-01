# HatchModularNavigation Cookbook

A practical guide to common navigation patterns in the Hatch iOS app.

## Table of Contents

1. [Adding Navigation to a Module](#1-adding-navigation-to-a-module)
2. [Connecting Two Modules](#2-connecting-two-modules-together)
3. [Setting Up Tab-Based Navigation](#3-setting-up-tab-based-navigation)
4. [Using the Claude AI Skill](#4-using-the-ios-modular-navigation-skill)

---

## 1. Adding Navigation to a Module

Follow these steps to add HatchModularNavigation to a new feature module.

### Step 1: Define Your Destination Enum

Create a `Navigation` folder in your module's `Sources` directory:

```swift
// Sources/Navigation/MyFeatureDestination.swift
import HatchModularNavigation
import SwiftUI

/// All possible destinations within MyFeature
/// Separate into those you want to expose to other modules
/// and those you only want to be able to see within the module
public struct MyFeatureDestination: Hashable {
    public enum Public: Hashable {
        case landing
        case settings
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

```

### Step 2: Create the Destination Builder

```swift
// Sources/Navigation/MyFeatureDestination.swift (continued)

/// Generic builder for MyFeature destinations
@MainActor
public struct MyFeatureDestinationBuilder<DestinationView: View> {
    public let buildDestination: DestinationBuilder<MyFeatureDestination, DestinationView>
    
    public init(
        buildDestination: @escaping DestinationBuilder<MyFeatureDestination, DestinationView>
    ) {
        self.buildDestination = buildDestination
    }
}
```

### Step 3: Create Destination-Specific ViewModels

You can use the wrapper ViewModel pattern shown here if you need to collect multiple objects. In some cases it might be cleaner to just directly pass you

```swift
// Sources/Navigation/MyFeatureDestinationViewModel.swift
import HatchModularNavigation
import SwiftUI

// MARK: - Destination-Specific ViewModels

struct MyFeatureLandingDestinationViewModel {
    let landingViewModel: LandingViewModel
    let additionalData: SomeType
}

struct MyFeatureDetailDestinationViewModel {
    let detailViewModel: DetailViewModel
    ...
}

struct MyFeatureSettingsDestinationViewModel {
    let settingsViewModel: SettingsViewModel
    ...
}

// MARK: - ViewModel Enum

enum MyFeatureDestinationViewModel {
    case landing(MyFeatureLandingDestinationViewModel)
    case detail(MyFeatureDetailDestinationViewModel)
    case settings(MyFeatureSettingsDestinationViewModel)
}
```

or if you don't need to collect any more contextual data outside of the view's standard ViewModel, you can simply build it like this:

```swift
enum MyFeatureDestinationViewModel {
    case landing(LandingViewModel)
    case detail(DetailViewModel)
    case settings(SettingsViewModel)
}
```

### Step 4: Create the DestinationView

This view become's the contextual destinaion builder for all destinations exposed by this module

```swift
// Sources/Navigation/MyFeatureDestinationView.swift
import HatchModularNavigation
import SwiftUI

public struct MyFeatureDestinationView: View {
    let viewModel: MyFeatureDestinationViewModel
    let mode: NavigationMode
    let client: NavigationClient<MyFeatureDestination>
    
    init(
        viewModel: MyFeatureDestinationViewModel,
        mode: NavigationMode,
        client: NavigationClient<MyFeatureDestination>
    ) {
        self.viewModel = viewModel
        self.mode = mode
        self.client = client
    }
    
    public var body: some View {
        switch viewModel {
        case .landing(let vm):
            landingView(vm)
        case .detail(let vm):
            detailView(vm)
        case .settings(let vm):
            settingsView(vm)
        }
    }
    
    // MARK: - Destination Views
    
    // use separate builders for complex views
    func landingView(_ vm: MyFeatureLandingDestinationViewModel) -> some View {
	    LandingView(viewModel: vm.landingViewModel)
    }
    
    func detailView(_ vm: MyFeatureDetailDestinationViewModel) -> some View {
        DetailView(viewModel: vm.detailViewModel)
    }
    
    func settingsView(_ vm: MyFeatureSettingsDestinationViewModel) -> some View {
        SettingsView(viewModel: vm.settingsViewModel)
    }
}
```
or, for simple views just do it all inline:

```swift
    public var body: some View {
        switch viewModel {
        case .landing(let vm):
            LandingView(viewModel: vm.landingViewModel)
        case .detail(let vm):
            DetailView(viewModel: vm.detailViewModel)
        case .settings(let vm):
            SettingsView(viewModel: vm.settingsViewModel)
        }
    }
```

### Step 5: Create Live and Mock Builders

```swift
// Sources/Navigation/MyFeatureDestination+Live.swift
import HatchModularNavigation

@MainActor
extension MyFeatureDestination {
    public static func liveBuilder(
        dataClient: DataClient,
        analyticsClient: AnalyticsClient
    ) -> MyFeatureDestinationBuilder<MyFeatureDestinationView> {
        MyFeatureDestinationBuilder { destination, mode, coordinator in
            let viewModel: MyFeatureDestinationViewModel = switch destination.type {
            case .public(let publicDestination):
                switch publicDestination {
                    case .landing:
                        .landing(
                            MyFeatureLandingDestinationViewModel(
                                myViewModel: MyViewModel(
                                    navigationClient: NavigationClient(coordinator: coordinator),
                                    dataClient: dataClient
                                )
                            )
                        )
                    case .settings:
                        .settings(
                            MyFeatureSettingsDestinationViewModel(
                                settingsViewModel: SettingsViewModel(
                                    navigationClient: NavigationClient(coordinator: coordinator)
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
                                navigationClient: NavigationClient(coordinator: coordinator),
                                dataClient: dataClient
                            )
                        )
                    )
                }
            }
            return MyFeatureDestinationView(
                viewModel: viewModel,
                mode: mode,
                coordinator: coordinator
            )
        }
    }
}
```

```swift
// Sources/Navigation/MyFeatureDestination+Mock.swift
import HatchModularNavigation
import SwiftUI

@MainActor
extension MyFeatureDestination {
    public static func mockBuilder() -> MyFeatureDestinationBuilder<MyFeatureDestinationView> {
        MyFeatureDestinationBuilder { destination, mode, coordinator in
            let viewModel: MyFeatureDestinationViewModel = switch destination.type {
            case .public(let publicDestination):
                switch publicDestination {
                    case .landing:
                        .landing(
                            MyFeatureLandingDestinationViewModel(
                                myViewModel: MyViewModel(
                                    navigationClient: NavigationClient(coordinator: coordinator),
                                    dataClient: .mock
                                )
                            )
                        )
                    case .settings:
                        .settings(
                            MyFeatureSettingsDestinationViewModel(
                                settingsViewModel: SettingsViewModel(
                                    navigationClient: NavigationClient(coordinator: coordinator)
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
                                navigationClient: NavigationClient(coordinator: coordinator),
                                dataClient: .mock,
                                analyticsClient: .mock
                            )
                        )
                    )
                }
            }
            return MyFeatureDestinationView(
                viewModel: viewModel,
                mode: mode,
                coordinator: coordinator
            )
        }
    }
}
```


### Step 6: Use NavigationClient in Your ViewModels

```swift
// Sources/ViewModels/LandingViewModel.swift
import HatchModularNavigation

struct LandingViewModel {
    let navigationClient: NavigationClient<MyFeatureDestination>
    let dataClient: DataClient
    
    func navigateToDetail(id: String) {
        navigationClient.push(.internal(.detail(id: id)))
    }
    
    func navigateToSettings() {
        navigationClient.presentSheet(.public(.settings))
    }
    
    func dismiss() {
        navigationClient.dismiss()
    }
}
```

**✅ That's it!** Your module now has full navigation support.

---

## 2. Connecting Two Modules Together

When a parent module needs to navigate to a child feature module, connect them through builders.

### Example: Connecting ParentScreen to ChildFeature

**Parent module structure:**
```swift
// In ParentScreen/Sources/Navigation/ParentDestination.swift
// If all of your destinations are public, you can expose them in a simple enum
public enum ParentDestination: Hashable {
    case home
    case childFeature  // ← This will navigate to the child module
    case settings
}
```

**Connect in the Parent's Live Builder:**

```swift
// In ParentScreen/Sources/Navigation/ParentDestination+Live.swift
import ChildFeature  // ← Import the child module

@MainActor
extension ParentDestination {
    public static func liveBuilder(
        // Parent's dependencies
        parentClient: ParentClient,
        // Child's dependencies
        childDataClient: ChildDataClient,
        childAnalyticsClient: ChildAnalyticsClient
    ) -> ParentDestinationBuilder<ParentDestinationView> {
        ParentDestinationBuilder { destination, mode, coordinator in
            let viewModel: ParentDestinationViewModel = switch destination {
            case .home:
                .home(
                    ParentHomeDestinationViewModel(
                        homeViewModel: ParentHomeViewModel(
                            navigationClient: NavigationClient(coordinator: coordinator),
                            parentClient: parentClient
                        )
                    )
                )
            
            case .childFeature:
                // Connect to child feature's builder
                .childFeature(
                    ParentChildFeatureDestinationViewModel(
                        buildDestination: ChildFeatureDestination.liveBuilder(
                            dataClient: childDataClient,
                            analyticsClient: childAnalyticsClient
                        ).buildDestination
                    )
                )
            
            case .settings:
                .settings(
                    ParentSettingsDestinationViewModel(
                        settingsViewModel: ParentSettingsViewModel(
                            navigationClient: NavigationClient(coordinator: coordinator)
                        )
                    )
                )
            }
            
            return ParentDestinationView(
                viewModel: viewModel,
                mode: mode,
                coordinator: coordinator
            )
        }
    }
}
```

**Update Parent's DestinationViewModel:**

```swift
// In ParentScreen/Sources/Navigation/ParentDestinationViewModel.swift
import ChildFeature
import HatchModularNavigation

// MARK: - Destination-Specific ViewModels

struct ParentHomeDestinationViewModel {
    let homeViewModel: ParentHomeViewModel
}

struct ParentChildFeatureDestinationViewModel {
    // Store the child's builder function
    let buildDestination: DestinationBuilder<ChildFeatureDestination, ChildFeatureDestinationView>
}

struct ParentSettingsDestinationViewModel {
    let settingsViewModel: ParentSettingsViewModel
}

// MARK: - ViewModel Enum

enum ParentDestinationViewModel {
    case home(ParentHomeDestinationViewModel)
    case childFeature(ParentChildFeatureDestinationViewModel)
    case settings(ParentSettingsDestinationViewModel)
}
```

**Update Parent's DestinationView:**

```swift
// In ParentScreen/Sources/Navigation/ParentDestinationView.swift
import ChildFeature
import HatchModularNavigation
import SwiftUI

public struct ParentDestinationView: View {
    let viewModel: ParentDestinationViewModel
    let mode: NavigationMode
    let client: NavigationClient<ParentDestination>
    
    public var body: some View {
        switch viewModel {
        case .home(let vm):
            homeView(vm)
        case .childFeature(let vm):
            childFeatureView(vm)
        case .settings(let vm):
            settingsView(vm)
        }
    }
    
    // MARK: - Destination Views
    
    func homeView(_ vm: ParentHomeDestinationViewModel) -> some View {
        ParentHomeView(viewModel: vm.homeViewModel)
    }
    
    func childFeatureView(_ vm: ParentChildFeatureDestinationViewModel) -> some View {
        // Any time you are building a view from another module (or in a new destination context)
        // Use NavigationDestinationView to create a new navigation context
        NavigationDestinationView(
            previousClient: client,
            mode: mode,
            destination: .landing,  // ← Child's initial destination
            builder: vm.buildDestination
        )
    }
    
    func settingsView(_ vm: ParentSettingsDestinationViewModel) -> some View {
        ParentSettingsView(viewModel: vm.settingsViewModel)
    }
}
```

**Navigate from Parent to Child:**

```swift
// In Parent's ViewModel
struct ParentHomeViewModel {
    let navigationClient: NavigationClient<ParentDestination>
    
    func openChildFeature() {
        navigationClient.push(.childFeature)
    }
}
```

**✅ Done!** The parent module can now navigate to the child feature module.

---

## 3. Setting Up Tab-Based Navigation

Use `NavigationTabView` to create a tab bar with independent navigation per tab.

### Example: Creating a Three-Tab Interface

```swift
// In MyApp/Sources/Views/MyAppTabBarView.swift
import HatchModularNavigation
import HomeFeature
import ProfileFeature
import SettingsFeature
import SwiftUI

enum AppTab: Hashable, CaseIterable {
    case home
    case profile
    case settings
}

public struct MyAppTabBarView<Content: View>: View {
    @State private var selectedTab: AppTab = .home
    
    private let rootClient: NavigationClient<RootDestination>
    private let builder: DestinationBuilder<MyAppDestination, Content>    
    private let tabModels: [NavigationTabModel<MyAppDestination, Content>]
    
    public init(
        rootClient: NavigationClient<RootDestination>,
        builder: @escaping DestinationBuilder<MyAppDestination, Content>
    ) {
        self.rootClient = rootClient
        self.builder = builder
        
        // Define tab models
        self.tabModels = [
            NavigationTabModel(
                label: Label("Home", systemImage: "house.fill"),
                destination: .home
            ),
            NavigationTabModel(
                label: Label("Profile", systemImage: "person.fill"),
                destination: .profile
            ),
            NavigationTabModel(
                label: Label("Settings", systemImage: "gear"),
                destination: .settings
            )
        ]
    }
    
    public var body: some View {
        NavigationTabView<AppTab, MyAppDestination, Content>(
            selectedTab: $selectedTab,
            rootClient: rootClient,
            builder: builder,
            tabModels: tabModels
        )
    }
}
```

**Define Tab Destinations:**

```swift
// In MyApp/Sources/Navigation/MyAppDestination.swift
import HatchModularNavigation
import SwiftUI

public enum MyAppDestination: Hashable {
    case home
    case profile
    case settings
}

@MainActor
public struct MyAppDestinationBuilder<DestinationView: View> {
    public let buildDestination: DestinationBuilder<MyAppDestination, DestinationView>
       
    public init(
        buildDestination: @escaping DestinationBuilder<MyAppDestination, DestinationView>
    ) {
        self.buildDestination = buildDestination
    }
}
```

**Create the Tab Builder:**

```swift
// In MyApp/Sources/Navigation/MyAppDestination+Live.swift
import HomeFeature
import ProfileFeature
import SettingsFeature
import HatchModularNavigation

@MainActor
extension MyAppDestination {
    public static func liveBuilder(
        homeClient: HomeClient,
        profileClient: ProfileClient,
        settingsClient: SettingsClient
    ) -> MyAppDestinationBuilder<MyAppDestinationView> {
        MyAppDestinationBuilder { destination, mode, coordinator in
            let viewModel: MyAppDestinationViewModel = switch destination {
            case .home:
                .home(
                    MyAppHomeDestinationViewModel(
                        buildDestination: HomeFeatureDestination.liveBuilder(
                            homeClient: homeClient
                        ).buildDestination
                    )
                )
            case .profile:
                .profile(
                    MyAppProfileDestinationViewModel(
                        buildDestination: ProfileFeatureDestination.liveBuilder(
                            profileClient: profileClient
                        ).buildDestination
                    )
                )
            case .settings:
                .settings(
                    MyAppSettingsDestinationViewModel(
                        buildDestination: SettingsFeatureDestination.liveBuilder(
                            settingsClient: settingsClient
                        ).buildDestination
                    )
                )
            }
            
            return MyAppDestinationView(
                viewModel: viewModel,
                mode: mode,
                coordinator: coordinator
            )
        }
    }
}
```

**Wire It Up at App Level:**

```swift
// In MyApp/Sources/Views/MyAppScreen.swift
import SwiftUI

public struct MyAppScreen: View {
    let tabView: MyAppTabBarView<MyAppDestinationView>
    
    public init(
        homeClient: HomeClient,
        profileClient: ProfileClient,
        settingsClient: SettingsClient
    ) {
        let tabDestinationBuilder = MyAppDestination.liveBuilder(
            homeClient: homeClient,
            profileClient: profileClient,
            settingsClient: settingsClient
        )
        
        let rootClient = NavigationClient<RootDestination>.root()
        
        self.tabView = MyAppTabBarView(
            builder: tabDestinationBuilder.buildDestination,
            rootClient: rootClient
        )
    }
    
    public var body: some View {
        tabView
    }
}
```

**✅ Complete!** Each tab now has independent navigation state.

---

## 4. Using the ios_modular_navigation Skill

The `ios_modular_navigation` skill helps Claude AI assist with HatchModularNavigation code.

### What is the Skill?

The skill is a reference document located at:
```
mobile/.claude/skills/ios_modular_navigation/
```

It contains:
- Complete navigation patterns and examples
- Best practices for the Hatch codebase
- Common troubleshooting scenarios
- Architecture decision rationale

### How to Use It with Claude

**1. Reference the skill in your prompt:**
```
Using the ios_modular_navigation skill, help me add navigation to MyFeature module.
```

**2. Ask for specific patterns:**
```
According to the ios_modular_navigation skill, how should I connect ParentModule to ChildModule?
```

**3. Request reviews:**
```
Review my navigation setup using the ios_modular_navigation skill. Here's my code: [paste code]
```

**4. Get troubleshooting help:**
```
My navigation coordinator isn't creating a new path. Can you check this against the ios_modular_navigation skill?
```

### What Claude Can Help With

✅ **Code Generation:**
- "Generate the navigation files for MyFeature with destinations: landing, detail, settings"
- "Create a live builder for MyModule that depends on DataClient and AnalyticsClient"

✅ **Module Connection:**
- "Help me connect ParentScreen to ChildFeature"
- "Show me how to pass dependencies from parent to child module"

✅ **Tab Navigation:**
- "Set up a 4-tab navigation structure"
- "Add a new tab to my existing TabView"

✅ **Testing:**
- "Write tests for navigation in MyViewModel"
- "Create a mock NavigationClient for testing"

✅ **Debugging:**
- "My sheet isn't presenting, what's wrong?"
- "Deep linking isn't working, help me debug"

✅ **Code Review:**
- "Review my navigation setup for best practices"
- "Is my builder following the correct pattern?"

### Tips for Best Results

1. **Be specific about your module name and dependencies**
   - ❌ "Add navigation to my module"
   - ✅ "Add navigation to ProfileFeature with dependencies: ProfileClient, AnalyticsClient"

2. **Share relevant code when asking for reviews**
   ```
   Review this builder. Does it follow the ios_modular_navigation patterns?
   [paste your builder code]
   ```

3. **Ask for explanations when learning**
   ```
   Explain why we use NavigationDestinationView when connecting modules
   ```

4. **Request complete examples**
   ```
   Show me a complete example of setting up MyFeature from scratch with:
   - Landing screen
   - Detail screen with ID parameter
   - Settings sheet
   ```

### Skill Limitations

- The skill documents the **current** navigation architecture
- It may not cover **future** changes to the navigation system
- For architecture changes, consult with the iOS team first
- The skill is a **reference**, not a replacement for code review

---

## Quick Reference

### Common NavigationClient Methods

```swift
    /// Navigate to a destination with a specific presentation mode
    public let present: (Destination, NavigationMode) -> Void

    /// Dismiss the current screen (pops, dismisses sheet/cover, or calls dismissParent)
    public let dismiss: () -> Void

    /// Close the entire presentation context (always dismisses the modal flow)
    public let close: () -> Void
```

### Testing Navigation

```swift
import Testing

@Test func testNavigation() async throws {
    var captured: MyDestination?
    
    let client = NavigationClient<MyDestination>(
        present: { dest, _ in captured = dest },
        dismiss: {},
        close: {}
    )
    
    let viewModel = MyViewModel(navigationClient: client)
    viewModel.navigateToDetail(id: "123")
    
    #expect(captured == .detail(id: "123"))
}
```

### SwiftUI Preview with Mock Builder

```swift
#Preview {
    let builder = MyFeatureDestination.mockBuilder()
    let rootClient = NavigationClient<RootDestination>.root()
    
    NavigationDestinationView(
        previousClient: rootClient,
        mode: .root,
        destination: .public(.landing),
        builder: builder.buildDestination
    )
}
```

### Injecting custom destinations

In the production code we use `AdultScreenTabDestinationBuilder<AdultScreenDestinationView>`, but here we can use our custome view `MockAdultScreenDestinationView` to test out our navigation destinations. This is a handy way to write unit tests or to simply test out navigation flows in Preview.

```swift
    /// Simple mock view for previewing the tab structure without full feature implementations
    private struct MockAdultScreenDestinationView: View {
        let destination: AdultScreenDestination
        
        var body: some View {
            switch destination {
            case .home:
                Color.blue
            case .routine:
                Color.red
            case .library:
                Color.green
            }
        }
    }

    let mockBuilder = AdultScreenTabDestinationBuilder<MockAdultScreenDestinationView> { destination, _, _ in
        MockAdultScreenDestinationView(destination: destination)
    }
```

---

## Need Help?

- Check the **RFC document** for architectural details
- Use the **ios_modular_navigation skill** with Claude AI
- Review existing modules (Home, Routine, Library) for examples
- Ask the iOS Architecture team for guidance on complex scenarios
