import MovieDomainInterface
import TMDBClientInterface
import ModularDependencyContainer

extension DetailScreen {
    @DependencyRequirements([
        Requirement(MovieRepository.self),
        Requirement(TMDBConfiguration.self)
    ])
    public struct Dependencies: DependencyRequirements {}
}
