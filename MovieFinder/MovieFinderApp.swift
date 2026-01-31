//
//  MovieFinderApp.swift
//  MovieFinder
//
//  Created by Stephane Magne
//

import ModularDependencyContainer
import SwiftUI

@main
struct MovieFinderApp: App {

    let appDependencies: AppDependencies = RootDependencyBuilder.buildChild(AppDependencies.self)

    var body: some Scene {
        WindowGroup {
            ContentView(appDependencies: appDependencies)
        }
    }
}
