//
//  AppCoordinatorRootView.swift
//  AppCoordinator
//
//  Created by Stephane Magne on 2026-01-31.
//

import TabCoordinator
import SwiftUI

public struct AppCoordinatorRootView: View {

    @State private var viewModel: AppCoordinatorViewModel

    public init(viewModel: AppCoordinatorViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        TabCoordinatorRootView(viewModel: viewModel.tabCoordinatorViewModel)
    }
}
