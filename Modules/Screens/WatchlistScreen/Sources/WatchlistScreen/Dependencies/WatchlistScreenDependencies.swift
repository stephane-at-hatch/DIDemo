import WatchlistDomainInterface
import TMDBClientInterface
import ModularDependencyContainer

extension WatchlistScreen {
    @DependencyRequirements([
        Requirement(WatchlistRepository.self)
    ],
    inputs: [
        InputRequirement(TMDBConfiguration.self)
    ])
    public struct Dependencies: DependencyRequirements {}
}
