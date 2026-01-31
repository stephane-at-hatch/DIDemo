//
//  Requirement.swift
//  ModularDependencyContainer
//
//  Created by Stephane Magne on 2026-01-05.
//

// MARK: - Requirement

/// A type-erased requirement for module dependency validation
public struct Requirement: Sendable {
    let key: RegistrationKey
    let description: String
    let isOptional: Bool
    let accessorName: String?

    /// Requires a type-only dependency
    /// swiftformat:disable:next opaqueGenericParameters
    public init<T>(_ type: T.Type, accessorName: String? = nil) {
        self.key = RegistrationKey(type: type)
        self.description = String(describing: type)
        self.isOptional = false
        self.accessorName = accessorName
    }
    
    /// Requires a keyed dependency
    /// swiftformat:disable:next opaqueGenericParameters
    public init<T, Key: Hashable>(_ type: T.Type, key: Key, accessorName: String? = nil) {
        self.key = RegistrationKey(type: type, key: key)
        self.description = "\(String(describing: type)) [key: \(String(describing: Key.self)).\(key)]"
        self.isOptional = false
        self.accessorName = accessorName
    }
    
    /// Requires an optional type-only dependency
    /// swiftformat:disable:next opaqueGenericParameters
    public init<T>(optional type: T.Type, accessorName: String? = nil) {
        self.key = RegistrationKey(type: type)
        self.description = String(describing: type)
        self.isOptional = true
        self.accessorName = accessorName
    }
    
    /// Requires an optional keyed dependency
    /// swiftformat:disable:next opaqueGenericParameters
    public init<T, Key: Hashable>(optional type: T.Type, key: Key, accessorName: String? = nil) {
        self.key = RegistrationKey(type: type, key: key)
        self.description = "\(String(describing: type)) [key: \(String(describing: Key.self)).\(key)]"
        self.isOptional = true
        self.accessorName = accessorName
    }
}

// MARK: - Input Requirement

/// A type-erased input requirement for module configuration validation.
/// Inputs are runtime configuration values provided by the caller before building a child module.
/// Unlike dependencies, inputs are NOT copied to grandchildren - they exist only for the immediate child.
public struct InputRequirement: Sendable {
    let typeId: ObjectIdentifier
    let description: String
    
    /// Requires an input of the specified type
    /// swiftformat:disable:next opaqueGenericParameters
    public init<T>(_ type: T.Type) {
        self.typeId = ObjectIdentifier(type)
        self.description = String(describing: type)
    }
}
