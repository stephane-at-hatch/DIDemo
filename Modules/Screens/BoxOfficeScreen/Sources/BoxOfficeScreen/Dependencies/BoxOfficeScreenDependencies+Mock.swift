//
//  BoxOfficeScreenDependencies+Mock.swift
//  BoxOfficeScreen
//
//  Created by Stephane Magne on 2026-03-01.
//

import DetailScreen
import MovieDomainInterface
import TMDBClientInterface
import ModularDependencyContainer

extension BoxOfficeScreen.Dependencies: TestDependencyProvider {
    public static func mockRegistration(in mockBuilder: MockDependencyBuilder<Self>) {
        mockBuilder.importDependencies(DetailScreen.Dependencies.self)
        
        mockBuilder.provideInput(TMDBConfiguration.self, .mock)
    }
}
