//
//  AppDependencies.swift
//  MovieFinder
//
//  Created by Stephane Magne
//

import ModularDependencyContainer

@DependencyRequirements([])
public struct AppDependencies: DependencyRequirements {
    public static func registerDependencies(in builder: DependencyBuilder<Self>) {
        do {
        } catch {
            preconditionFailure("Failed to build dependencies with error: \(error)")
        }
    }
}
