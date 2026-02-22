import MovieDomainInterface
import WatchlistDomainInterface
import TMDBClientInterface
import ModularDependencyContainer

extension DetailScreen {
    @DependencyRequirements([
        Requirement(MovieRepository.self),
        Requirement(WatchlistRepository.self)
    ],
    inputs: [
        InputRequirement(TMDBConfiguration.self)
    ])
    public struct Dependencies: DependencyRequirements {}
}
