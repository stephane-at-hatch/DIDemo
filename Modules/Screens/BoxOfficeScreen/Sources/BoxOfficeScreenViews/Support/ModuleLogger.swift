//
//  ModuleLogger.swift
//  BoxOfficeScreenViews
//

import OSLog

let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "MovieFinder",
    category: "Screen.BoxOfficeScreenViews"
)
