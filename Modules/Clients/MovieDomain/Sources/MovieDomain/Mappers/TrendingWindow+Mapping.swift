//
//  TrendingWindow+Mapping.swift
//  MovieDomain
//
//  Created by Stephane Magne
//

import Foundation
import MovieDomainInterface
import TMDBClientInterface

extension TrendingWindow {

    func toDTO() -> TrendingTimeWindow {
        switch self {
        case .day:
            return .day
        case .week:
            return .week
        }
    }
}
