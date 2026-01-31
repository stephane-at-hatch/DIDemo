import Foundation

public struct LoggerConfiguration {
    public let domain: String

    public init(domain: String) {
        self.domain = domain
    }
}

public enum LogLevel: String {
    case debug
    case info
    case warning
    case error
}

/// Protocol defining the Core client interface
public struct Logger: Sendable {
    public var log: (_ message: @autoclosure () -> String, _ level: LogLevel) -> Void

    public init(log: @escaping (@autoclosure () -> String, LogLevel) -> Void) {
        self.log = log
    }
}
