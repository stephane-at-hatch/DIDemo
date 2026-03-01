# TestDependencyProvider Adoption Cookbook

> **Purpose**: Step-by-step guide for converting a module's `DependencyRequirements` to `TestDependencyProvider`, adding mock registration support for the modular dependency container.

---

## Overview

Converting a module to `TestDependencyProvider` enables testing mode where the module self-fulfills its own dependency requirements with mock objects. The key mechanism is `importDependencies`, which reuses mock registrations from child modules to minimize boilerplate.

**What you're creating:** A `+Mock.swift` file alongside the existing `Dependencies.swift` file that extends the dependencies struct to conform to `TestDependencyProvider`.

**File location:**
```
[FeatureModule]/
└── Sources/
    └── Dependencies/
        ├── [FeatureName]Dependencies.swift          ← existing
        └── [FeatureName]Dependencies+Mock.swift     ← new
```

---

## Step 1: Identify the Module's Children

Open `[FeatureName]Destination+Live.swift` and search for all `dependencies.buildChild(...)` calls. These are the module's direct children in the dependency graph.

```swift
// Example from AdultRoutineDestination+Live.swift
dependencies.buildChild(AdultAlarmsDependencies.self)
dependencies.buildChild(BedtimeRemindersDependencies.self)
dependencies.buildChild(ContentPreviewDependencies.self)
dependencies.buildChild(AdultContentDetailDependencies.self)
```

**Rule: Every `buildChild` call becomes an `importDependencies` call in the mock registration.** This ensures the parent container has all registrations needed for child containers to resolve their requirements.

Children can appear in `external` destinations, `internal` destinations, or anywhere in the builder closure — search comprehensively.

---

## Step 2: Identify Uncovered Requirements

Compare the module's declared requirements (from `@DependencyRequirements` in the `Dependencies.swift` file) against what the child imports provide. Whatever the imports don't cover needs explicit registration.

**To determine what an import covers:** Read the child's `+Mock.swift` file. Every `registerSingleton`, `registerInstance`, `provideInput`, and transitive `importDependencies` call in that file contributes registrations. Imports are recursive — a child's imports bring their imports too.

**Common categories of uncovered requirements:**
- Module-specific inputs (typealiased closures, view models)
- Dependencies unique to this module that no child shares
- Protocol types with no existing mock (need a private mock class)

---

## Step 3: Determine Registration Patterns for Uncovered Requirements

For each uncovered requirement, determine the appropriate mock:

| Dependency Pattern | Mock Pattern |
|---|---|
| Simple client with `.mock()` or `.noOp` | `try builder.registerSingleton(Client.self) { _ in .mock() }` |
| Keyed dependency | `try builder.registerSingleton(Client.self, key: Key.value) { _ in .mock }` |
| MainActor dependency | `try builder.mainActor.registerSingleton(Type.self) { _ in .mock }` |
| Protocol type (`any Protocol`) | `try builder.mainActor.registerSingleton((any Protocol).self) { _ in MockImpl() }` |
| Input value type | `builder.provideInput(Type.self, value)` |
| Input Tagged type | `builder.provideInput(MacAddress.self, Tagged(rawValue: "00:00:00:00:00:00"))` |
| Input closure typealias | `builder.provideInput(ClosureType.self, { defaultValue })` |
| Local dependency (composed) | `try builder.local.mainActor.registerSingleton(Type.self) { container in ... }` |

**Finding mock values:** Check the module's `Destination+Mock.swift` file — it shows what mock values were used for SwiftUI previews. Also check the client's own source for `.mock()`, `.noOp`, or `.mock` static members.

---

## Step 4: Handle Local Dependencies

Local dependencies (`localMainActor`, `local`) are registered in `registerDependencies` for production. In testing mode, `registerDependencies` does NOT run — only `mockRegistration` runs. So local dependencies must also be registered in the mock.

**Important:** Local registrations are NOT exported by `importDependencies` (they're scoped to their declaring module). So even if a child registers the same type locally, the parent must register its own.

For composed local dependencies that resolve sub-dependencies from the container:

```swift
try builder.local.mainActor.registerSingleton(RoutineStateProvider.self) { container in
    try RoutineStateProvider(
        coordinator: container.resolveMainActor(AdultRoutineCoordinator.self),
        contentClient: container.resolve(ContentClient.self),
        deviceStateEmitter: container.resolve(IoTDeviceStateEmitterClient.self)
    )
}
```

Use `container.resolve(...)` for Sendable types and `container.resolveMainActor(...)` for MainActor types. Mismatches cause runtime crashes.

---

## Step 5: Write the +Mock.swift File

### Template

```swift
//
//  [FeatureName]Dependencies+Mock.swift
//

import HatchModularDependencyContainer
// Import child module frameworks (one per importDependencies call)
// Import frameworks for explicitly registered types

extension [FeatureName]Dependencies: TestDependencyProvider {
    public static func mockRegistration(in builder: MockDependencyBuilder<[FeatureName]Dependencies>) {
        do {
            // MARK: - Imported dependencies (from child modules)

            builder.importDependencies(ChildOneDependencies.self)
            builder.importDependencies(ChildTwoDependencies.self)

            // MARK: - Leaf dependencies (not covered by imports)

            // Inherited
            try builder.registerSingleton(SomeClient.self) { _ in .mock() }

            // MainActor inherited
            try builder.mainActor.registerSingleton(SomeProvider.self) { _ in .mock }

            // Inputs
            builder.provideInput(SomeInput.self, defaultValue)

            // MARK: - Local dependencies (composed, resolve sub-deps from container)

            try builder.local.mainActor.registerSingleton(LocalProvider.self) { container in
                try LocalProvider(
                    client: container.resolve(SomeClient.self)
                )
            }
        } catch {
            preconditionFailure("\(Self.self): Failed to register mock dependencies. Error: \(error).")
        }
    }
}
```

### Ordering Convention

1. **Imported dependencies** — one `importDependencies` per `buildChild` child, alphabetical
2. **Leaf dependencies** — grouped by scope (Inherited → MainActor inherited → Inputs)
3. **Local dependencies** — composed types that resolve from the container

---

## Step 6: Assess Tests for Container Conversion

**Don't over-apply.** If existing tests have clean, focused `makeViewModel` helpers that give precise control over individual dependencies, leave them as-is.

**Convert when:**
- Tests have large boilerplate constructing many dependencies manually
- The ViewModel has a `convenience init(dependencies:)` that maps cleanly
- Test overrides map naturally to `buildChildWithOverrides`

**Don't convert when:**
- Tests inject types that differ from what the container provides (e.g., injecting a bare `MockRoutineCoordinator` where the container provides `AdultRoutineCoordinator`)
- Tests are pure logic with no DI involvement (view state tests, configurator tests)
- Tests are placeholder stubs

---

## Protocol Types Without Existing Mocks

When a protocol type (e.g., `any DeviceSettingsViewControllerProvider`) has no existing mock, create a private mock class in the +Mock.swift file:

```swift
// MARK: - Mock Helpers

private final class MockDeviceSettingsProvider: DeviceSettingsViewControllerProvider {
    func makeDeviceSettingsViewController(
        for macAddress: String,
        deepLink: SettingsDeepLink?
    ) -> UIViewController? {
        nil
    }
}
```

---

## Validation

After creating the +Mock.swift file, verify:

1. **Builds successfully** — the module and its test target compile
2. **Static analyzer** — run with `--mode monorepo --no-cache` to confirm all requirements are met
3. **Requirement coverage** — the analyzer should report `✅ [FeatureName]Dependencies: all N requirements met`

---

## Real Examples by Complexity

### Leaf Module (no children)

**ContentPreviewDependencies** — 4 inherited + 1 input, no children, no imports.

```swift
extension ContentPreviewDependencies: TestDependencyProvider {
    public static func mockRegistration(in builder: MockDependencyBuilder<ContentPreviewDependencies>) {
        do {
            try builder.registerSingleton(DeviceStateEmitterClient.Factory.self) { _ in .noOp }
            try builder.registerSingleton(HatchAnalyticsClient.self, key: AnalyticsKey.amplitude) { _ in .noOp }
            try builder.registerSingleton(HatchAnalyticsClient.self, key: AnalyticsKey.statsig) { _ in .noOp }
            try builder.registerSingleton(IoTActionSenderClient.self) { _ in .noOp }
            builder.provideInput(HardwareProduct.self, .restoreIoT)
        } catch {
            preconditionFailure("\(Self.self): Failed to register mock dependencies. Error: \(error).")
        }
    }
}
```

### Mid-Level Module (imports cover most requirements)

**AdultLibraryDependencies** — 8 requirements, 1 child. Import covers 6, explicit for 2.

```swift
extension AdultLibraryDependencies: TestDependencyProvider {
    public static func mockRegistration(in builder: MockDependencyBuilder<AdultLibraryDependencies>) {
        do {
            builder.importDependencies(AdultContentDetailDependencies.self)
            try builder.registerSingleton(FavoritesClient.self) { _ in .mock() }
            try builder.mainActor.registerSingleton(LibraryContentClient.self) { _ in .mock() }
        } catch {
            preconditionFailure("\(Self.self): Failed to register mock dependencies. Error: \(error).")
        }
    }
}
```

### Large Module with Local Dependencies

**AdultRoutineDependencies** — 15 requirements, 4 children, 1 local composed dependency.

```swift
extension AdultRoutineDependencies: TestDependencyProvider {
    public static func mockRegistration(in builder: MockDependencyBuilder<AdultRoutineDependencies>) {
        do {
            builder.importDependencies(AdultAlarmsDependencies.self)
            builder.importDependencies(BedtimeRemindersDependencies.self)
            builder.importDependencies(ContentPreviewDependencies.self)
            builder.importDependencies(AdultContentDetailDependencies.self)

            try builder.registerSingleton(FavoritesClient.self) { _ in .mock() }
            try builder.registerSingleton(SubscriptionClient.self) { _ in .noOp }
            try builder.registerSingleton(IoTDeviceConnectionStateClient.Factory.self) { _ in .noOp }

            try builder.local.mainActor.registerSingleton(RoutineStateProvider.self) { container in
                try RoutineStateProvider(
                    coordinator: container.resolveMainActor(AdultRoutineCoordinator.self),
                    contentClient: container.resolve(ContentClient.self),
                    deviceStateEmitter: container.resolve(IoTDeviceStateEmitterClient.self)
                )
            }
        } catch {
            preconditionFailure("\(Self.self): Failed to register mock dependencies. Error: \(error).")
        }
    }
}
```

### Composition Root (many children, few explicit registrations)

**AdultScreenDependencies** — 14 requirements, 3 children. Imports cover all non-input requirements.

```swift
extension AdultScreenDependencies: TestDependencyProvider {
    public static func mockRegistration(in builder: MockDependencyBuilder<AdultScreenDependencies>) {
        do {
            builder.importDependencies(AdultSleepDependencies.self)
            builder.importDependencies(AdultRoutineDependencies.self)
            builder.importDependencies(AdultLibraryDependencies.self)

            builder.provideInput(AdultUserIdentifier.self, "mock-user-id")
            builder.provideInput(HA25ToolbarViewModel.self, .mock)
        } catch {
            preconditionFailure("\(Self.self): Failed to register mock dependencies. Error: \(error).")
        }
    }
}
```

---

## Converted Modules Reference

| Module | Requirements | Children | Explicit Registrations |
|---|---|---|---|
| ContentPreviewDependencies | 5 | 0 | 5 (all explicit) |
| AdultAlarmsDependencies | 10 | 0 | 10 (all explicit) |
| BedtimeRemindersDependencies | 18 | 1 | 14 + import ContentPreview |
| AdultContentDetailDependencies | ~12 | 3 | 3 composed + import Alarms, BedtimeReminders, ContentPreview |
| AdultLibraryDependencies | 8 | 1 | 2 + import ContentDetail |
| AdultRoutineDependencies | 15 | 4 | 4 + import Alarms, BedtimeReminders, ContentPreview, ContentDetail |
| SleepTrackingDependencies | 8 | 1 | 1 input + import BedtimeReminders |
| AdultSleepDependencies | 6 | 1 | 2 + import SleepTracking |
| DeviceSettingsDependencies | 5 | 1 | 5 + import ContentPreview |
| AdultScreenDependencies | 14 | 3 | 2 inputs + import AdultSleep, AdultRoutine, AdultLibrary |
