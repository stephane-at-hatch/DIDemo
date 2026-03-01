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
        
        mockBuilder.provideInput(
            TMDBConfiguration.self,
            TMDBConfiguration(
                apiReadAccessToken: "test-token",
                apiBaseURL: URL(string: "https://api.themoviedb.org")!,
                imageBaseURL: URL(string: "https://images.themoviedb.org")!,
                region: "US",
                language: "en"
            )
        )
    }
}

