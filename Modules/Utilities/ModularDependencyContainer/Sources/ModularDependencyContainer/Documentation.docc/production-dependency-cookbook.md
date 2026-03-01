# Modular Dependency Container — Production Cookbook

> **Purpose**: Step-by-step guide for adding modular dependency injection to an iOS feature module for production use.

---

## Overview

The modular dependency container replaces manual dependency threading with a declarative system. Each feature module declares its requirements via the `@DependencyRequirements` macro, and the container resolves them at runtime. Dependencies flow from parent to child through `buildChild` calls that match the navigation graph.

**Key principle:** Clients and services should NOT import `HatchModularDependencyContainer`. They are injected INTO the container. Only feature modules (with `*Dependencies.swift`) and the app's composition root import the container.

---

## Step 1: Identify Dependencies

Catalog what the feature needs. Check the ViewModel initializers and the `Destination+Live.swift` file for everything the feature uses.

| Category | Description | Example |
|---|---|---|
| **Inherited** | Sendable services/clients from parent | `ContentClient`, `SubscriptionClient` |
| **Keyed** | Same type registered with different keys | `HatchAnalyticsClient` with key `.amplitude` |
| **MainActor** | Services requiring main thread | `AdultRoutineCoordinator`, `AlarmStateProvider` |
| **Local** | Created by this module, not inherited by children | `RoutineStateProvider` |
| **Inputs** | Runtime values passed at navigation time | `HardwareProduct`, `MacAddress` |

---

## Step 2: Create the Dependencies File

**File location:**
```
[FeatureModule]/
└── Sources/
    └── Dependencies/
        └── [FeatureName]Dependencies.swift
```

### Leaf Module (no local registrations)

When a module only consumes dependencies without creating any of its own:

```swift
import HatchModularDependencyContainer
import HatchContentClient
import HatchVisualAssetsClient
// ... imports for each dependency type

@DependencyRequirements(
    [
        Requirement(ContentClient.self),
        Requirement(VisualAssetsClient.self)
    ],
    mainActor: [
        Requirement(AdultRoutineCoordinator.self)
    ],
    inputs: [
        InputRequirement(HardwareProduct.self),
        InputRequirement(MacAddress.self)
    ]
)
public struct MyFeatureDependencies: DependencyRequirements {}
```

The struct body is empty — the macro generates all the accessors.

### Module with Local Registrations

When a module creates dependencies for its own use (not inherited by children), implement `registerDependencies`:

```swift
public struct AdultRoutineDependencies: DependencyRequirements {
    public static func registerDependencies(in builder: DependencyBuilder<AdultRoutineDependencies>) {
        do {
            try builder.local.mainActor.registerSingleton(RoutineStateProvider.self) { container in
                let dependencies = Self(container)
                return RoutineStateProvider(
                    coordinator: dependencies.adultRoutineCoordinator,
                    contentClient: dependencies.contentClient,
                    deviceStateEmitter: dependencies.iotDeviceStateEmitter
                )
            }
        } catch {
            preconditionFailure("\(Self.self): Failed to register dependencies. Error: \(error).")
        }
    }
}
```

**Two factory patterns for resolving sub-dependencies:**

```swift
// Pattern A: Use Self(container) for convenient accessor names
try builder.local.mainActor.registerSingleton(MyProvider.self) { container in
    let dependencies = Self(container)
    return MyProvider(
        client: dependencies.contentClient,          // uses generated accessor
        coordinator: dependencies.adultRoutineCoordinator
    )
}

// Pattern B: Resolve directly from container (useful for non-requirement types)
try builder.mainActor.registerSingleton(BedtimeStateProvider.self) { container in
    let bedtimeDependencies = container.buildChild(BedtimeRemindersDependencies.self)
    return BedtimeStateProvider(dependencies: bedtimeDependencies)
}
```

### Composition Root (many composed dependencies)

Screens that act as composition roots register dependencies that downstream children will inherit:

```swift
public struct AdultScreenDependencies: DependencyRequirements {
    public static func registerDependencies(in builder: DependencyBuilder<AdultScreenDependencies>) {
        do {
            // Composed from declared requirements
            try builder.mainActor.registerSingleton(AdultRoutineCoordinator.self) { container in
                let dependencies = Self(container)
                return AdultRoutineCoordinator(coordinator: dependencies.routineCoordinating)
            }

            // Composed with sub-dependencies resolved from container
            try builder.mainActor.registerSingleton(AlarmStateProvider.self) { container in
                let dependencies = Self(container)
                return AlarmStateProvider(
                    coordinator: dependencies.adultRoutineCoordinator,
                    deviceStateEmitter: dependencies.iotDeviceStateEmitter,
                    visualAssetsClient: dependencies.visualAssetsClient,
                    contentClient: dependencies.contentClient
                )
            }

            // Override a requirement with a live implementation
            try builder.registerSingleton(UserDefaultsClient.self, key: BedtimeRemindersKey.goodnightPhone) { _ in
                UserDefaultsClient.live(
                    domain: .suite(name: AppGroupIdentifier.hatchSleepApp.appGroupIdentifier)
                )
            }

            // ... more registrations
        } catch {
            preconditionFailure("\(Self.self): Failed to register dependencies. Error: \(error).")
        }
    }
}
```

---

## Step 3: Requirement Macro Parameters

| Parameter | Purpose | Example |
|---|---|---|
| `Type.self` | The type to require | `ContentClient.self` |
| `key:` | Keyed registration | `key: AnalyticsKey.amplitude` |
| `accessorName:` | Custom property name | `accessorName: "iotActionSender"` |

### Common Type Patterns

```swift
// Simple type
Requirement(ContentClient.self)
// → dependencies.contentClient

// Keyed type
Requirement(HatchAnalyticsClient.self, key: AnalyticsKey.amplitude)
// → dependencies.amplitudeAnalyticsClient

// Protocol type
Requirement((any DeviceSettingsViewControllerProvider).self)
// → dependencies.deviceSettingsViewControllerProvider

// Custom accessor name
Requirement(IoTActionSenderClient.self, accessorName: "iotActionSender")
// → dependencies.iotActionSender

// Factory type
Requirement(IoTDeviceConnectionStateClient.Factory.self, accessorName: "iotDeviceConnectionStateFactory")
// → dependencies.iotDeviceConnectionStateFactory

// Input value
InputRequirement(HardwareProduct.self)
// → dependencies.hardwareProduct

// Input with custom accessor
InputRequirement(HA25ToolbarViewModel.self, accessorName: "toolbarViewModel")
// → dependencies.toolbarViewModel
```

---

## Step 4: Update Package.swift

Add the dependency on `HatchModularDependencyContainer`:

```swift
.target(
    name: "HatchMyFeature",
    dependencies: [
        // ... existing dependencies
        "HatchModularDependencyContainer",
    ]
),
```

---

## Step 5: Wire Up Navigation

### Destination+Live.swift

The `Destination+Live.swift` file is where dependencies meet navigation. The entry point receives the dependencies struct and uses it to construct ViewModels and child modules.

```swift
extension MyFeatureDestination {
    @MainActor
    public static func liveEntry(
        publicDestination: MyFeatureDestination.Public,
        dependencies: MyFeatureDependencies
    ) -> MyFeatureEntry {
        MyFeatureEntry(
            entryDestination: .public(publicDestination),
            builder: { destination, mode, navigationClient in
                let state: MyFeatureDestinationState = switch destination.type {

                // PUBLIC — screens this module owns
                case .public(let publicDestination):
                    switch publicDestination {
                    case .main:
                        .main(
                            MyFeatureViewModel(
                                dependencies: dependencies,
                                navigationClient: navigationClient
                            )
                        )
                    }

                // INTERNAL — sub-screens within this module
                case .internal(let internalDestination):
                    switch internalDestination {
                    case .detail(let item):
                        .detail(
                            DetailViewModel(
                                contentClient: dependencies.contentClient,
                                item: item,
                                navigationClient: navigationClient
                            )
                        )
                    }

                // EXTERNAL — child feature modules
                case .external(let externalDestination):
                    switch externalDestination {
                    case .alarm(let publicDestination):
                        .alarm(
                            AdultAlarmsDestination.liveEntry(
                                publicDestination: publicDestination,
                                dependencies: dependencies.buildChild(AdultAlarmsDependencies.self)
                            )
                        )
                    case .contentPreview(let publicDestination):
                        .contentPreview(
                            ContentPreviewDestination.liveEntry(
                                publicDestination: publicDestination,
                                dependencies: dependencies.buildChild(ContentPreviewDependencies.self),
                                backgroundColor: DSColorAdult.surfaceSecondary
                            )
                        )
                    }
                }

                return MyFeatureDestinationView(
                    state: state,
                    mode: mode,
                    client: navigationClient
                )
            }
        )
    }
}
```

### buildChild

`buildChild` creates a child container that inherits all registrations from the parent. The child's `registerDependencies` runs, adding any child-specific local registrations.

```swift
// Simple — child inherits everything it needs from parent
dependencies.buildChild(AdultAlarmsDependencies.self)

// With additional inputs — child needs runtime values
dependencies.buildChild(SomeChildDependencies.self) { childBuilder in
    childBuilder.provideInput(SomeValue.self, someRuntimeValue)
}
```

---

## Step 6: Update the ViewModel

### Recommended: Dual-Init Pattern

Keep the existing detailed initializer for test flexibility, and add a convenience initializer that unpacks from the dependencies struct:

```swift
@MainActor @Observable
final class MyFeatureViewModel {

    // MARK: - Convenience Init (used by Destination+Live)

    convenience init(
        dependencies: MyFeatureDependencies,
        navigationClient: NavigationClient<MyFeatureDestination>
    ) {
        self.init(
            contentClient: dependencies.contentClient,
            coordinator: dependencies.adultRoutineCoordinator,
            macAddress: dependencies.macAddress.rawValue,
            navigationClient: navigationClient
        )
    }

    // MARK: - Detailed Init (used by tests and previews)

    init(
        contentClient: ContentClient,
        coordinator: any RoutineCoordinating,
        macAddress: String,
        navigationClient: NavigationClient<MyFeatureDestination>
    ) {
        self.contentClient = contentClient
        self.coordinator = coordinator
        self.macAddress = macAddress
        self.navigationClient = navigationClient
    }
}
```

**Why dual-init?** The convenience init keeps the `Destination+Live.swift` clean. The detailed init preserves test flexibility — tests can inject individual dependencies without constructing a full container, which is important when the test needs a type that differs from what the container provides (e.g., injecting a bare `MockRoutineCoordinator` instead of the container's `AdultRoutineCoordinator` wrapper).

### Alternative: Dependencies-Only Init

For simpler ViewModels where tests will use the container:

```swift
init(
    dependencies: MyFeatureDependencies,
    navigationClient: NavigationClient<MyFeatureDestination>
) {
    self.contentClient = dependencies.contentClient
    self.macAddress = dependencies.macAddress.rawValue
    // ...
}
```

---

## Step 7: App Composition Root

At the top level (e.g., `ViewControllerFactory.swift`), create the root container and build the first child:

```swift
// Build root container
let dependencyBuilder = DependencyBuilder<AppRoot>()

do {
    try dependencyBuilder.registerSingleton(ContentClient.self) { _ in
        contentClient
    }
    try dependencyBuilder.registerSingleton(
        HatchAnalyticsClient.self,
        key: AnalyticsKey.amplitude
    ) { _ in
        amplitudeAnalyticsClient
    }
    // ... register all root-level dependencies
} catch {
    preconditionFailure("Failed to register dependencies. Error: \(error).")
}

let rootContainer = dependencyBuilder.freeze()

// Build the first child with runtime inputs
let screenDependencies = rootContainer.buildChild(AdultScreenDependencies.self) { childBuilder in
    childBuilder.provideInput(HardwareProduct.self, hardwareProduct)
    childBuilder.provideInput(MacAddress.self, Tagged(macAddress))
}

let screen = AdultScreen.live(dependencies: screenDependencies)
```

---

## Registration Scopes Reference

| Method | Scope | Behavior |
|---|---|---|
| `registerInstance` | Transient | New instance every resolution |
| `registerSingleton` | Singleton | Cached in root container |
| `registerScoped` | Scoped | Cached per container scope |
| `local.register*` | Local | Not inherited by children |
| `mainActor.register*` | MainActor | Main thread isolated |
| `local.mainActor.register*` | Local + MainActor | Both constraints |

### Choosing a Scope

- **Singleton** — most common. Use for stateful services, clients, state providers. One instance shared across the container hierarchy.
- **Instance** — use when each resolution site needs a fresh instance (e.g., `LocalNotificationClient.live()` that sets up its own state).
- **Scoped** — use when you want one instance per container scope (rare).
- **Local** — use for dependencies only this module needs. Not visible to children via `buildChild`. Good for internal providers and operations classes.

---

## Layered Registration Pattern

When `registerDependencies` has many composed dependencies, order them in layers:

```swift
public static func registerDependencies(in builder: DependencyBuilder<MyDependencies>) {
    do {
        // Layer 1: Leaf registrations (no sub-dependencies from container)
        try builder.registerSingleton(UserDefaultsClient.self, key: SomeKey.value) { _ in
            UserDefaultsClient.live(domain: .suite(name: "com.app.suite"))
        }
        try builder.mainActor.registerInstance(LocalNotificationClient.self) { _ in
            LocalNotificationClient.live()
        }

        // Layer 2: Composed registrations (resolve from declared requirements)
        try builder.mainActor.registerSingleton(AdultRoutineCoordinator.self) { container in
            let dependencies = Self(container)
            return AdultRoutineCoordinator(coordinator: dependencies.routineCoordinating)
        }

        // Layer 3: Composed registrations (resolve from Layer 2)
        try builder.mainActor.registerSingleton(AlarmOperations.self) { container in
            let dependencies = Self(container)
            return AlarmOperations(
                coordinator: dependencies.adultRoutineCoordinator, // from Layer 2
                contentClient: dependencies.contentClient,
                macAddress: dependencies.macAddress.rawValue
            )
        }
    } catch {
        preconditionFailure("\(Self.self): Failed to register dependencies. Error: \(error).")
    }
}
```

**Resolution order:** Within `registerDependencies`, all registrations use deferred factory closures. The factories execute at resolution time (when `Self(container)` or `container.resolve(...)` is called), not at registration time. So declaration order doesn't matter for correctness — but layering improves readability.

---

## Critical Rules

### resolve vs resolveMainActor

Dependencies registered via `builder.mainActor.*` **must** be resolved via `container.resolveMainActor(Type.self)` or accessed through the generated accessor on `Self(container)`. Using `container.resolve(Type.self)` for a MainActor-registered dependency causes a runtime crash.

The macro-generated accessors handle this automatically. Manual resolution in factory closures must match:

```swift
// ✅ Correct
try container.resolveMainActor(AdultRoutineCoordinator.self)

// ❌ Crash — AdultRoutineCoordinator was registered via builder.mainActor
try container.resolve(AdultRoutineCoordinator.self)
```

### Inversion of Control

Clients and services should NOT import `HatchModularDependencyContainer`. They receive dependencies through their initializers and are registered IN the container by feature modules. The container module is only imported by:

- Feature modules that declare `*Dependencies.swift`
- The app's composition root (`ViewControllerFactory` or equivalent)

### Tagged Input Types

Input types like `MacAddress` are often `Tagged` wrappers. Access the raw value when passing to initializers:

```swift
dependencies.macAddress.rawValue  // String, not Tagged<MacAddress>
```

---

## Summary Checklist

- [ ] Dependencies identified (inherited, mainActor, local, inputs)
- [ ] `[FeatureName]Dependencies.swift` created with `@DependencyRequirements` macro
- [ ] `registerDependencies` implemented if module has local registrations
- [ ] `Package.swift` updated with `HatchModularDependencyContainer` dependency
- [ ] `Destination+Live.swift` updated to accept and use dependencies
- [ ] `buildChild` used for all child feature navigations
- [ ] ViewModel updated with convenience init (or dependencies-only init)
- [ ] Composition root registers all root-level dependencies and builds first child
