//
//  DetailScreenDependencies+Mock.swift
//  DetailScreen
//
//  Created by Stephane Magne on 2026-02-28.
//

import Foundation
import ModularDependencyContainer
import MovieDomainInterface
import WatchlistDomainInterface
import TMDBClientInterface

extension DetailScreen.Dependencies: TestDependencyProvider {
    public static func mockRegistration(in mockBuilder: MockDependencyBuilder<DetailScreen.Dependencies>) {
        try? mockBuilder.registerSingleton(
            MovieRepository.self,
            factory: { _ in .fixtureData }
        )
        
        mockBuilder.provideInput(TMDBConfiguration.self, .mock)
    }
}

