//
//  MockDependencyBuilder.swift
//  ModularDependencyContainer
//
//  Created by Stephane Magne
//

import Foundation

// MARK: - Mock Dependency Builder

/// A builder wrapper used inside `TestDependencyProvider.mockRegistration(in:)`.
///
/// All registrations implicitly use `override: true`, allowing mocks to replace
/// any existing registration (including those inherited from a parent container).
/// This is the key difference from the standard `DependencyBuilder` — mock
/// registrations are expected to shadow parent-provided dependencies.
///
/// Parent-provided dependencies take precedence: registrations are skipped for
/// dependencies that the parent container already provides, allowing top-level
/// injections to propagate through the graph.
///
/// When used as an override builder (via `buildChildWithOverrides`), the parent
/// check is bypassed — overrides always take effect.
///
/// **Factory closures receive `AnyFrozenContainer`** (not `DependencyContainer<Marker>`).
/// This is intentional: factories registered via `importDependencies` may be transferred
/// between builders with different `Marker` types. Using `AnyFrozenContainer` avoids the
/// `typed()` force-cast that would fail when the Marker doesn't match at resolution time.
/// `AnyFrozenContainer` provides the same resolution API (`resolve`, `resolveMainActor`,
/// `resolveInput`) so mock factories work identically.
///
/// Supports the same registration patterns as `DependencyBuilder`:
/// - `registerInstance` / `registerSingleton` / `registerScoped` (inherited Sendable)
/// - `mainActor.registerInstance` / `.registerSingleton` / `.registerScoped` (MainActor)
/// - `local.registerInstance` / `.registerSingleton` / `.registerScoped` (local Sendable)
/// - `local.mainActor.registerInstance` / `.registerSingleton` / `.registerScoped` (local MainActor)
/// - `provideInput` (inputs)
@MainActor
public struct MockDependencyBuilder<Marker> {
    let builder: DependencyBuilder<Marker>
    private let parent: AnyFrozenContainer?
    private let isOverride: Bool

    init(builder: DependencyBuilder<Marker>, parent: AnyFrozenContainer?, isOverride: Bool = false) {
        self.builder = builder
        self.parent = parent
        self.isOverride = isOverride
    }

    /// Returns `true` if the registration should proceed.
    /// Override builders always return `true`.
    /// Standard mock builders return `false` if the parent already provides this key.
    private func shouldRegister(key: RegistrationKey) -> Bool {
        if isOverride { return true }
        return !(parent?.canResolve(key: key) ?? false)
    }

    /// Tracks the key as an explicit registration (not imported).
    private func trackExplicit(key: RegistrationKey) {
        builder.explicitRegistrationKeys.insert(key)
    }

    // MARK: - Namespace Accessors

    public var mainActor: MockMainActorRegistrar<Marker> {
        MockMainActorRegistrar(builder: builder, parent: parent, isOverride: isOverride)
    }

    public var local: MockLocalRegistrar<Marker> {
        MockLocalRegistrar(builder: builder, parent: parent, isOverride: isOverride)
    }

    // MARK: - Import Dependencies

    /// Imports mock registrations from a child module's `mockRegistration`.
    ///
    /// Creates a scratch builder, runs the target module's `mockRegistration` into it
    /// (which may itself call `importDependencies`, enabling natural recursion), then
    /// bulk-copies non-local registration dictionaries into the current builder.
    ///
    /// Local-scoped registrations (`local.*`, `local.mainActor.*`) are excluded —
    /// they are designed for the registering module only and may reference
    /// module-internal types invisible to the importing module.
    ///
    /// **Collision rules:**
    /// - Import-import collision: first-in wins, silent.
    /// - Explicit-over-import: explicit registrations after imports always win.
    ///
    /// ```swift
    /// static func mockRegistration(in builder: MockDependencyBuilder<MyModule>) {
    ///     builder.importDependencies(ChildModule.self)
    ///     builder.importDependencies(OtherChildModule.self)
    ///     // Only register what the imports don't cover
    ///     try builder.registerSingleton(MyOwnClient.self) { _ in .mock }
    /// }
    /// ```
    public func importDependencies<T: TestDependencyProvider>(_ type: T.Type) {
        // 1. Create a scratch builder for the target module
        let scratchBuilder = DependencyBuilder<T>(scratchForImport: .testing)

        // 2. Run the target module's mockRegistration into the scratch builder
        //    (no parent — scratch builders are isolated)
        let scratchMockBuilder = MockDependencyBuilder<T>(
            builder: scratchBuilder,
            parent: nil,
            isOverride: false
        )
        T.mockRegistration(in: scratchMockBuilder)

        // 3. Export non-local registrations from the scratch builder
        let exported = scratchBuilder.exportNonLocalRegistrations()

        // 4. Import into the current builder (first-in-wins)
        builder.importRegistrations(exported)
    }

    // MARK: - Suppression

    /// Suppresses the missing-requirement assertion in DEBUG builds.
    ///
    /// Use this as an explicit opt-in escape hatch for modules in mid-adoption
    /// that knowingly have gaps in their mock registrations. Shows up in code
    /// review as "I know what I'm doing."
    ///
    /// ```swift
    /// static func mockRegistration(in builder: MockDependencyBuilder<MyModule>) {
    ///     builder.suppressMissingRequirementAssertions()
    ///     // Partial registrations — known gaps
    ///     try builder.registerSingleton(SomeClient.self) { _ in .mock }
    /// }
    /// ```
    public func suppressMissingRequirementAssertions() {
        builder.isMissingRequirementAssertionsSuppressed = true
    }

    // MARK: - Input Management

    public func provideInput<T: Sendable>(
        _ type: T.Type,
        _ value: T,
        file: String = #file,
        line: Int = #line
    ) {
        builder.provideInput(type, value, file: file, line: line)
    }

    public func provideInput<T: Sendable>(
        _ type: T.Type,
        key: some Hashable & Sendable,
        _ value: T,
        file: String = #file,
        line: Int = #line
    ) {
        builder.provideInput(type, key: key, value, file: file, line: line)
    }

    // MARK: - Registration (Type-Only) — override: true

    //
    // All mock registrations use container-agnostic internal methods that store
    // `AnyFrozenContainer`-based factories. This is critical: factories registered
    // in a scratch builder (e.g. DependencyBuilder<ChildModule>) may be imported
    // into a builder with a different Marker type. The agnostic path avoids the
    // `anyContainer.typed(DependencyContainer<Marker>)` force-cast that would
    // fail when the Marker doesn't match.

    public func registerInstance<T: Sendable>(
        _ type: T.Type,
        file: String = #file,
        line: Int = #line,
        factory: @escaping @Sendable (AnyFrozenContainer) throws -> T
    ) throws {
        let key = RegistrationKey(type: type)
        guard shouldRegister(key: key) else { return }
        trackExplicit(key: key)
        try builder.registerAgnosticInstance(type, override: true, file: file, line: line, factory: factory)
    }

    public func registerSingleton<T: Sendable>(
        _ type: T.Type,
        file: String = #file,
        line: Int = #line,
        factory: @escaping @Sendable (AnyFrozenContainer) throws -> T
    ) throws {
        let key = RegistrationKey(type: type)
        guard shouldRegister(key: key) else { return }
        trackExplicit(key: key)
        try builder.registerAgnosticSingleton(type, override: true, file: file, line: line, factory: factory)
    }

    public func registerScoped<T: Sendable>(
        _ type: T.Type,
        file: String = #file,
        line: Int = #line,
        factory: @escaping @Sendable (AnyFrozenContainer) throws -> T
    ) throws {
        let key = RegistrationKey(type: type)
        guard shouldRegister(key: key) else { return }
        trackExplicit(key: key)
        try builder.registerAgnosticScoped(type, override: true, file: file, line: line, factory: factory)
    }

    // MARK: - Registration (Keyed) — override: true

    public func registerInstance<T: Sendable>(
        _ type: T.Type,
        key: some Hashable & Sendable,
        file: String = #file,
        line: Int = #line,
        factory: @escaping @Sendable (AnyFrozenContainer) throws -> T
    ) throws {
        let registrationKey = RegistrationKey(type: type, key: key)
        guard shouldRegister(key: registrationKey) else { return }
        trackExplicit(key: registrationKey)
        try builder.registerAgnosticInstance(type, key: key, override: true, file: file, line: line, factory: factory)
    }

    public func registerSingleton<T: Sendable>(
        _ type: T.Type,
        key: some Hashable & Sendable,
        file: String = #file,
        line: Int = #line,
        factory: @escaping @Sendable (AnyFrozenContainer) throws -> T
    ) throws {
        let registrationKey = RegistrationKey(type: type, key: key)
        guard shouldRegister(key: registrationKey) else { return }
        trackExplicit(key: registrationKey)
        try builder.registerAgnosticSingleton(type, key: key, override: true, file: file, line: line, factory: factory)
    }

    public func registerScoped<T: Sendable>(
        _ type: T.Type,
        key: some Hashable & Sendable,
        file: String = #file,
        line: Int = #line,
        factory: @escaping @Sendable (AnyFrozenContainer) throws -> T
    ) throws {
        let registrationKey = RegistrationKey(type: type, key: key)
        guard shouldRegister(key: registrationKey) else { return }
        trackExplicit(key: registrationKey)
        try builder.registerAgnosticScoped(type, key: key, override: true, file: file, line: line, factory: factory)
    }
}

// MARK: - Mock MainActor Registrar

@MainActor
public struct MockMainActorRegistrar<Marker> {
    private let builder: DependencyBuilder<Marker>
    private let parent: AnyFrozenContainer?
    private let isOverride: Bool

    init(builder: DependencyBuilder<Marker>, parent: AnyFrozenContainer?, isOverride: Bool = false) {
        self.builder = builder
        self.parent = parent
        self.isOverride = isOverride
    }

    private func shouldRegister(key: RegistrationKey) -> Bool {
        if isOverride { return true }
        return !(parent?.canResolve(key: key) ?? false)
    }

    private func trackExplicit(key: RegistrationKey) {
        builder.explicitRegistrationKeys.insert(key)
    }

    // MARK: - Type-Only Registration — override: true

    public func registerInstance<T>(
        _ type: T.Type,
        file: String = #file,
        line: Int = #line,
        factory: @escaping @MainActor (AnyFrozenContainer) throws -> T
    ) throws {
        let key = RegistrationKey(type: type, isolation: .mainActor)
        guard shouldRegister(key: key) else { return }
        trackExplicit(key: key)
        try builder.registerAgnosticMainActorInstance(type, override: true, file: file, line: line, factory: factory)
    }

    public func registerSingleton<T>(
        _ type: T.Type,
        file: String = #file,
        line: Int = #line,
        factory: @escaping @MainActor (AnyFrozenContainer) throws -> T
    ) throws {
        let key = RegistrationKey(type: type, isolation: .mainActor)
        guard shouldRegister(key: key) else { return }
        trackExplicit(key: key)
        try builder.registerAgnosticMainActorSingleton(type, override: true, file: file, line: line, factory: factory)
    }

    public func registerScoped<T>(
        _ type: T.Type,
        file: String = #file,
        line: Int = #line,
        factory: @escaping @MainActor (AnyFrozenContainer) throws -> T
    ) throws {
        let key = RegistrationKey(type: type, isolation: .mainActor)
        guard shouldRegister(key: key) else { return }
        trackExplicit(key: key)
        try builder.registerAgnosticMainActorScoped(type, override: true, file: file, line: line, factory: factory)
    }

    // MARK: - Keyed Registration — override: true

    public func registerInstance<T>(
        _ type: T.Type,
        key: some Hashable & Sendable,
        file: String = #file,
        line: Int = #line,
        factory: @escaping @MainActor (AnyFrozenContainer) throws -> T
    ) throws {
        let registrationKey = RegistrationKey(type: type, key: key, isolation: .mainActor)
        guard shouldRegister(key: registrationKey) else { return }
        trackExplicit(key: registrationKey)
        try builder.registerAgnosticMainActorInstance(type, key: key, override: true, file: file, line: line, factory: factory)
    }

    public func registerSingleton<T>(
        _ type: T.Type,
        key: some Hashable & Sendable,
        file: String = #file,
        line: Int = #line,
        factory: @escaping @MainActor (AnyFrozenContainer) throws -> T
    ) throws {
        let registrationKey = RegistrationKey(type: type, key: key, isolation: .mainActor)
        guard shouldRegister(key: registrationKey) else { return }
        trackExplicit(key: registrationKey)
        try builder.registerAgnosticMainActorSingleton(type, key: key, override: true, file: file, line: line, factory: factory)
    }

    public func registerScoped<T>(
        _ type: T.Type,
        key: some Hashable & Sendable,
        file: String = #file,
        line: Int = #line,
        factory: @escaping @MainActor (AnyFrozenContainer) throws -> T
    ) throws {
        let registrationKey = RegistrationKey(type: type, key: key, isolation: .mainActor)
        guard shouldRegister(key: registrationKey) else { return }
        trackExplicit(key: registrationKey)
        try builder.registerAgnosticMainActorScoped(type, key: key, override: true, file: file, line: line, factory: factory)
    }
}

// MARK: - Mock Local Registrar

@MainActor
public struct MockLocalRegistrar<Marker> {
    private let builder: DependencyBuilder<Marker>
    private let parent: AnyFrozenContainer?
    private let isOverride: Bool

    init(builder: DependencyBuilder<Marker>, parent: AnyFrozenContainer?, isOverride: Bool = false) {
        self.builder = builder
        self.parent = parent
        self.isOverride = isOverride
    }

    public var mainActor: MockLocalMainActorRegistrar<Marker> {
        MockLocalMainActorRegistrar(builder: builder, parent: parent, isOverride: isOverride)
    }

    // MARK: - Type-Only Registration — override: true

    // Local registrations are NOT exported by importDependencies, so they could
    // safely use the typed path. However, for consistency and simplicity, they
    // also use the agnostic path.

    public func registerInstance<T: Sendable>(
        _ type: T.Type,
        file: String = #file,
        line: Int = #line,
        factory: @escaping @Sendable (AnyFrozenContainer) throws -> T
    ) throws {
        let key = RegistrationKey(type: type)
        let wrappedFactory: @Sendable (AnyFrozenContainer) throws -> T = factory
        try builder.registerLocal(
            key: key,
            type: type,
            scope: .transient,
            keyDescription: nil,
            override: true,
            file: file,
            line: line,
            factory: wrappedFactory
        )
    }

    public func registerSingleton<T: Sendable>(
        _ type: T.Type,
        file: String = #file,
        line: Int = #line,
        factory: @escaping @Sendable (AnyFrozenContainer) throws -> T
    ) throws {
        let key = RegistrationKey(type: type)
        let wrappedFactory: @Sendable (AnyFrozenContainer) throws -> T = factory
        try builder.registerLocal(
            key: key,
            type: type,
            scope: .singleton,
            keyDescription: nil,
            override: true,
            file: file,
            line: line,
            factory: wrappedFactory
        )
    }

    public func registerScoped<T: Sendable>(
        _ type: T.Type,
        file: String = #file,
        line: Int = #line,
        factory: @escaping @Sendable (AnyFrozenContainer) throws -> T
    ) throws {
        let key = RegistrationKey(type: type)
        let wrappedFactory: @Sendable (AnyFrozenContainer) throws -> T = factory
        try builder.registerLocalScoped(
            key: key,
            type: type,
            keyDescription: nil,
            override: true,
            file: file,
            line: line,
            factory: wrappedFactory
        )
    }

    // MARK: - Keyed Registration — override: true

    public func registerInstance<T: Sendable, Key: Hashable & Sendable>(
        _ type: T.Type,
        key: Key,
        file: String = #file,
        line: Int = #line,
        factory: @escaping @Sendable (AnyFrozenContainer) throws -> T
    ) throws {
        let registrationKey = RegistrationKey(type: type, key: key)
        let keyDescription = "\(String(describing: Key.self)).\(key)"
        let wrappedFactory: @Sendable (AnyFrozenContainer) throws -> T = factory
        try builder.registerLocal(
            key: registrationKey,
            type: type,
            scope: .transient,
            keyDescription: keyDescription,
            override: true,
            file: file,
            line: line,
            factory: wrappedFactory
        )
    }

    public func registerSingleton<T: Sendable, Key: Hashable & Sendable>(
        _ type: T.Type,
        key: Key,
        file: String = #file,
        line: Int = #line,
        factory: @escaping @Sendable (AnyFrozenContainer) throws -> T
    ) throws {
        let registrationKey = RegistrationKey(type: type, key: key)
        let keyDescription = "\(String(describing: Key.self)).\(key)"
        let wrappedFactory: @Sendable (AnyFrozenContainer) throws -> T = factory
        try builder.registerLocal(
            key: registrationKey,
            type: type,
            scope: .singleton,
            keyDescription: keyDescription,
            override: true,
            file: file,
            line: line,
            factory: wrappedFactory
        )
    }

    public func registerScoped<T: Sendable, Key: Hashable & Sendable>(
        _ type: T.Type,
        key: Key,
        file: String = #file,
        line: Int = #line,
        factory: @escaping @Sendable (AnyFrozenContainer) throws -> T
    ) throws {
        let registrationKey = RegistrationKey(type: type, key: key)
        let keyDescription = "\(String(describing: Key.self)).\(key)"
        let wrappedFactory: @Sendable (AnyFrozenContainer) throws -> T = factory
        try builder.registerLocalScoped(
            key: registrationKey,
            type: type,
            keyDescription: keyDescription,
            override: true,
            file: file,
            line: line,
            factory: wrappedFactory
        )
    }
}

// MARK: - Mock Local MainActor Registrar

@MainActor
public struct MockLocalMainActorRegistrar<Marker> {
    private let builder: DependencyBuilder<Marker>
    private let parent: AnyFrozenContainer?
    private let isOverride: Bool

    init(builder: DependencyBuilder<Marker>, parent: AnyFrozenContainer?, isOverride: Bool = false) {
        self.builder = builder
        self.parent = parent
        self.isOverride = isOverride
    }

    // MARK: - Type-Only Registration — override: true

    public func registerInstance<T>(
        _ type: T.Type,
        file: String = #file,
        line: Int = #line,
        factory: @escaping @MainActor (AnyFrozenContainer) throws -> T
    ) throws {
        let key = RegistrationKey(type: type, isolation: .mainActor)
        let wrappedFactory: @MainActor (AnyFrozenContainer) throws -> T = factory
        try builder.registerLocalMainActor(
            key: key,
            type: type,
            scope: .transient,
            keyDescription: nil,
            override: true,
            file: file,
            line: line,
            factory: wrappedFactory
        )
    }

    public func registerSingleton<T>(
        _ type: T.Type,
        file: String = #file,
        line: Int = #line,
        factory: @escaping @MainActor (AnyFrozenContainer) throws -> T
    ) throws {
        let key = RegistrationKey(type: type, isolation: .mainActor)
        let wrappedFactory: @MainActor (AnyFrozenContainer) throws -> T = factory
        try builder.registerLocalMainActor(
            key: key,
            type: type,
            scope: .singleton,
            keyDescription: nil,
            override: true,
            file: file,
            line: line,
            factory: wrappedFactory
        )
    }

    public func registerScoped<T>(
        _ type: T.Type,
        file: String = #file,
        line: Int = #line,
        factory: @escaping @MainActor (AnyFrozenContainer) throws -> T
    ) throws {
        let key = RegistrationKey(type: type, isolation: .mainActor)
        let wrappedFactory: @MainActor (AnyFrozenContainer) throws -> T = factory
        try builder.registerLocalMainActorScoped(
            key: key,
            type: type,
            keyDescription: nil,
            override: true,
            file: file,
            line: line,
            factory: wrappedFactory
        )
    }

    // MARK: - Keyed Registration — override: true

    public func registerInstance<T, Key: Hashable & Sendable>(
        _ type: T.Type,
        key: Key,
        file: String = #file,
        line: Int = #line,
        factory: @escaping @MainActor (AnyFrozenContainer) throws -> T
    ) throws {
        let registrationKey = RegistrationKey(type: type, key: key, isolation: .mainActor)
        let keyDescription = "\(String(describing: Key.self)).\(key)"
        let wrappedFactory: @MainActor (AnyFrozenContainer) throws -> T = factory
        try builder.registerLocalMainActor(
            key: registrationKey,
            type: type,
            scope: .transient,
            keyDescription: keyDescription,
            override: true,
            file: file,
            line: line,
            factory: wrappedFactory
        )
    }

    public func registerSingleton<T, Key: Hashable & Sendable>(
        _ type: T.Type,
        key: Key,
        file: String = #file,
        line: Int = #line,
        factory: @escaping @MainActor (AnyFrozenContainer) throws -> T
    ) throws {
        let registrationKey = RegistrationKey(type: type, key: key, isolation: .mainActor)
        let keyDescription = "\(String(describing: Key.self)).\(key)"
        let wrappedFactory: @MainActor (AnyFrozenContainer) throws -> T = factory
        try builder.registerLocalMainActor(
            key: registrationKey,
            type: type,
            scope: .singleton,
            keyDescription: keyDescription,
            override: true,
            file: file,
            line: line,
            factory: wrappedFactory
        )
    }

    public func registerScoped<T, Key: Hashable & Sendable>(
        _ type: T.Type,
        key: Key,
        file: String = #file,
        line: Int = #line,
        factory: @escaping @MainActor (AnyFrozenContainer) throws -> T
    ) throws {
        let registrationKey = RegistrationKey(type: type, key: key, isolation: .mainActor)
        let keyDescription = "\(String(describing: Key.self)).\(key)"
        let wrappedFactory: @MainActor (AnyFrozenContainer) throws -> T = factory
        try builder.registerLocalMainActorScoped(
            key: registrationKey,
            type: type,
            keyDescription: keyDescription,
            override: true,
            file: file,
            line: line,
            factory: wrappedFactory
        )
    }
}
