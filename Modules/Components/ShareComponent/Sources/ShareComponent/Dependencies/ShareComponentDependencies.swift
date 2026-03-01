//
//  ShareComponentDependencies.swift
//  ShareComponent
//
//  Created by Stephane Magne
//

import ShareClientInterface
import ModularDependencyContainer

extension ShareComponent {
    @DependencyRequirements(
        mainActor: [
            Requirement(ShareClient.self)
        ]
    )
    public struct Dependencies: DependencyRequirements {}
}
