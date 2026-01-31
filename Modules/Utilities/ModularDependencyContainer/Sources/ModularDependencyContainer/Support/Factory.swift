//
//  Factory.swift
//  ModularDependencyContainer
//
//  Created by Stephane Magne
//

import Foundation

// MARK: - Factory

struct Factory: Sendable {
    let scope: RegistrationScope
    private let create: @Sendable (AnyFrozenContainer) throws -> any Sendable
    private let singletonCache: SingletonCache? // Only non-nil for .singleton

    init(
        scope: RegistrationScope,
        factory: @escaping @Sendable (AnyFrozenContainer) throws -> any Sendable
    ) {
        self.scope = scope
        self.create = factory
        self.singletonCache = (scope == .singleton) ? SingletonCache() : nil
    }

    func resolve(in container: AnyFrozenContainer) throws -> any Sendable {
        switch scope {
        case .transient:
            try create(container)

        case .singleton:
            try singletonCache!.getOrCreate {
                try create(container)
            }

        case .scoped:
            // Caller (container) is responsible for scoped caching
            try create(container)
        }
    }
}

// MARK: - MainActor Factory

/// Factory for @MainActor-isolated dependencies.
/// Unlike regular Factory, this works with `Any` instead of `any Sendable` because:
/// 1. MainActor-isolated types don't need to be Sendable (they never cross isolation boundaries)
/// 2. All access is gated by @MainActor, so thread safety is guaranteed by actor isolation
/// 
/// This struct is Sendable because it only stores Sendable components:
/// - `scope` is a Sendable enum
/// - `factory` closure is stored and only accessed on MainActor
/// - `singletonCache` uses @unchecked Sendable with MainActor-gated access
struct MainActorFactory: Sendable {
    let scope: RegistrationScope
    private let _factory: @MainActor (AnyFrozenContainer) throws -> Any
    private let singletonCache: MainActorAnySingletonCache?

    @MainActor
    init(
        scope: RegistrationScope,
        factory: @escaping @MainActor (AnyFrozenContainer) throws -> Any
    ) {
        self.scope = scope
        self._factory = factory
        self.singletonCache = (scope == .singleton) ? MainActorAnySingletonCache() : nil
    }

    @MainActor
    func resolve(in container: AnyFrozenContainer) throws -> Any {
        switch scope {
        case .transient:
            try _factory(container)

        case .singleton:
            try singletonCache!.getOrCreate {
                try _factory(container)
            }

        case .scoped:
            // Caller (container) is responsible for scoped caching
            try _factory(container)
        }
    }
}

// MARK: - Type-Erased Frozen Container

/// Type-erased container for parent lookups and factory closures.
/// 
/// This uses `@unchecked Sendable` because:
/// - All Sendable closures are truly Sendable (marked @Sendable)
/// - MainActor closures are stored directly and only accessed via @MainActor methods
/// - The original container is Sendable (DependencyContainer is Sendable)
public struct AnyFrozenContainer: Sendable {
    private let _resolveErased: @Sendable (RegistrationKey) throws -> any Sendable
    private let _resolveMainActorErased: @MainActor (RegistrationKey) throws -> Any
    private let _resolveInput: @Sendable (ObjectIdentifier) throws -> any Sendable
    private let _canResolve: @Sendable (RegistrationKey) -> Bool
    private let _findKeyedRegistrations: @Sendable (ObjectIdentifier) -> [String]
    private let _hasNonKeyedRegistration: @Sendable (ObjectIdentifier) -> Bool
    private let _diagnose: @Sendable (Int) -> String

    // Store original container for typed access in local factory closures
    private let _originalContainer: any Sendable

    // swiftformat:disable:next opaqueGenericParameters
    init<Marker>(_ container: DependencyContainer<Marker>) {
        self._originalContainer = container
        self._resolveErased = { try container.resolveErased(key: $0) }
        self._resolveMainActorErased = { key in try container.resolveMainActorErased(key: key) }
        self._resolveInput = { key in
            guard let value = container.inputs[key] else {
                throw DependencyError.inputNotFound("Input not found for key")
            }
            return value
        }
        self._canResolve = { container.canResolve(key: $0) }
        self._findKeyedRegistrations = { container.findKeyedRegistrations(for: $0) }
        self._hasNonKeyedRegistration = { container.hasNonKeyedRegistration(for: $0) }
        self._diagnose = { container.diagnose(level: $0) }
    }

    /// Retrieves the original typed container.
    /// Use this when registering local factories that need access to the typed DependencyRequirements.
    // swiftformat:disable:next opaqueGenericParameters
    public func typed<Marker>(_ type: DependencyContainer<Marker>.Type) -> DependencyContainer<Marker> {
        // swiftlint:disable:next force_cast
        _originalContainer as! DependencyContainer<Marker>
    }

    func resolveErased(key: RegistrationKey) throws -> any Sendable {
        try _resolveErased(key)
    }

    @MainActor
    func resolveMainActorErased(key: RegistrationKey) throws -> Any {
        try _resolveMainActorErased(key)
    }

    func canResolve(key: RegistrationKey) -> Bool {
        _canResolve(key)
    }

    func findKeyedRegistrations(for typeId: ObjectIdentifier) -> [String] {
        _findKeyedRegistrations(typeId)
    }

    func hasNonKeyedRegistration(for typeId: ObjectIdentifier) -> Bool {
        _hasNonKeyedRegistration(typeId)
    }

    func diagnose(level: Int) -> String {
        _diagnose(level)
    }
}

// ═══════════════════════════════════════════════════════════════════════════

// MARK: - Typed Resolution on AnyFrozenContainer

// ═══════════════════════════════════════════════════════════════════════════

extension AnyFrozenContainer {
    public func resolve<T>(_ type: T.Type) throws -> T {
        let key = RegistrationKey(type: type)
        let resolved = try resolveErased(key: key)
        
        guard let typed = resolved as? T else {
            throw DependencyError.resolutionFailed(
                "Type mismatch: expected \(T.self), got \(Swift.type(of: resolved))"
            )
        }
        return typed
    }

    // swiftformat:disable:next opaqueGenericParameters
    public func resolve<T, Key: Hashable>(_ type: T.Type, key: Key) throws -> T {
        let registrationKey = RegistrationKey(type: type, key: key)
        let resolved = try resolveErased(key: registrationKey)
        
        guard let typed = resolved as? T else {
            throw DependencyError.resolutionFailed(
                "Type mismatch: expected \(T.self), got \(Swift.type(of: resolved))"
            )
        }
        return typed
    }
    
    public func resolveInput<T>(_ type: T.Type) throws -> T {
        let key = ObjectIdentifier(type)
        let resolved = try _resolveInput(key)

        guard let typed = resolved as? T else {
            throw DependencyError.resolutionFailed(
                "Input type mismatch: expected \(T.self), got \(Swift.type(of: resolved))"
            )
        }
        return typed
    }

    // MARK: - MainActor Resolution

    @MainActor
    public func resolveMainActor<T>(_ type: T.Type) throws -> T {
        let key = RegistrationKey(type: type, isolation: .mainActor)
        let resolved = try resolveMainActorErased(key: key)

        guard let typed = resolved as? T else {
            throw DependencyError.resolutionFailed(
                "Type mismatch: expected \(T.self), got \(Swift.type(of: resolved))"
            )
        }
        return typed
    }

    @MainActor
    // swiftformat:disable:next opaqueGenericParameters
    public func resolveMainActor<T, Key: Hashable>(_ type: T.Type, key: Key) throws -> T {
        let registrationKey = RegistrationKey(type: type, key: key, isolation: .mainActor)
        let resolved = try resolveMainActorErased(key: registrationKey)

        guard let typed = resolved as? T else {
            throw DependencyError.resolutionFailed(
                "Type mismatch: expected \(T.self), got \(Swift.type(of: resolved))"
            )
        }
        return typed
    }
}
