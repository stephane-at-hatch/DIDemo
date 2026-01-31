# MovieFinder Module Architecture

## Overview

MovieFinder is a movie discovery app built on TMDB APIs, demonstrating modular iOS architecture with clean separation of concerns.

---

## Module Dependency Graph

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                    APP                                          │
│                                                                                 │
│  ┌─────────────┐                                                                │
│  │ MovieFinder │ (Xcode target)                                                 │
│  └──────┬──────┘                                                                │
│         │                                                                       │
│         ▼                                                                       │
│  ┌──────────────┐                                                               │
│  │AppCoordinator│                                                               │
│  └──────┬───────┘                                                               │
└─────────┼───────────────────────────────────────────────────────────────────────┘
          │
          ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              FEATURE LAYER                                      │
│                                                                                 │
│  ┌──────────────┐                                                               │
│  │TabCoordinator│                                                               │
│  └──────┬───────┘                                                               │
│         │                                                                       │
│         ├────────────────┬────────────────┬────────────────┐                   │
│         ▼                ▼                ▼                ▼                   │
│  ┌──────────────┐ ┌────────────┐ ┌───────────────┐ ┌────────────┐             │
│  │DiscoverScreen│ │SearchScreen│ │WatchlistScreen│ │DetailScreen│             │
│  └──────────────┘ └────────────┘ └───────────────┘ └────────────┘             │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              DOMAIN LAYER                                       │
│                                                                                 │
│  ┌─────────────────────────────────┐  ┌─────────────────────────────────────┐  │
│  │          MovieDomain            │  │         WatchlistDomain             │  │
│  │  ┌───────────────────────────┐  │  │  ┌───────────────────────────────┐  │  │
│  │  │   MovieDomainInterface    │  │  │  │  WatchlistDomainInterface     │  │  │
│  │  │  • Movie (entity)         │  │  │  │  • WatchlistItem (entity)     │  │  │
│  │  │  • MovieRepositoryProtocol│  │  │  │  • WatchlistRepositoryProtocol│  │  │
│  │  │  • GetTrendingMovies      │  │  │  │  • AddToWatchlist             │  │  │
│  │  │  • SearchMovies           │  │  │  │  • RemoveFromWatchlist        │  │  │
│  │  │  • GetMovieDetails        │  │  │  │  • GetWatchlist               │  │  │
│  │  └───────────────────────────┘  │  │  │  • IsInWatchlist              │  │  │
│  │  ┌───────────────────────────┐  │  │  └───────────────────────────────┘  │  │
│  │  │      MovieDomain          │  │  │  ┌───────────────────────────────┐  │  │
│  │  │  • MovieRepository (live) │  │  │  │      WatchlistDomain          │  │  │
│  │  └───────────────────────────┘  │  │  │  • WatchlistRepository        │  │  │
│  └─────────────────────────────────┘  │  │    (SwiftData)                │  │  │
│                  │                    │  └───────────────────────────────┘  │  │
│                  ▼                    └─────────────────────────────────────┘  │
└──────────────────┼──────────────────────────────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              CLIENT LAYER                                       │
│                                                                                 │
│  ┌─────────────────────────────────┐  ┌─────────────────────────────────────┐  │
│  │          TMDBClient             │  │          ImageLoader                │  │
│  │  ┌───────────────────────────┐  │  │  ┌───────────────────────────────┐  │  │
│  │  │   TMDBClientInterface     │  │  │  │   ImageLoaderInterface        │  │  │
│  │  │  • TMDBClientProtocol     │  │  │  │  • ImageLoaderProtocol        │  │  │
│  │  │  • TMDBConfiguration      │  │  │  │  • ImageCacheProtocol         │  │  │
│  │  │  • MovieDTO, etc.         │  │  │  └───────────────────────────────┘  │  │
│  │  │  • TMDBImageURL           │  │  │  ┌───────────────────────────────┐  │  │
│  │  └───────────────────────────┘  │  │  │       ImageLoader             │  │  │
│  │  ┌───────────────────────────┐  │  │  │  • AsyncImageLoader           │  │  │
│  │  │       TMDBClient          │  │  │  │  • CachedAsyncImage           │  │  │
│  │  │  • Live implementation    │  │  │  └───────────────────────────────┘  │  │
│  │  └───────────────────────────┘  │  └─────────────────────────────────────┘  │
│  └─────────────────────────────────┘                                            │
│                                                                                 │
│  ┌─────────────────────────────────┐                                            │
│  │            Logger               │                                            │
│  │  (existing from AppShell)       │                                            │
│  └─────────────────────────────────┘                                            │
└─────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────┐
│                            UTILITY LAYER                                        │
│                                                                                 │
│  ┌────────────────────────┐  ┌────────────────────────┐  ┌──────────────────┐  │
│  │ModularDependencyContainer│  │   ModularNavigation   │  │    SharedUI      │  │
│  └────────────────────────┘  └────────────────────────┘  └──────────────────┘  │
│                                                                                 │
│  ┌────────────────────────┐                                                    │
│  │     UIComponents       │                                                    │
│  └────────────────────────┘                                                    │
└─────────────────────────────────────────────────────────────────────────────────┘
```

---

## Module Inventory

### Feature Modules (Screens)

| Module | Type | Description |
|--------|------|-------------|
| `DiscoverScreen` | `.screen` | Trending movies grid, genre filtering, app entry point |
| `SearchScreen` | `.screen` | Search bar, results list |
| `DetailScreen` | `.screen` | Movie poster, overview, cast, watchlist toggle |
| `WatchlistScreen` | `.screen` | Saved movies list, remove capability |

### Domain Modules

| Module | Type | Description |
|--------|------|-------------|
| `MovieDomain` | `.client` | Movie entity, repository protocol, use cases for fetching movie data |
| `WatchlistDomain` | `.client` | WatchlistItem entity, local persistence with SwiftData |

### Client Modules

| Module | Type | Description |
|--------|------|-------------|
| `TMDBClient` | `.client` | TMDB API networking, DTOs, image URL builder |
| `ImageLoader` | `.client` | Generic async image loading with caching |
| `Logger` | `.client` | Logging infrastructure |

### Coordinator Modules

| Module | Type | Description |
|--------|------|-------------|
| `AppCoordinator` | `.coordinator` | Root coordinator, app lifecycle |
| `TabCoordinator` | `.coordinator` | Tab bar navigation, manages feature screens |

### Utility Modules

| Module | Type | Description |
|--------|------|-------------|
| `ModularDependencyContainer` | `.utility` | DI container |
| `ModularNavigation` | `.utility` | Navigation infrastructure |
| `UIComponents` | `.utility` | Generic UI components |
| `SharedUI` | `.utility` | Movie-specific shared views (poster card, rating badge) |

---

## Dependency Rules

1. **Features depend on Domain Interfaces** — Screens import `MovieDomainInterface`, never `MovieDomain`
2. **Domains depend on Client Interfaces** — `MovieDomain` imports `TMDBClientInterface`
3. **Horizontal isolation** — Features don't import other features directly (except for navigation destinations)
4. **Interface segregation** — Each client/domain exposes an `Interface` target

---

## Directory Structure

```
Modules/
├── Package.swift                    (root aggregator)
├── _/Tests.swift
├── Clients/
│   ├── ImageLoader/
│   │   ├── Package.swift
│   │   └── Sources/
│   │       ├── ImageLoader/
│   │       └── ImageLoaderInterface/
│   ├── Logger/
│   └── TMDBClient/
│       ├── Package.swift
│       └── Sources/
│           ├── TMDBClient/
│           └── TMDBClientInterface/
├── Coordinators/
│   ├── AppCoordinator/
│   └── TabCoordinator/
├── Domains/
│   ├── MovieDomain/
│   │   ├── Package.swift
│   │   └── Sources/
│   │       ├── MovieDomain/
│   │       └── MovieDomainInterface/
│   └── WatchlistDomain/
│       ├── Package.swift
│       └── Sources/
│           ├── WatchlistDomain/
│           └── WatchlistDomainInterface/
├── Macros/
│   ├── CopyableMacro/
│   └── DependencyRequirementsMacro/
├── Screens/
│   ├── DetailScreen/
│   │   ├── Package.swift
│   │   └── Sources/
│   │       ├── DetailScreen/
│   │       └── DetailScreenViews/
│   ├── DiscoverScreen/
│   ├── SearchScreen/
│   └── WatchlistScreen/
└── Utilities/
    ├── ModularDependencyContainer/
    ├── ModularNavigation/
    ├── SharedUI/
    └── UIComponents/
```

---

## Next Steps

1. ✅ Define module structure in `Modules.swift`
2. ✅ Define dependency graph in `PackageGraph.swift`
3. Run package generator to scaffold the structure
4. Remove old placeholder screens (ScreenA, ScreenB, ScreenC, ScreenD)
5. Remove TestClient module
6. Begin implementation starting with TMDBClient
