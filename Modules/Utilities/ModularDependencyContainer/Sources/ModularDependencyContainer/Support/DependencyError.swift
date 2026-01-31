//
//  DependencyError.swift
//  ModularDependencyContainer
//
//  Created by Stephane Magne on 2026-01-05.
//

// MARK: - Dependency Error

public enum DependencyError: Error, CustomStringConvertible, Sendable {
    case missingDependencies([String])
    case missingInputs([String])
    case resolutionFailed(String)
    case registrationExists(String)
    case inputNotFound(String)
    
    public var description: String {
        switch self {
        case .missingDependencies(let types):
            "Missing dependencies: \(types.joined(separator: ", "))"
        case .missingInputs(let types):
            "Missing inputs: \(types.joined(separator: ", "))"
        case .resolutionFailed(let message):
            message
        case .registrationExists(let message):
            message
        case .inputNotFound(let type):
            "Input not found: \(type)"
        }
    }
}
