//
//  DependencyContainerTests.swift
//  HatchModularDependencyContainer
//
//  Created by Claude on 2/4/26.
//

import Foundation
@testable import HatchModularDependencyContainer
import Testing

// MARK: - Test Helpers

protocol TestServiceProtocol: Sendable {
    var id: String { get }
}

struct TestService: TestServiceProtocol, Sendable {
    let id: String
    
    init(id: String = UUID().uuidString) {
        self.id = id
    }
}

struct AnotherService: Sendable {
    let value: Int
}

@MainActor
final class MainActorService {
    let id: String
    
    init(id: String = UUID().uuidString) {
        self.id = id
    }
}

enum ServiceKey: Hashable, Sendable {
    case primary
    case secondary
    case tertiary
}

// MARK: - Test Module Definitions

struct TestModule: DependencyRequirements {
    static var requirements: [Requirement] { [] }
    
    static func registerDependencies(in builder: DependencyBuilder<TestModule>) {
        do {
            try builder.registerSingleton(TestService.self) { _ in
                TestService(id: "test-singleton")
            }
        } catch {
            Issue.record(error, "Failed to register singleton: \(error)")
        }
    }
    
    init(_ container: DependencyContainer<TestModule>) {}
}

struct ChildModule: DependencyRequirements {
    static var requirements: [Requirement] {
        [Requirement(TestService.self)]
    }
    
    static func registerDependencies(in builder: DependencyBuilder<ChildModule>) {
        do {
            try builder.registerInstance(AnotherService.self) { _ in
                AnotherService(value: 42)
            }
        } catch {
            Issue.record(error, "Failed to register instance: \(error)")
        }
    }
    
    init(_ container: DependencyContainer<ChildModule>) {}
}

struct ModuleWithInputs: DependencyRequirements {
    static var inputRequirements: [InputRequirement] {
        [InputRequirement(String.self)]
    }
    
    static func registerDependencies(in builder: DependencyBuilder<ModuleWithInputs>) {}
    
    init(_ container: DependencyContainer<ModuleWithInputs>) {}
}

struct ModuleWithLocalDependencies: DependencyRequirements {
    static var localRequirements: [Requirement] {
        [Requirement(TestService.self)]
    }
    
    static func registerDependencies(in builder: DependencyBuilder<ModuleWithLocalDependencies>) {
        do {
            try builder.local.registerSingleton(TestService.self) { _ in
                TestService(id: "local-service")
            }
        } catch {
            Issue.record(error, "Failed to register local singleton: \(error)")
        }
    }
    
    init(_ container: DependencyContainer<ModuleWithLocalDependencies>) {}
}

// MARK: - Basic Registration Tests

struct BasicRegistrationTests {
    @Test("Register and resolve transient instance")
    @MainActor
    func registerAndResolveTransient() throws {
        let builder = DependencyBuilder<GraphRoot>()
        
        try builder.registerInstance(TestService.self) { _ in
            TestService() // Uses UUID - each call creates a unique instance
        }
        
        let container = builder.freeze()
        let service1 = try container.resolve(TestService.self)
        let service2 = try container.resolve(TestService.self)
        
        #expect(service1.id != service2.id, "Transient should create new instances")
    }
    
    @Test("Register and resolve singleton")
    @MainActor
    func registerAndResolveSingleton() throws {
        let builder = DependencyBuilder<GraphRoot>()
        
        try builder.registerSingleton(TestService.self) { _ in
            TestService(id: "singleton")
        }
        
        let container = builder.freeze()
        let service1 = try container.resolve(TestService.self)
        let service2 = try container.resolve(TestService.self)
        
        #expect(service1.id == service2.id, "Singleton should return same instance")
        #expect(service1.id == "singleton")
    }
    
    @Test("Register and resolve scoped dependency")
    @MainActor
    func registerAndResolveScoped() throws {
        let builder = DependencyBuilder<GraphRoot>()
        
        try builder.registerScoped(TestService.self) { _ in
            TestService()
        }
        
        let container = builder.freeze()
        
        let service1 = try container.resolve(TestService.self)
        let service2 = try container.resolve(TestService.self)
        #expect(service1.id == service2.id, "Same scope should return same instance")
        
        let newScopeContainer = container.newScope()
        let service3 = try newScopeContainer.resolve(TestService.self)
        #expect(service1.id != service3.id, "New scope should create new instance")
    }
    
    @Test("Resolve throws for unregistered dependency")
    @MainActor
    func resolveThrowsForUnregistered() throws {
        let builder = DependencyBuilder<GraphRoot>()
        let container = builder.freeze()
        
        #expect(throws: DependencyError.self) {
            _ = try container.resolve(TestService.self)
        }
    }
}

// MARK: - Keyed Registration Tests

struct KeyedRegistrationTests {
    @Test("Register and resolve keyed instances")
    @MainActor
    func registerAndResolveKeyed() throws {
        let builder = DependencyBuilder<GraphRoot>()
        
        try builder.registerInstance(TestService.self, key: ServiceKey.primary) { _ in
            TestService(id: "primary")
        }
        try builder.registerInstance(TestService.self, key: ServiceKey.secondary) { _ in
            TestService(id: "secondary")
        }
        
        let container = builder.freeze()
        
        let primary = try container.resolve(TestService.self, key: ServiceKey.primary)
        let secondary = try container.resolve(TestService.self, key: ServiceKey.secondary)
        
        #expect(primary.id == "primary")
        #expect(secondary.id == "secondary")
    }
    
    @Test("Keyed and non-keyed registrations are independent")
    @MainActor
    func keyedAndNonKeyedAreIndependent() throws {
        let builder = DependencyBuilder<GraphRoot>()
        
        try builder.registerSingleton(TestService.self) { _ in
            TestService(id: "default")
        }
        try builder.registerSingleton(TestService.self, key: ServiceKey.primary) { _ in
            TestService(id: "keyed")
        }
        
        let container = builder.freeze()
        
        let defaultService = try container.resolve(TestService.self)
        let keyedService = try container.resolve(TestService.self, key: ServiceKey.primary)
        
        #expect(defaultService.id == "default")
        #expect(keyedService.id == "keyed")
    }
    
    @Test("Resolve throws for wrong key")
    @MainActor
    func resolveThrowsForWrongKey() throws {
        let builder = DependencyBuilder<GraphRoot>()
        
        try builder.registerInstance(TestService.self, key: ServiceKey.primary) { _ in
            TestService(id: "primary")
        }
        
        let container = builder.freeze()
        
        #expect(throws: DependencyError.self) {
            _ = try container.resolve(TestService.self, key: ServiceKey.secondary)
        }
    }
}

// MARK: - MainActor Registration Tests

struct MainActorRegistrationTests {
    @Test("Register and resolve MainActor singleton")
    @MainActor
    func registerAndResolveMainActorSingleton() throws {
        let builder = DependencyBuilder<GraphRoot>()
        
        try builder.mainActor.registerSingleton(MainActorService.self) { _ in
            MainActorService(id: "main-actor-singleton")
        }
        
        let container = builder.freeze()
        
        let service1 = try container.resolveMainActor(MainActorService.self)
        let service2 = try container.resolveMainActor(MainActorService.self)
        
        #expect(service1.id == service2.id)
        #expect(service1.id == "main-actor-singleton")
    }
    
    @Test("Register and resolve MainActor transient")
    @MainActor
    func registerAndResolveMainActorTransient() throws {
        let builder = DependencyBuilder<GraphRoot>()
        
        try builder.mainActor.registerInstance(MainActorService.self) { _ in
            MainActorService()
        }
        
        let container = builder.freeze()
        
        let service1 = try container.resolveMainActor(MainActorService.self)
        let service2 = try container.resolveMainActor(MainActorService.self)
        
        #expect(service1.id != service2.id, "Transient should create new instances")
    }
    
    @Test("Register and resolve keyed MainActor dependency")
    @MainActor
    func registerAndResolveKeyedMainActor() throws {
        let builder = DependencyBuilder<GraphRoot>()
        
        try builder.mainActor.registerSingleton(MainActorService.self, key: ServiceKey.primary) { _ in
            MainActorService(id: "primary-main-actor")
        }
        try builder.mainActor.registerSingleton(MainActorService.self, key: ServiceKey.secondary) { _ in
            MainActorService(id: "secondary-main-actor")
        }
        
        let container = builder.freeze()
        
        let primary = try container.resolveMainActor(MainActorService.self, key: ServiceKey.primary)
        let secondary = try container.resolveMainActor(MainActorService.self, key: ServiceKey.secondary)
        
        #expect(primary.id == "primary-main-actor")
        #expect(secondary.id == "secondary-main-actor")
    }
}

// MARK: - Local Registration Tests

struct LocalRegistrationTests {
    @Test("Local dependencies are not inherited by children")
    @MainActor
    func localDependenciesNotInherited() throws {
        let builder = DependencyBuilder<GraphRoot>()
        
        // Register an inherited dependency
        try builder.registerSingleton(AnotherService.self) { _ in
            AnotherService(value: 100)
        }
        
        // Register a local dependency
        try builder.local.registerSingleton(TestService.self) { _ in
            TestService(id: "local-only")
        }
        
        let container = builder.freeze()
        
        // Local dependency should be resolvable in this container
        let localService = try container.resolve(TestService.self)
        #expect(localService.id == "local-only")
        
        // Build a child that tries to use TestService
        struct SimpleChild: DependencyRequirements {
            static func registerDependencies(in builder: DependencyBuilder<SimpleChild>) {}

            let container: DependencyContainer<SimpleChild>

            init(_ container: DependencyContainer<SimpleChild>) {
                self.container = container
            }
        }
        
        let childContainer = container.buildChild(SimpleChild.self)

        // The child should NOT be able to resolve the local dependency
        #expect(throws: DependencyError.self) {
            _ = try childContainer.container.resolve(TestService.self)
        }
    }
    
    @Test("Local scoped dependencies reset with newScope")
    @MainActor
    func localScopedResetWithNewScope() throws {
        let builder = DependencyBuilder<GraphRoot>()
        
        try builder.local.registerScoped(TestService.self) { _ in
            TestService()
        }
        
        let container = builder.freeze()
        
        let service1 = try container.resolve(TestService.self)
        let service2 = try container.resolve(TestService.self)
        #expect(service1.id == service2.id, "Same scope returns same instance")
        
        let newScope = container.newScope()
        let service3 = try newScope.resolve(TestService.self)
        #expect(service1.id != service3.id, "New scope creates new instance")
    }
    
    @Test("Local MainActor registration works correctly")
    @MainActor
    func localMainActorRegistration() throws {
        let builder = DependencyBuilder<GraphRoot>()
        
        try builder.local.mainActor.registerSingleton(MainActorService.self) { _ in
            MainActorService(id: "local-main-actor")
        }
        
        let container = builder.freeze()
        
        let service = try container.resolveMainActor(MainActorService.self)
        #expect(service.id == "local-main-actor")
    }
}

// MARK: - Input Tests

struct InputTests {
    @Test("Provide and resolve input")
    @MainActor
    func provideAndResolveInput() throws {
        let builder = DependencyBuilder<GraphRoot>()
        
        builder.provideInput(String.self, "test-input")
        builder.provideInput(Int.self, 42)
        
        let container = builder.freeze()
        
        let stringInput = try container.resolveInput(String.self)
        let intInput = try container.resolveInput(Int.self)
        
        #expect(stringInput == "test-input")
        #expect(intInput == 42)
    }
    
    @Test("Resolve throws for missing input")
    @MainActor
    func resolveThrowsForMissingInput() throws {
        let builder = DependencyBuilder<GraphRoot>()
        let container = builder.freeze()
        
        #expect(throws: DependencyError.self) {
            _ = try container.resolveInput(String.self)
        }
    }
    
    @Test("Inputs are passed to child containers")
    @MainActor
    func inputsPassedToChildren() throws {
        let rootBuilder = DependencyBuilder<GraphRoot>()
        
        rootBuilder.provideInput(String.self, "parent-input")
        
        let rootContainer = rootBuilder.freeze()
        
        struct ChildWithInput: DependencyRequirements {
            static func registerDependencies(in builder: DependencyBuilder<ChildWithInput>) {}
            init(_ container: DependencyContainer<ChildWithInput>) {}
        }
        
        // Build child without providing additional inputs
        let childBuilder = DependencyBuilder<ChildWithInput>(
            parent: AnyFrozenContainer(rootContainer),
            inputs: rootContainer.inputs
        )
        let childContainer = childBuilder.freeze()
        
        let input = try childContainer.resolveInput(String.self)
        #expect(input == "parent-input")
    }
}

// MARK: - Child Building Tests

struct ChildBuildingTests {
    @Test("Child inherits parent dependencies")
    @MainActor
    func childInheritsParentDependencies() throws {
        let rootBuilder = DependencyBuilder<GraphRoot>()
        
        try rootBuilder.registerSingleton(TestService.self) { _ in
            TestService(id: "root-service")
        }
        
        let rootContainer = rootBuilder.freeze()
        
        struct SimpleChild: DependencyRequirements {
            static var requirements: [Requirement] {
                [Requirement(TestService.self)]
            }
            
            static func registerDependencies(in builder: DependencyBuilder<SimpleChild>) {}
            init(_ container: DependencyContainer<SimpleChild>) {}
        }
        
        // This should succeed because TestService is registered in parent
        _ = rootContainer.buildChild(SimpleChild.self)
    }
    
    @Test("Child can override parent dependencies")
    @MainActor
    func childCanOverrideParent() throws {
        let rootBuilder = DependencyBuilder<GraphRoot>()
        
        try rootBuilder.registerSingleton(TestService.self) { _ in
            TestService(id: "root-service")
        }
        
        let rootContainer = rootBuilder.freeze()
        
        struct OverridingChild: DependencyRequirements {
            static func registerDependencies(in builder: DependencyBuilder<OverridingChild>) {
                do {
                    try builder.registerSingleton(TestService.self, override: true) { _ in
                        TestService(id: "child-override")
                    }
                } catch {
                    Issue.record(error, "Failed to register singleton with override: \(error)")
                }
            }
            
            init(_ container: DependencyContainer<OverridingChild>) {}
        }
        
        let child = rootContainer.buildChild(OverridingChild.self)
        _ = child
    }
    
    @Test("buildChild with configure closure provides inputs")
    @MainActor
    func buildChildWithConfigureProvidesInputs() throws {
        let rootBuilder = DependencyBuilder<GraphRoot>()
        let rootContainer = rootBuilder.freeze()
        
        let child = rootContainer.buildChild(ModuleWithInputs.self) { builder in
            builder.provideInput(String.self, "configured-input")
        }
        
        _ = child // Should succeed without crashing
    }
}

// MARK: - Override Tests

struct OverrideTests {
    @Test("Registration without override throws for duplicate")
    @MainActor
    func registrationWithoutOverrideThrows() throws {
        let builder = DependencyBuilder<GraphRoot>()
        
        try builder.registerSingleton(TestService.self) { _ in
            TestService(id: "first")
        }
        
        #expect(throws: DependencyError.self) {
            try builder.registerSingleton(TestService.self) { _ in
                TestService(id: "second")
            }
        }
    }
    
    @Test("Registration with override succeeds")
    @MainActor
    func registrationWithOverrideSucceeds() throws {
        let builder = DependencyBuilder<GraphRoot>()
        
        try builder.registerSingleton(TestService.self) { _ in
            TestService(id: "first")
        }
        
        try builder.registerSingleton(TestService.self, override: true) { _ in
            TestService(id: "second")
        }
        
        let container = builder.freeze()
        let service = try container.resolve(TestService.self)
        
        #expect(service.id == "second")
    }
}

// MARK: - Cross-Scope Registration Guard Tests

struct CrossScopeRegistrationTests {
    // MARK: - Inherited Sendable

    @Test("Registering singleton then scoped for same type throws without override")
    @MainActor
    func singletonThenScopedThrows() throws {
        let builder = DependencyBuilder<GraphRoot>()

        try builder.registerSingleton(TestService.self) { _ in
            TestService(id: "singleton")
        }

        #expect(throws: DependencyError.self) {
            try builder.registerScoped(TestService.self) { _ in
                TestService(id: "scoped")
            }
        }
    }

    @Test("Registering scoped then singleton for same type throws without override")
    @MainActor
    func scopedThenSingletonThrows() throws {
        let builder = DependencyBuilder<GraphRoot>()

        try builder.registerScoped(TestService.self) { _ in
            TestService(id: "scoped")
        }

        #expect(throws: DependencyError.self) {
            try builder.registerSingleton(TestService.self) { _ in
                TestService(id: "singleton")
            }
        }
    }

    @Test("Override from singleton to scoped resolves as scoped")
    @MainActor
    func overrideSingletonToScoped() throws {
        let builder = DependencyBuilder<GraphRoot>()

        try builder.registerSingleton(TestService.self) { _ in
            TestService(id: "singleton")
        }

        try builder.registerScoped(TestService.self, override: true) { _ in
            TestService()
        }

        let container = builder.freeze()

        let service1 = try container.resolve(TestService.self)
        let service2 = try container.resolve(TestService.self)
        #expect(service1.id == service2.id, "Same scope should return same instance")

        let newScope = container.newScope()
        let service3 = try newScope.resolve(TestService.self)
        #expect(service1.id != service3.id, "New scope should create new instance")
    }

    @Test("Override from scoped to singleton resolves as singleton")
    @MainActor
    func overrideScopedToSingleton() throws {
        let builder = DependencyBuilder<GraphRoot>()

        try builder.registerScoped(TestService.self) { _ in
            TestService()
        }

        try builder.registerSingleton(TestService.self, override: true) { _ in
            TestService(id: "singleton")
        }

        let container = builder.freeze()

        let service1 = try container.resolve(TestService.self)
        let service2 = try container.resolve(TestService.self)
        #expect(service1.id == "singleton")
        #expect(service1.id == service2.id)

        let newScope = container.newScope()
        let service3 = try newScope.resolve(TestService.self)
        #expect(service1.id == service3.id, "Singleton should persist across scopes")
    }

    // MARK: - MainActor

    @Test("MainActor singleton then scoped throws without override")
    @MainActor
    func mainActorSingletonThenScopedThrows() throws {
        let builder = DependencyBuilder<GraphRoot>()

        try builder.mainActor.registerSingleton(MainActorService.self) { _ in
            MainActorService(id: "singleton")
        }

        #expect(throws: DependencyError.self) {
            try builder.mainActor.registerScoped(MainActorService.self) { _ in
                MainActorService(id: "scoped")
            }
        }
    }

    @Test("MainActor override from singleton to scoped resolves as scoped")
    @MainActor
    func mainActorOverrideSingletonToScoped() throws {
        let builder = DependencyBuilder<GraphRoot>()

        try builder.mainActor.registerSingleton(MainActorService.self) { _ in
            MainActorService(id: "singleton")
        }

        try builder.mainActor.registerScoped(MainActorService.self, override: true) { _ in
            MainActorService()
        }

        let container = builder.freeze()

        let service1 = try container.resolveMainActor(MainActorService.self)
        let service2 = try container.resolveMainActor(MainActorService.self)
        #expect(service1.id == service2.id, "Same scope should return same instance")

        let newScope = container.newScope()
        let service3 = try newScope.resolveMainActor(MainActorService.self)
        #expect(service1.id != service3.id, "New scope should create new instance")
    }

    // MARK: - Local Sendable

    @Test("Local singleton then scoped throws without override")
    @MainActor
    func localSingletonThenScopedThrows() throws {
        let builder = DependencyBuilder<GraphRoot>()

        try builder.local.registerSingleton(TestService.self) { _ in
            TestService(id: "singleton")
        }

        #expect(throws: DependencyError.self) {
            try builder.local.registerScoped(TestService.self) { _ in
                TestService(id: "scoped")
            }
        }
    }

    @Test("Local override from singleton to scoped resolves as scoped")
    @MainActor
    func localOverrideSingletonToScoped() throws {
        let builder = DependencyBuilder<GraphRoot>()

        try builder.local.registerSingleton(TestService.self) { _ in
            TestService(id: "singleton")
        }

        try builder.local.registerScoped(TestService.self, override: true) { _ in
            TestService()
        }

        let container = builder.freeze()

        let service1 = try container.resolve(TestService.self)
        let service2 = try container.resolve(TestService.self)
        #expect(service1.id == service2.id, "Same scope should return same instance")

        let newScope = container.newScope()
        let service3 = try newScope.resolve(TestService.self)
        #expect(service1.id != service3.id, "New scope should create new instance")
    }

    // MARK: - Local MainActor

    @Test("Local MainActor singleton then scoped throws without override")
    @MainActor
    func localMainActorSingletonThenScopedThrows() throws {
        let builder = DependencyBuilder<GraphRoot>()

        try builder.local.mainActor.registerSingleton(MainActorService.self) { _ in
            MainActorService(id: "singleton")
        }

        #expect(throws: DependencyError.self) {
            try builder.local.mainActor.registerScoped(MainActorService.self) { _ in
                MainActorService(id: "scoped")
            }
        }
    }

    @Test("Local MainActor override from singleton to scoped resolves as scoped")
    @MainActor
    func localMainActorOverrideSingletonToScoped() throws {
        let builder = DependencyBuilder<GraphRoot>()

        try builder.local.mainActor.registerSingleton(MainActorService.self) { _ in
            MainActorService(id: "singleton")
        }

        try builder.local.mainActor.registerScoped(MainActorService.self, override: true) { _ in
            MainActorService()
        }

        let container = builder.freeze()

        let service1 = try container.resolveMainActor(MainActorService.self)
        let service2 = try container.resolveMainActor(MainActorService.self)
        #expect(service1.id == service2.id, "Same scope should return same instance")

        let newScope = container.newScope()
        let service3 = try newScope.resolveMainActor(MainActorService.self)
        #expect(service1.id != service3.id, "New scope should create new instance")
    }
}

// MARK: - Factory Resolution Tests

struct FactoryResolutionTests {
    @Test("Factory can resolve other dependencies")
    @MainActor
    func factoryCanResolveDependencies() throws {
        let builder = DependencyBuilder<GraphRoot>()
        
        try builder.registerSingleton(TestService.self) { _ in
            TestService(id: "dependency")
        }
        
        try builder.registerSingleton(AnotherService.self) { container in
            let testService = try container.resolve(TestService.self)
            return AnotherService(value: testService.id.count)
        }
        
        let container = builder.freeze()
        
        let anotherService = try container.resolve(AnotherService.self)
        #expect(anotherService.value == "dependency".count)
    }
    
    @Test("Factory can resolve inputs")
    @MainActor
    func factoryCanResolveInputs() throws {
        let builder = DependencyBuilder<GraphRoot>()
        
        builder.provideInput(Int.self, 99)
        
        try builder.registerSingleton(AnotherService.self) { container in
            let value = try container.resolveInput(Int.self)
            return AnotherService(value: value)
        }
        
        let container = builder.freeze()
        
        let service = try container.resolve(AnotherService.self)
        #expect(service.value == 99)
    }
}

// MARK: - Re-entrant Resolution Tests (NSRecursiveLock)

struct ReentrantResolutionTests {
    @Test("Scoped dependency resolving another scoped dependency does not deadlock")
    @MainActor
    func scopedResolvingScopedDoesNotDeadlock() throws {
        let builder = DependencyBuilder<GraphRoot>()

        try builder.registerScoped(TestService.self) { _ in
            TestService(id: "inner-scoped")
        }

        try builder.registerScoped(AnotherService.self) { container in
            let inner = try container.resolve(TestService.self)
            return AnotherService(value: inner.id.count)
        }

        let container = builder.freeze()

        let service = try container.resolve(AnotherService.self)
        #expect(service.value == "inner-scoped".count)
    }

    @Test("Singleton dependency resolving another singleton does not deadlock")
    @MainActor
    func singletonResolvingSingletonDoesNotDeadlock() throws {
        let builder = DependencyBuilder<GraphRoot>()

        try builder.registerSingleton(TestService.self) { _ in
            TestService(id: "inner-singleton")
        }

        try builder.registerSingleton(AnotherService.self) { container in
            let inner = try container.resolve(TestService.self)
            return AnotherService(value: inner.id.count)
        }

        let container = builder.freeze()

        let service = try container.resolve(AnotherService.self)
        #expect(service.value == "inner-singleton".count)
    }

    @Test("Three-level scoped dependency chain does not deadlock")
    @MainActor
    func threeLevelScopedChainDoesNotDeadlock() throws {
        let builder = DependencyBuilder<GraphRoot>()

        try builder.registerScoped(Int.self) { _ in
            42
        }

        try builder.registerScoped(TestService.self) { container in
            let value = try container.resolve(Int.self)
            return TestService(id: "level-\(value)")
        }

        try builder.registerScoped(AnotherService.self) { container in
            let inner = try container.resolve(TestService.self)
            return AnotherService(value: inner.id.count)
        }

        let container = builder.freeze()

        let service = try container.resolve(AnotherService.self)
        #expect(service.value == "level-42".count)
    }

    @Test("Scoped dependency resolving a singleton does not deadlock")
    @MainActor
    func scopedResolvingSingletonDoesNotDeadlock() throws {
        let builder = DependencyBuilder<GraphRoot>()

        try builder.registerSingleton(TestService.self) { _ in
            TestService(id: "singleton-dep")
        }

        try builder.registerScoped(AnotherService.self) { container in
            let inner = try container.resolve(TestService.self)
            return AnotherService(value: inner.id.count)
        }

        let container = builder.freeze()

        let service = try container.resolve(AnotherService.self)
        #expect(service.value == "singleton-dep".count)
    }
}

// MARK: - Diagnostics Tests

struct DiagnosticsTests {
    @Test("Diagnose returns registration information")
    @MainActor
    func diagnoseReturnsInfo() throws {
        let builder = DependencyBuilder<GraphRoot>()
        
        try builder.registerSingleton(TestService.self) { _ in
            TestService(id: "test")
        }
        try builder.registerInstance(AnotherService.self) { _ in
            AnotherService(value: 1)
        }
        
        let container = builder.freeze()
        let diagnosis = container.diagnose()
        
        #expect(diagnosis.contains("GraphRoot"))
        #expect(diagnosis.contains("singleton"))
        #expect(diagnosis.contains("transient"))
        #expect(diagnosis.contains("TestService"))
        #expect(diagnosis.contains("AnotherService"))
    }
}

// MARK: - RootDependencyBuilder Tests

struct RootDependencyBuilderTests {
    @Test("RootDependencyBuilder builds child from scratch")
    @MainActor
    func rootBuilderBuildsChild() {
        let child = RootDependencyBuilder.buildChild(TestModule.self)
        _ = child // Should succeed
    }
}

// MARK: - Error Message Tests

struct ErrorMessageTests {
    @Test("Resolution error includes type information")
    @MainActor
    func resolutionErrorIncludesTypeInfo() throws {
        let builder = DependencyBuilder<GraphRoot>()
        let container = builder.freeze()
        
        do {
            _ = try container.resolve(TestService.self)
            Issue.record("Expected error to be thrown")
        } catch let error as DependencyError {
            let description = error.description
            #expect(description.contains("TestService"))
        }
    }
    
    @Test("Resolution error suggests available keyed registrations")
    @MainActor
    func resolutionErrorSuggestsKeyedRegistrations() throws {
        let builder = DependencyBuilder<GraphRoot>()
        
        try builder.registerSingleton(TestService.self, key: ServiceKey.primary) { _ in
            TestService(id: "primary")
        }
        
        let container = builder.freeze()
        
        do {
            // Try to resolve without a key when only keyed registration exists
            _ = try container.resolve(TestService.self)
            Issue.record("Expected error to be thrown")
        } catch let error as DependencyError {
            let description = error.description
            #expect(description.contains("primary") || description.contains("ServiceKey"))
        }
    }
}

// MARK: - Keyed Input Tests

enum ConfigKey: Hashable, Sendable {
    case primary
    case secondary
    case logger
}

struct KeyedInputTests {
    @Test("Provide and resolve keyed input")
    @MainActor
    func provideAndResolveKeyedInput() throws {
        let builder = DependencyBuilder<GraphRoot>()
        
        builder.provideInput(String.self, key: ConfigKey.primary, "primary-value")
        
        let container = builder.freeze()
        
        let input = try container.resolveInput(String.self, key: ConfigKey.primary)
        #expect(input == "primary-value")
    }
    
    @Test("Multiple inputs of same type with different keys")
    @MainActor
    func multipleInputsWithDifferentKeys() throws {
        let builder = DependencyBuilder<GraphRoot>()
        
        builder.provideInput(String.self, key: ConfigKey.primary, "primary-value")
        builder.provideInput(String.self, key: ConfigKey.secondary, "secondary-value")
        
        let container = builder.freeze()
        
        let primary = try container.resolveInput(String.self, key: ConfigKey.primary)
        let secondary = try container.resolveInput(String.self, key: ConfigKey.secondary)
        
        #expect(primary == "primary-value")
        #expect(secondary == "secondary-value")
    }
    
    @Test("Keyed and non-keyed inputs are independent")
    @MainActor
    func keyedAndNonKeyedAreIndependent() throws {
        let builder = DependencyBuilder<GraphRoot>()
        
        builder.provideInput(String.self, "default-value")
        builder.provideInput(String.self, key: ConfigKey.primary, "keyed-value")
        
        let container = builder.freeze()
        
        let defaultInput = try container.resolveInput(String.self)
        let keyedInput = try container.resolveInput(String.self, key: ConfigKey.primary)
        
        #expect(defaultInput == "default-value")
        #expect(keyedInput == "keyed-value")
    }
    
    @Test("Resolve throws for wrong input key")
    @MainActor
    func resolveThrowsForWrongKey() throws {
        let builder = DependencyBuilder<GraphRoot>()
        
        builder.provideInput(String.self, key: ConfigKey.primary, "primary-value")
        
        let container = builder.freeze()
        
        #expect(throws: DependencyError.self) {
            _ = try container.resolveInput(String.self, key: ConfigKey.secondary)
        }
    }
    
    @Test("Resolve throws for missing keyed input")
    @MainActor
    func resolveThrowsForMissingKeyedInput() throws {
        let builder = DependencyBuilder<GraphRoot>()
        
        // Provide non-keyed input but try to resolve keyed
        builder.provideInput(String.self, "default-value")
        
        let container = builder.freeze()
        
        #expect(throws: DependencyError.self) {
            _ = try container.resolveInput(String.self, key: ConfigKey.primary)
        }
    }
    
    @Test("Factory can resolve keyed inputs")
    @MainActor
    func factoryCanResolveKeyedInputs() throws {
        let builder = DependencyBuilder<GraphRoot>()
        
        builder.provideInput(Int.self, key: ConfigKey.logger, 42)
        
        try builder.registerSingleton(AnotherService.self) { container in
            let value = try container.resolveInput(Int.self, key: ConfigKey.logger)
            return AnotherService(value: value)
        }
        
        let container = builder.freeze()
        
        let service = try container.resolve(AnotherService.self)
        #expect(service.value == 42)
    }
    
    @Test("Keyed input error message includes key information")
    @MainActor
    func keyedInputErrorIncludesKeyInfo() throws {
        let builder = DependencyBuilder<GraphRoot>()
        let container = builder.freeze()
        
        do {
            _ = try container.resolveInput(String.self, key: ConfigKey.primary)
            Issue.record("Expected error to be thrown")
        } catch let error as DependencyError {
            let description = error.description
            #expect(description.contains("String"))
            #expect(description.contains("key") || description.contains("primary") || description.contains("InputKey"))
        }
    }
}

// MARK: - InputRequirement Tests

struct InputRequirementTests {
    @Test("InputRequirement with type only")
    func inputRequirementTypeOnly() {
        let requirement = InputRequirement(String.self)
        
        #expect(requirement.description == "String")
        #expect(requirement.accessorName == nil)
        #expect(requirement.key.isKeyed == false)
    }
    
    @Test("InputRequirement with accessorName")
    func inputRequirementWithAccessorName() {
        let requirement = InputRequirement(String.self, accessorName: "myCustomName")
        
        #expect(requirement.description == "String")
        #expect(requirement.accessorName == "myCustomName")
        #expect(requirement.key.isKeyed == false)
    }
    
    @Test("InputRequirement with key")
    func inputRequirementWithKey() {
        let requirement = InputRequirement(String.self, key: ConfigKey.primary)
        
        #expect(requirement.description.contains("String"))
        #expect(requirement.description.contains("primary") || requirement.description.contains("InputKey"))
        #expect(requirement.accessorName == nil)
        #expect(requirement.key.isKeyed == true)
    }
    
    @Test("InputRequirement with key and accessorName")
    func inputRequirementWithKeyAndAccessorName() {
        let requirement = InputRequirement(String.self, key: ConfigKey.logger, accessorName: "configValue")
        
        #expect(requirement.description.contains("String"))
        #expect(requirement.accessorName == "configValue")
        #expect(requirement.key.isKeyed == true)
    }
}

// MARK: - InputKey Tests

struct InputKeyTests {
    @Test("InputKey type-only equality")
    func inputKeyTypeOnlyEquality() {
        let key1 = InputKey(type: String.self)
        let key2 = InputKey(type: String.self)
        let key3 = InputKey(type: Int.self)
        
        #expect(key1 == key2)
        #expect(key1 != key3)
    }
    
    @Test("InputKey keyed equality")
    func inputKeyKeyedEquality() {
        let key1 = InputKey(type: String.self, key: ConfigKey.primary)
        let key2 = InputKey(type: String.self, key: ConfigKey.primary)
        let key3 = InputKey(type: String.self, key: ConfigKey.secondary)
        
        #expect(key1 == key2)
        #expect(key1 != key3)
    }
    
    @Test("InputKey keyed vs non-keyed are different")
    func inputKeyKeyedVsNonKeyed() {
        let nonKeyed = InputKey(type: String.self)
        let keyed = InputKey(type: String.self, key: ConfigKey.primary)
        
        #expect(nonKeyed != keyed)
        #expect(nonKeyed.isKeyed == false)
        #expect(keyed.isKeyed == true)
    }
}
