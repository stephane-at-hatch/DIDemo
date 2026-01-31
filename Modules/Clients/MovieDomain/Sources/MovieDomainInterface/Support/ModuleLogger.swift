//
//  ModuleLogger.swift
//  MovieDomainInterface
//

import OSLog

let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "MovieFinder",
    category: "Client.MovieDomainInterface"
)
