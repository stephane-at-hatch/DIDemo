//
//  AppDependencies.swift
//  MovieFinder
//
//  Created by Stephane Magne
//

import Logger
import ModularDependencyContainer
import TestClient

@DependencyRequirements([])
public struct AppDependencies: DependencyRequirements {
    public static func registerDependencies(in builder: DependencyBuilder<Self>) {
        // Register Inputs
        let configuration = LoggerConfiguration(domain: "MovieFinder")
        builder.provideInput(LoggerConfiguration.self, configuration)

        do {
            // Register Dependencies
            try builder.registerSingleton(TestClientProtocol.self, key: TestClientKey.testClient) { _ in
                TestClient()
            }
            try builder.registerInstance(Logger.self) { container in
                let configuration = try! container.resolveInput(LoggerConfiguration.self)
                return Logger.live(domain: configuration.domain)
            }
        } catch {
            preconditionFailure("Failed to build dependencies with error: \(error)")
        }
    }
}
