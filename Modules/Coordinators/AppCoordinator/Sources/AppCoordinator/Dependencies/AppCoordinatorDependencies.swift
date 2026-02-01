import ModularDependencyContainer
import MovieDomain
import TMDBClient

extension AppCoordinator {
    @DependencyRequirements([
            Requirement(TMDBClient.self)
        ],
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
                    return TMDBClient.live(configuration: dependencies.tmdbConfiguration)
                }
                try builder.registerSingleton(MovieRepository.self) { container in
                    let dependencies = Self(container)
                    return MovieRepository.live(client: dependencies.tmdbClient)
                }
            } catch {
                preconditionFailure("Failed to build dependencies with error: \(error)")
            }
        }
    }
}
