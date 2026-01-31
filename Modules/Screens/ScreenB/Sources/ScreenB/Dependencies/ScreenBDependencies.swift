import Logger
import ModularDependencyContainer
import TestClientInterface

extension ScreenB {
    @DependencyRequirements([
        Requirement(Logger.self),
        Requirement(TestClientProtocol.self, key: TestClientKey.testClient, accessorName: "testClient"),
    ])
    public struct Dependencies: DependencyRequirements {}
}
