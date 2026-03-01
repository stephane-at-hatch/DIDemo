//
//  ShareComponentDependencies+Mock.swift
//  ShareComponent
//
//  Created by Stephane Magne on 2026-02-28.
//

import ModularDependencyContainer
import ShareClientInterface

extension ShareComponent.Dependencies: TestDependencyProvider {
    public static func mockRegistration(in mockBuilder: MockDependencyBuilder<Self>) {
        try? mockBuilder.mainActor.registerSingleton(ShareClient.self) { _ in .mock() }
    }
}
