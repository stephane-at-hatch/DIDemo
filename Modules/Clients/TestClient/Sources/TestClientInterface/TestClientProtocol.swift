import Foundation

/// Protocol defining the Core client interface
public protocol TestClientProtocol: Sendable {
    func fetchData() async throws -> TestClientData
    func saveData(_ data: TestClientData) async throws
}

/// Data model used by TestClient
public struct TestClientData: Equatable, Sendable {
    public let id: String
    public let title: String
    public let timestamp: Date
    
    public init(id: String, title: String, timestamp: Date = Date()) {
        self.id = id
        self.title = title
        self.timestamp = timestamp
    }
}

/// Mock implementation for testing and previews
public final class MockTestClient: TestClientProtocol, @unchecked Sendable {
    public var fetchDataResult: Result<TestClientData, Error> = .success(
        TestClientData(id: "mock-1", title: "Mock Data")
    )
    
    public init() {}
    
    public func fetchData() async throws -> TestClientData {
        try await Task.sleep(for: .milliseconds(100))
        return try fetchDataResult.get()
    }
    
    public func saveData(_ data: TestClientData) async throws {
        // Mock implementation
    }
}

public enum TestClientKey {
    case testClient
}
