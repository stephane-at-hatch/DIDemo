import ModularDependencyContainer

extension AppCoordinator {
    @DependencyRequirements([
    ])
    public struct Dependencies: DependencyRequirements {
        public func registerDependencies(in container: ModularDependencyContainer.DependencyContainer<Dependencies>) {
            // Register any dependencies this module provides
        }
    }
}
