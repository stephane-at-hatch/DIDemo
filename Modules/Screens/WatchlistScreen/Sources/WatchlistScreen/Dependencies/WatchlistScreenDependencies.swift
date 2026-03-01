//
//  WatchlistScreenDependencies.swift
//  WatchlistScreen
//
//  Created by Stephane Magne
//

import WatchlistDomainInterface
import TMDBClientInterface
import ShareClientInterface
import ShareClient
import ModularDependencyContainer

extension WatchlistScreen {
    @DependencyRequirements([
        Requirement(WatchlistRepository.self)
    ],
    inputs: [
        InputRequirement(TMDBConfiguration.self)
    ])
    public struct Dependencies: DependencyRequirements {
        public static func registerDependencies(in builder: DependencyBuilder<Self>) {
            do {
                try builder.registerInstance(ShareClient.self) { _ in
                    ShareClient.live()
                }
            } catch {
                preconditionFailure("Failed to build dependencies with error: \(error)")
            }
        }
    }
}
