import ModularDependencyContainer
import TMDBClient

extension AppCoordinator {
    @DependencyRequirements([],
        inputs: [
            InputRequirement(TMDBConfiguration.self)
        ]
    )
    public struct Dependencies: DependencyRequirements {
        @MainActor
        public static func registerDependencies(in builder: DependencyBuilder<Self>) {
            do {
                try builder.registerSingleton(TMDBClient.self) { container in
                    let dependencies = Self(container)
                    return TMDBClient.live(configuration: dependencies.tMDBConfiguration)
                }
            } catch {
                preconditionFailure("Failed to build dependencies with error: \(error)")
            }
        }
    }
}
