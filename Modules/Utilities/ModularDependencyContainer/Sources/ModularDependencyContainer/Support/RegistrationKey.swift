//
//  RegistrationKey.swift
//  ModularDependencyContainer
//
//  Created by Stephane Magne
//

import Foundation

// MARK: - AnyHashableSendable

/// Type-erased wrapper for values that are both `Hashable` and `Sendable`.
/// Uses `@unchecked Sendable` because the wrapped `AnyHashable` is guaranteed
/// to contain a `Sendable` value, enforced at the generic `init` boundary.
struct AnyHashableSendable: Hashable, @unchecked Sendable {
    private let wrapped: AnyHashable

    init(_ value: some Hashable & Sendable) {
        self.wrapped = AnyHashable(value)
    }

    static func == (lhs: AnyHashableSendable, rhs: AnyHashableSendable) -> Bool {
        lhs.wrapped == rhs.wrapped
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(wrapped)
    }
}

// MARK: - Actor Isolation

/// Indicates the actor isolation context for a dependency registration
enum ActorIsolation: Hashable, Sendable {
    case none
    case mainActor
}

// MARK: - Registration Key

/// Composite key for dependency registration supporting both type-only and keyed registration
struct RegistrationKey: Hashable, Sendable {
    let typeId: ObjectIdentifier
    let keyValue: AnyHashableSendable?
    let isolation: ActorIsolation

    /// Whether this is a keyed registration
    var isKeyed: Bool {
        keyValue != nil
    }

    /// Type-only key
    init(type: Any.Type, isolation: ActorIsolation = .none) {
        self.typeId = ObjectIdentifier(type)
        self.keyValue = nil
        self.isolation = isolation
    }

    /// Type + key
    /// swiftformat:disable:next opaqueGenericParameters
    init<T, Key: Hashable & Sendable>(type: T.Type, key: Key, isolation: ActorIsolation = .none) {
        self.typeId = ObjectIdentifier(type)
        self.keyValue = AnyHashableSendable(key)
        self.isolation = isolation
    }

    /// ObjectIdentifier-based key (for internal lookup)
    init(typeId: ObjectIdentifier, isolation: ActorIsolation = .none) {
        self.typeId = typeId
        self.keyValue = nil
        self.isolation = isolation
    }

    /// Creates a copy with different isolation (preserves key value)
    func withIsolation(_ isolation: ActorIsolation) -> RegistrationKey {
        RegistrationKey(
            typeId: typeId,
            keyValue: keyValue,
            isolation: isolation
        )
    }

    /// Private memberwise initializer for withIsolation
    private init(
        typeId: ObjectIdentifier,
        keyValue: AnyHashableSendable?,
        isolation: ActorIsolation
    ) {
        self.typeId = typeId
        self.keyValue = keyValue
        self.isolation = isolation
    }
}

// MARK: - Registration Metadata

enum RegistrationScope: String, Sendable {
    case transient
    case singleton
    case scoped
}

/// Stores additional information about a registration for debugging
struct RegistrationMetadata: Sendable {
    let typeDescription: String
    let scope: RegistrationScope
    let file: String
    let line: Int
    let keyDescription: String?
    let isLocal: Bool
}

/// Stores additional information about an input for debugging
struct InputMetadata: Sendable {
    let typeDescription: String
    let file: String
    let line: Int
    let keyDescription: String?
}

// MARK: - Input Key

/// Composite key for input registration supporting both type-only and keyed registration
struct InputKey: Hashable, Sendable {
    let typeId: ObjectIdentifier
    let keyValue: AnyHashableSendable?

    /// Whether this is a keyed input
    var isKeyed: Bool {
        keyValue != nil
    }

    /// Type-only key
    init(type: Any.Type) {
        self.typeId = ObjectIdentifier(type)
        self.keyValue = nil
    }

    /// Type + key
    /// swiftformat:disable:next opaqueGenericParameters
    init<T, Key: Hashable & Sendable>(type: T.Type, key: Key) {
        self.typeId = ObjectIdentifier(type)
        self.keyValue = AnyHashableSendable(key)
    }

    /// ObjectIdentifier-based key (for internal lookup)
    init(typeId: ObjectIdentifier) {
        self.typeId = typeId
        self.keyValue = nil
    }
}

// MARK: - Singleton Cache (minimal @unchecked Sendable)

final class SingletonCache: @unchecked Sendable {
    private var instance: (any Sendable)?
    private let lock = NSRecursiveLock()

    func getOrCreate(_ factory: @Sendable () throws -> any Sendable) rethrows -> any Sendable {
        lock.lock()
        defer { lock.unlock() }

        if let instance { return instance }

        let new = try factory()
        instance = new
        return new
    }
}

// MARK: - Scoped Cache (minimal @unchecked Sendable)

final class ScopedCache: @unchecked Sendable {
    private var instances: [RegistrationKey: any Sendable] = [:]
    private let lock = NSRecursiveLock()

    func getOrCreate(
        key: RegistrationKey,
        factory: @Sendable () throws -> any Sendable
    ) rethrows -> any Sendable {
        lock.lock()
        defer { lock.unlock() }

        if let instance = instances[key] { return instance }

        let new = try factory()
        instances[key] = new
        return new
    }
}

// MARK: - MainActor Singleton Cache (for Sendable types)

/// Thread-safe singleton cache for @MainActor dependencies that are Sendable.
/// Uses @unchecked Sendable because all access is guarded by @MainActor isolation at call sites.
final class MainActorSingletonCache: @unchecked Sendable {
    private var instance: (any Sendable)?

    @MainActor
    func getOrCreate(_ factory: @MainActor () throws -> any Sendable) rethrows -> any Sendable {
        if let instance { return instance }

        let new = try factory()
        instance = new
        return new
    }
}

// MARK: - MainActor Scoped Cache (for Sendable types)

/// Thread-safe scoped cache for @MainActor dependencies that are Sendable.
/// Uses @unchecked Sendable because all access is guarded by @MainActor isolation at call sites.
final class MainActorScopedCache: @unchecked Sendable {
    private var instances: [RegistrationKey: any Sendable] = [:]

    @MainActor
    func getOrCreate(
        key: RegistrationKey,
        factory: @MainActor () throws -> any Sendable
    ) rethrows -> any Sendable {
        if let instance = instances[key] { return instance }

        let new = try factory()
        instances[key] = new
        return new
    }
}

// MARK: - MainActor Any Singleton Cache (for non-Sendable types)

/// Singleton cache for @MainActor dependencies that may NOT be Sendable.
/// Uses `Any` instead of `any Sendable` to support non-Sendable MainActor types.
/// Safe because all access is gated by @MainActor isolation.
final class MainActorAnySingletonCache: @unchecked Sendable {
    private var instance: Any?

    @MainActor
    func getOrCreate(_ factory: @MainActor () throws -> Any) rethrows -> Any {
        if let instance { return instance }

        let new = try factory()
        instance = new
        return new
    }
}

// MARK: - MainActor Any Scoped Cache (for non-Sendable types)

/// Scoped cache for @MainActor dependencies that may NOT be Sendable.
/// Uses `Any` instead of `any Sendable` to support non-Sendable MainActor types.
/// Safe because all access is gated by @MainActor isolation.
final class MainActorAnyScopedCache: @unchecked Sendable {
    private var instances: [RegistrationKey: Any] = [:]

    @MainActor
    func getOrCreate(
        key: RegistrationKey,
        factory: @MainActor () throws -> Any
    ) rethrows -> Any {
        if let instance = instances[key] { return instance }

        let new = try factory()
        instances[key] = new
        return new
    }
}
