//
//  ContentView.swift
//  MovieFinder
//
//  Created by Stephane Magne
//

import AppCoordinator
import ModularDependencyContainer
import SwiftUI

struct ContentView: View {

    let appCoordinatorViewModel: AppCoordinatorViewModel

    init(
        appDependencies: AppDependencies
    ) {
        let appCoordinatorDependencies = appDependencies.buildChild(AppCoordinator.Dependencies.self)
        self.appCoordinatorViewModel = AppCoordinatorViewModel(dependencies: appCoordinatorDependencies)
    }

    var body: some View {
        VStack {
            AppCoordinatorRootView(viewModel: appCoordinatorViewModel)
        }
        .padding()
    }
}

#Preview {
    let appDependencies = RootDependencyBuilder.buildChild(AppDependencies.self)
    ContentView(appDependencies: appDependencies)
}
