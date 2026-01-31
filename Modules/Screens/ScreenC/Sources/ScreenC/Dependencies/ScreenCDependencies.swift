import ModularDependencyContainer

extension ScreenC {
    @DependencyRequirements([])
    public struct Dependencies: DependencyRequirements {
        public static func registerDependencies(in builder: inout DependencyBuilder<Self>) {
            // Register any dependencies this module provides
        }
    }
}
