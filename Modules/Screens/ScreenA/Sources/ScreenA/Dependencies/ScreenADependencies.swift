//
//  ScreenADependencies.swift
//  ScreenA
//
//  Created by Stephane Magne
//

import Logger
import ModularDependencyContainer
import TestClientInterface

extension ScreenA {
    @DependencyRequirements([
        Requirement(TestClientProtocol.self, key: TestClientKey.testClient, accessorName: "testClient"),
        Requirement(Logger.self)
    ],
    inputs: [
        InputRequirement(LoggerConfiguration.self)
    ])
    public struct Dependencies: DependencyRequirements {
        public static func registerDependencies(in builder: DependencyBuilder<Self>) {
            try! builder.registerInstance(Logger.self, override: true) { container in
                let configuration = try container.resolveInput(LoggerConfiguration.self)
                return Logger.live(domain: configuration.domain)
            }
        }
    }
}
