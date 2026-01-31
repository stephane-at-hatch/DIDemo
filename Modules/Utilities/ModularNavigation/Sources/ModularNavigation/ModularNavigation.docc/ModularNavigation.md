# ``ModularNavigation``

A type-safe, modular navigation system for SwiftUI applications.

## Overview

ModularNavigation provides a clean architecture for managing navigation across isolated Swift modules. It enables each module to define its own strongly-typed destinations while maintaining seamless navigation between modules.

### Core Concepts

The system is built around three key ideas:

1. **Module Entry Points** - Each module exposes a single `Entry` type that external modules use to navigate into it
2. **NavigationClient** - A closure-based interface for triggering navigation from ViewModels
3. **Destination Types** - Strongly-typed enums that define all possible screens within a module

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                           TabCoordinator                            │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  TabView with tabs                                            │  │
│  │  ├─ Tab 1: ScreenA.Entry                                      │  │
│  │  ├─ Tab 2: ScreenC.Entry                                      │  │
│  │  └─ Tab 3: ScreenD.Entry                                      │  │
│  └───────────────────────────────────────────────────────────────┘  │
│              ▼                      ▼                    ▼          │
├─────────────────────────┬───────────────────────┬───────────────────┤
│       ScreenA           │       ScreenC         │      ScreenD      │
│  ┌───────────────────┐  │  ┌─────────────────┐  │  ┌─────────────┐  │
│  │ Destination.Public│  │  │Destination.Public│ │  │Dest.Public  │  │
│  │ - .main           │  │  │ - .main          │ │  │ - .main     │  │
│  │                   │  │  └─────────────────┘  │  └─────────────┘  │
│  │ Destination.Ext.  │  │                       │                   │
│  │ - .screenB ───────┼──┼───────────────────────┼───────────────┐   │
│  └───────────────────┘  │                       │               │   │
└─────────────────────────┴───────────────────────┴───────────────┼───┘
                                                                  ▼
                                                        ┌─────────────────┐
                                                        │     ScreenB     │
                                                        │ ┌─────────────┐ │
                                                        │ │Dest.Public  │ │
                                                        │ │ - .main     │ │
                                                        │ │             │ │
                                                        │ │Dest.Internal│ │
                                                        │ │ - .testPage │ │
                                                        │ └─────────────┘ │
                                                        └─────────────────┘
```

### Module Public API

Each module exposes a minimal public interface:

```swift
public extension MyModule {
    // The entry point type
    typealias Entry = ModuleEntry<Destination, DestinationView>
    
    // Factory for production use
    @MainActor
    static func liveEntry(at: Destination.Public, dependencies: Dependencies) -> Entry
    
    // Factory for testing/previews
    @MainActor
    static func mockEntry(at: Destination.Public) -> Entry
}
```

### Key Benefits

- **Type Safety**: Compile-time guarantees prevent invalid navigation paths
- **Module Isolation**: Each module owns its destinations without exposing internals
- **Testability**: `NavigationClient` enables easy mocking in ViewModels
- **Explicit Connections**: Module connections are visible and debuggable
- **Deep Linking**: Type-erased routes can span multiple navigation contexts

## Topics

### Getting Started

- ``NavigationClient``
- ``ModuleEntry``
- ``NavigationMode``

### Views

- ``NavigationDestinationView``
- ``NavigationRootView``
- ``NavigationTabView``
- ``NavigationTabModel``

### Supporting Types

- ``DestinationBuilder``
- ``NavigationStep``
- ``AnyRoute``
- ``AnySteps``
- ``RootDestination``
- ``NavigationHashable``
