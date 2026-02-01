import MovieDomainInterface
import TMDBClientInterface
import ModularDependencyContainer

extension BoxOfficeScreen {
    @DependencyRequirements([
        Requirement(MovieRepository.self)
    ],
    inputs: [
        InputRequirement(TMDBConfiguration.self)
    ])
    public struct Dependencies: DependencyRequirements {}
}
