//
//  ModuleLogger.swift
//  MovieDomain
//

import OSLog

private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "MovieFinder",
    category: "Client.MovieDomain"
)
