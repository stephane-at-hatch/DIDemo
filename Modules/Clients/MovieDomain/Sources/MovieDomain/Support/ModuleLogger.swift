//
//  ModuleLogger.swift
//  MovieDomain
//

import OSLog

let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "MovieFinder",
    category: "Client.MovieDomain"
)
