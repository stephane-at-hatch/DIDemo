//
//  NavigationCoordinatorTests.swift
//  HatchModularNavigationTests
//
//  Created by Stephane Magne on 2025-11-06.
//  Copyright hatch.co, 2025.
//

@testable import ModularNavigation
import SwiftUI
import Testing

// MARK: - Test Destinations

enum TestDestination: Hashable {
    case home
    case detail(id: String)
    case settings
}

enum ChildDestination: Hashable {
    case childHome
    case childDetail
}

// MARK: - Navigation Coordinator Tests

@MainActor
struct NavigationCoordinatorTests {
    // MARK: - Initialization Tests
    
    @Test("Coordinator initializes as root with empty route")
    func testRootInitialization() {
        let coordinator = NavigationCoordinator<TestDestination>(
            type: .root,
            presentationMode: .root,
            route: [],
            didConsumeRoute: {},
            dismissParent: { false }
        )
        
        #expect(coordinator.isRoot == true)
        #expect(coordinator.presentationMode == .root)
        #expect(coordinator.presentationBindings?.sheet.wrappedValue?.value == nil)
        #expect(coordinator.presentationBindings?.fullScreenCover.wrappedValue?.value == nil)
    }
    
    @Test("Coordinator initializes as nested navigation")
    func testNestedInitialization() {
        var path = NavigationPath()
        let pathBinding = Binding<NavigationPath>(
            get: { path },
            set: { path = $0 }
        )
        
        let coordinator = NavigationCoordinator<TestDestination>(
            type: .nested(path: pathBinding),
            presentationMode: .push,
            route: [],
            didConsumeRoute: {},
            dismissParent: { false }
        )
        
        #expect(coordinator.isRoot == false)
        #expect(coordinator.presentationMode == .push)
    }
    
    // MARK: - Push Navigation Tests
    
    @Test("Push adds destination to navigation path")
    func testPushDestination() async throws {
        var path = NavigationPath()
        let pathBinding = Binding<NavigationPath>(
            get: { path },
            set: { path = $0 }
        )
        
        let coordinator = NavigationCoordinator<TestDestination>(
            type: .root,
            presentationMode: .root,
            route: [],
            didConsumeRoute: {},
            dismissParent: { false }
        )
        
        coordinator.rootPath = pathBinding
        
        coordinator.present(.home, mode: .push)
        
        #expect(path.count == 1)
    }
    
    @Test("Push multiple destinations")
    func testPushMultipleDestinations() async throws {
        var path = NavigationPath()
        let pathBinding = Binding<NavigationPath>(
            get: { path },
            set: { path = $0 }
        )
        
        let coordinator = NavigationCoordinator<TestDestination>(
            type: .root,
            presentationMode: .root,
            route: [],
            didConsumeRoute: {},
            dismissParent: { false }
        )
        coordinator.rootPath = pathBinding
        
        coordinator.present(.home, mode: .push)
        coordinator.present(.detail(id: "123"), mode: .push)
        coordinator.present(.settings, mode: .push)
        
        #expect(path.count == 3)
    }
    
    @Test("Pop removes last destination from path")
    func testPopDestination() async throws {
        var path = NavigationPath()
        let pathBinding = Binding<NavigationPath>(
            get: { path },
            set: { path = $0 }
        )
        
        let coordinator = NavigationCoordinator<TestDestination>(
            type: .root,
            presentationMode: .root,
            route: [],
            didConsumeRoute: {},
            dismissParent: { false }
        )
        coordinator.rootPath = pathBinding
        
        coordinator.present(.home, mode: .push)
        coordinator.present(.detail(id: "123"), mode: .push)
        
        #expect(path.count == 2)
        
        coordinator.pop()
        
        #expect(path.count == 1)
    }
    
    @Test("Pop to root clears navigation path")
    func testPopToRoot() async throws {
        var path = NavigationPath()
        let pathBinding = Binding<NavigationPath>(
            get: { path },
            set: { path = $0 }
        )
        
        let coordinator = NavigationCoordinator<TestDestination>(
            type: .root,
            presentationMode: .root,
            route: [],
            didConsumeRoute: {},
            dismissParent: { false }
        )
        coordinator.rootPath = pathBinding
        
        coordinator.present(.home, mode: .push)
        coordinator.present(.detail(id: "123"), mode: .push)
        coordinator.present(.settings, mode: .push)
        
        #expect(path.count == 3)
        
        coordinator.popToRoot()
        
        #expect(path.isEmpty == true)
    }
    
    // MARK: - Sheet Presentation Tests
    
    @Test("Present sheet sets sheet binding")
    func testPresentSheet() async throws {
        var presentation = PresentationBindings<TestDestination>()
        let presentationBinding = Binding<PresentationBindings<TestDestination>>(
            get: { presentation },
            set: { presentation = $0 }
        )

        let coordinator = NavigationCoordinator<TestDestination>(
            type: .root,
            presentationMode: .root,
            route: [],
            didConsumeRoute: {},
            dismissParent: { false }
        )
        
        coordinator.presentationBindings = presentationBinding
        
        coordinator.present(.settings, mode: .sheet)
        
        #expect(coordinator.presentationBindings?.sheet.wrappedValue?.value != nil)
        #expect(coordinator.presentationBindings?.sheet.wrappedValue?.value.destination == .settings)
    }

    @Test("Present sheet sets sheet binding with custom detents")
    func testPresentSheetCustomDetents() async throws {
        var presentation = PresentationBindings<TestDestination>()
        let presentationBinding = Binding<PresentationBindings<TestDestination>>(
            get: { presentation },
            set: { presentation = $0 }
        )

        let coordinator = NavigationCoordinator<TestDestination>(
            type: .root,
            presentationMode: .root,
            route: [],
            didConsumeRoute: {},
            dismissParent: { false }
        )
        
        coordinator.presentationBindings = presentationBinding
        
        coordinator.present(.settings, mode: .sheet(detents: [.medium]))
        
        #expect(coordinator.presentationBindings?.sheet.wrappedValue?.value != nil)
        #expect(coordinator.presentationBindings?.sheet.wrappedValue?.value.destination == .settings)
        #expect(coordinator.presentationBindings?.sheet.wrappedValue?.value.detents == [.medium])
    }

    @Test("Present sheet when sheet already presented does nothing")
    func testPresentSheetWhenAlreadyPresented() async throws {
        var presentation = PresentationBindings<TestDestination>()
        let presentationBinding = Binding<PresentationBindings<TestDestination>>(
            get: { presentation },
            set: { presentation = $0 }
        )

        let coordinator = NavigationCoordinator<TestDestination>(
            type: .root,
            presentationMode: .root,
            route: [],
            didConsumeRoute: {},
            dismissParent: { false }
        )
        
        coordinator.presentationBindings = presentationBinding
        
        coordinator.present(.settings, mode: .sheet)
        
        let firstSheetId = coordinator.presentationBindings?.sheet.wrappedValue?.id
        
        coordinator.present(.home, mode: .sheet)
        
        // Should still be the first sheet
        #expect(coordinator.presentationBindings?.sheet.wrappedValue?.id == firstSheetId)
        #expect(coordinator.presentationBindings?.sheet.wrappedValue?.value.destination == .settings)
    }

    @Test("Present sheet when cover already presented does nothing")
    func testPresentSheetWhenCoverAlreadyPresented() async throws {
        var presentation = PresentationBindings<TestDestination>()
        let presentationBinding = Binding<PresentationBindings<TestDestination>>(
            get: { presentation },
            set: { presentation = $0 }
        )

        let coordinator = NavigationCoordinator<TestDestination>(
            type: .root,
            presentationMode: .root,
            route: [],
            didConsumeRoute: {},
            dismissParent: { false }
        )
        
        coordinator.presentationBindings = presentationBinding
        
        coordinator.present(.settings, mode: .cover)
        
        let firstSheetId = coordinator.presentationBindings?.fullScreenCover.wrappedValue?.id
        
        coordinator.present(.home, mode: .sheet)
        
        // Should still be the first sheet
        #expect(coordinator.presentationBindings?.sheet.wrappedValue?.id == nil)
        #expect(coordinator.presentationBindings?.fullScreenCover.wrappedValue?.id == firstSheetId)
        #expect(coordinator.presentationBindings?.fullScreenCover.wrappedValue?.value.destination == .settings)
    }

    @Test("Dismiss sheet clears sheet binding")
    func testDismissSheet() async throws {
        var presentation = PresentationBindings<TestDestination>()
        let presentationBinding = Binding<PresentationBindings<TestDestination>>(
            get: { presentation },
            set: { presentation = $0 }
        )

        let coordinator = NavigationCoordinator<TestDestination>(
            type: .root,
            presentationMode: .root,
            route: [],
            didConsumeRoute: {},
            dismissParent: { false }
        )
        
        coordinator.presentationBindings = presentationBinding
        
        coordinator.present(.settings, mode: .sheet)
        
        #expect(coordinator.presentationBindings?.sheet.wrappedValue?.value != nil)
        
        coordinator.dismissSheet()
        
        #expect(coordinator.presentationBindings?.sheet.wrappedValue?.value == nil)
    }
    
    // MARK: - Full Screen Cover Tests
    
    @Test("Present full screen cover sets cover binding")
    func testPresentFullScreenCover() async throws {
        var presentation = PresentationBindings<TestDestination>()
        let presentationBinding = Binding<PresentationBindings<TestDestination>>(
            get: { presentation },
            set: { presentation = $0 }
        )

        let coordinator = NavigationCoordinator<TestDestination>(
            type: .root,
            presentationMode: .root,
            route: [],
            didConsumeRoute: {},
            dismissParent: { false }
        )
        
        coordinator.presentationBindings = presentationBinding
        
        coordinator.present(.detail(id: "456"), mode: .cover)
        
        #expect(coordinator.presentationBindings?.fullScreenCover != nil)
        #expect(coordinator.presentationBindings?.fullScreenCover.wrappedValue?.value.destination == .detail(id: "456"))
    }
    
    @Test("Present cover when cover already presented does nothing")
    func testPresentCoverWhenAlreadyPresented() async throws {
        var presentation = PresentationBindings<TestDestination>()
        let presentationBinding = Binding<PresentationBindings<TestDestination>>(
            get: { presentation },
            set: { presentation = $0 }
        )

        let coordinator = NavigationCoordinator<TestDestination>(
            type: .root,
            presentationMode: .root,
            route: [],
            didConsumeRoute: {},
            dismissParent: { false }
        )
        
        coordinator.presentationBindings = presentationBinding
        
        coordinator.present(.detail(id: "456"), mode: .cover)
        
        let firstCoverId = coordinator.presentationBindings?.fullScreenCover.wrappedValue?.id
        
        coordinator.present(.home, mode: .cover)
        
        // Should still be the first cover
        #expect(coordinator.presentationBindings?.fullScreenCover.wrappedValue?.id == firstCoverId)
        #expect(coordinator.presentationBindings?.fullScreenCover.wrappedValue?.value.destination == .detail(id: "456"))
    }

    @Test("Present cover when sheet already presented does nothing")
    func testPresentCoverWhenSheetAlreadyPresented() async throws {
        var presentation = PresentationBindings<TestDestination>()
        let presentationBinding = Binding<PresentationBindings<TestDestination>>(
            get: { presentation },
            set: { presentation = $0 }
        )

        let coordinator = NavigationCoordinator<TestDestination>(
            type: .root,
            presentationMode: .root,
            route: [],
            didConsumeRoute: {},
            dismissParent: { false }
        )
        
        coordinator.presentationBindings = presentationBinding
        
        coordinator.present(.detail(id: "456"), mode: .sheet)
        
        let firstCoverId = coordinator.presentationBindings?.sheet.wrappedValue?.id
        
        coordinator.present(.home, mode: .cover)
        
        // Should still be the first cover
        #expect(coordinator.presentationBindings?.fullScreenCover.wrappedValue?.id == nil)
        #expect(coordinator.presentationBindings?.sheet.wrappedValue?.id == firstCoverId)
        #expect(coordinator.presentationBindings?.sheet.wrappedValue?.value.destination == .detail(id: "456"))
    }

    @Test("Dismiss full screen cover clears cover binding")
    func testDismissFullScreenCover() async throws {
        var presentation = PresentationBindings<TestDestination>()
        let presentationBinding = Binding<PresentationBindings<TestDestination>>(
            get: { presentation },
            set: { presentation = $0 }
        )

        let coordinator = NavigationCoordinator<TestDestination>(
            type: .root,
            presentationMode: .root,
            route: [],
            didConsumeRoute: {},
            dismissParent: { false }
        )
        
        coordinator.presentationBindings = presentationBinding
        
        coordinator.present(.detail(id: "456"), mode: .cover)
        
        #expect(coordinator.presentationBindings?.fullScreenCover.wrappedValue?.value != nil)
        
        coordinator.dismissFullScreenCover()
        
        #expect(coordinator.presentationBindings?.fullScreenCover.wrappedValue?.value == nil)
    }
    
    // MARK: - Smart Dismiss Tests
    
    @Test("Smart dismiss prioritizes sheet over navigation pop")
    func testSmartDismissPrioritizesSheet() async throws {
        var path = NavigationPath()
        let pathBinding = Binding<NavigationPath>(
            get: { path },
            set: { path = $0 }
        )

        var presentation = PresentationBindings<TestDestination>()
        let presentationBinding = Binding<PresentationBindings<TestDestination>>(
            get: { presentation },
            set: { presentation = $0 }
        )

        let coordinator = NavigationCoordinator<TestDestination>(
            type: .root,
            presentationMode: .root,
            route: [],
            didConsumeRoute: {},
            dismissParent: { false }
        )
        
        coordinator.rootPath = pathBinding
        coordinator.presentationBindings = presentationBinding
        
        coordinator.present(.home, mode: .push)
        
        coordinator.present(.settings, mode: .sheet)
        
        #expect(path.count == 1)
        #expect(coordinator.presentationBindings?.sheet.wrappedValue?.value != nil)
        
        coordinator.dismiss()
        
        // Sheet should be dismissed, path should remain
        #expect(coordinator.presentationBindings?.sheet.wrappedValue?.value == nil)
        #expect(path.count == 1)
    }
    
    @Test("Smart dismiss prioritizes cover over navigation pop")
    func testSmartDismissPrioritizesCover() async throws {
        var path = NavigationPath()
        let pathBinding = Binding<NavigationPath>(
            get: { path },
            set: { path = $0 }
        )
        
        var presentation = PresentationBindings<TestDestination>()
        let presentationBinding = Binding<PresentationBindings<TestDestination>>(
            get: { presentation },
            set: { presentation = $0 }
        )

        let coordinator = NavigationCoordinator<TestDestination>(
            type: .root,
            presentationMode: .root,
            route: [],
            didConsumeRoute: {},
            dismissParent: { false }
        )
        
        coordinator.rootPath = pathBinding
        coordinator.presentationBindings = presentationBinding
        
        coordinator.present(.home, mode: .push)
        
        coordinator.present(.settings, mode: .cover)
        
        #expect(path.count == 1)
        #expect(coordinator.presentationBindings?.fullScreenCover.wrappedValue?.value != nil)
        
        coordinator.dismiss()
        
        // Cover should be dismissed, path should remain
        #expect(coordinator.presentationBindings?.fullScreenCover.wrappedValue?.value == nil)
        #expect(path.count == 1)
    }
    
    @Test("Smart dismiss pops from navigation when no modals")
    func testSmartDismissPopsNavigation() async throws {
        var path = NavigationPath()
        let pathBinding = Binding<NavigationPath>(
            get: { path },
            set: { path = $0 }
        )
        
        let coordinator = NavigationCoordinator<TestDestination>(
            type: .root,
            presentationMode: .root,
            route: [],
            didConsumeRoute: {},
            dismissParent: { false }
        )
        coordinator.rootPath = pathBinding
        
        coordinator.present(.home, mode: .push)
        coordinator.present(.detail(id: "123"), mode: .push)
        
        #expect(path.count == 2)
        
        coordinator.dismiss()
        
        #expect(path.count == 1)
    }
    
    @Test("Smart dismiss calls dismiss parent when path empty")
    func testSmartDismissCallsDismissParent() async throws {
        var path = NavigationPath()
        let pathBinding = Binding<NavigationPath>(
            get: { path },
            set: { path = $0 }
        )
        var dismissParentCalled = false
        
        let coordinator = NavigationCoordinator<TestDestination>(
            type: .root,
            presentationMode: .root,
            route: [],
            didConsumeRoute: {},
            dismissParent: {
                dismissParentCalled = true
                return false
            }
        )
        coordinator.rootPath = pathBinding
        
        #expect(path.isEmpty == true)
        
        coordinator.dismiss()
        
        #expect(dismissParentCalled == true)
    }
    
    // MARK: - Close Tests
    
    @Test("Close always calls dismiss parent")
    func testCloseCallsDismissParent() async throws {
        var path = NavigationPath()
        let pathBinding = Binding<NavigationPath>(
            get: { path },
            set: { path = $0 }
        )
        var dismissParentCalled = false
        
        let coordinator = NavigationCoordinator<TestDestination>(
            type: .root,
            presentationMode: .root,
            route: [],
            didConsumeRoute: {},
            dismissParent: {
                dismissParentCalled = true
                return false
            }
        )
        coordinator.rootPath = pathBinding
        
        coordinator.present(.home, mode: .push)
        
        coordinator.close()
        
        #expect(dismissParentCalled == true)
    }
    
    // MARK: - Deep Linking Tests
    
    @Test("Root coordinator processes deep link route")
    func testRootDeepLinking() async throws {
        let steps = [
            NavigationStep(destination: TestDestination.home, mode: .push),
            NavigationStep(destination: TestDestination.detail(id: "123"), mode: .push)
        ]
        let route: AnyRoute = [steps.anySteps()]
        
        let coordinator = NavigationCoordinator<TestDestination>(
            type: .nested(path: nil),
            presentationMode: .root,
            route: route,
            didConsumeRoute: {},
            dismissParent: { false }
        )
        
        // Verify initial steps were extracted
        #expect(coordinator.deepLinkRoute.initialSteps.count == 2)
        #expect(coordinator.deepLinkRoute.initialSteps[0].destination == .home)
        #expect(coordinator.deepLinkRoute.initialSteps[1].destination == .detail(id: "123"))
    }
    
    @Test("Nested coordinator consumes matching route")
    func testNestedCoordinatorConsumesRoute() {
        let steps = [
            NavigationStep(destination: TestDestination.home, mode: .push)
        ]
        let route: AnyRoute = [steps.anySteps()]
        
        let coordinator = NavigationCoordinator<TestDestination>(
            type: .nested(path: nil),
            presentationMode: .push,
            route: route,
            didConsumeRoute: {},
            dismissParent: { false }
        )
        
        // Should consume the matching route
        #expect(coordinator.deepLinkRoute.initialSteps.count == 1)
        #expect(coordinator.deepLinkRoute.handoffRoute.isEmpty == true)
    }
    
    @Test("Nested coordinator passes through non-matching route")
    func testNestedCoordinatorPassesThroughRoute() {
        let childSteps = [
            NavigationStep(destination: ChildDestination.childHome, mode: .push)
        ]
        let route: AnyRoute = [childSteps.anySteps()]
        
        let coordinator = NavigationCoordinator<TestDestination>(
            type: .nested(path: nil),
            presentationMode: .push,
            route: route,
            didConsumeRoute: {},
            dismissParent: { false }
        )
        
        // Should not consume non-matching route
        #expect(coordinator.deepLinkRoute.initialSteps.isEmpty == true)
        #expect(coordinator.deepLinkRoute.handoffRoute.count == 1)
    }
    
    @Test("New coordinator receives handoff route")
    func testNewCoordinatorHandoff() {
        let firstSteps = [
            NavigationStep(destination: TestDestination.home, mode: .push)
        ]
        let secondSteps = [
            NavigationStep(destination: ChildDestination.childHome, mode: .push)
        ]
        let route: AnyRoute = [firstSteps.anySteps(), secondSteps.anySteps()]
        
        let parentCoordinator = NavigationCoordinator<TestDestination>(
            type: .nested(path: nil),
            presentationMode: .root,
            route: route,
            didConsumeRoute: {},
            dismissParent: { false }
        )
        
        // Parent consumes first segment
        #expect(parentCoordinator.deepLinkRoute.initialSteps.count == 1)
        #expect(parentCoordinator.deepLinkRoute.handoffRoute.count == 1)
        
        // Create child coordinator
        let childCoordinator: NavigationCoordinator<ChildDestination> = parentCoordinator.newCoordinator(monitor: DestinationMonitor(mode: .push))
        
        // Child should receive handoff
        #expect(childCoordinator.deepLinkRoute.initialSteps.count == 1)
        #expect(childCoordinator.deepLinkRoute.initialSteps[0].destination == .childHome)
    }
    
    // MARK: - Hashable Tests
    
    @Test("Coordinators with same UUID are equal")
    func testCoordinatorEquality() {
        let coordinator1 = NavigationCoordinator<TestDestination>(
            type: .root,
            presentationMode: .root,
            route: [],
            didConsumeRoute: {},
            dismissParent: { false }
        )
        
        let coordinator2 = coordinator1
        
        #expect(coordinator1 == coordinator2)
    }
    
    @Test("Coordinators with different UUIDs are not equal")
    func testCoordinatorInequality() {
        let coordinator1 = NavigationCoordinator<TestDestination>(
            type: .root,
            presentationMode: .root,
            route: [],
            didConsumeRoute: {},
            dismissParent: { false }
        )
        
        let coordinator2 = NavigationCoordinator<TestDestination>(
            type: .root,
            presentationMode: .root,
            route: [],
            didConsumeRoute: {},
            dismissParent: { false }
        )
        
        #expect(coordinator1 != coordinator2)
    }
    
    @Test("Coordinator hash is based on UUID")
    func testCoordinatorHash() {
        let coordinator = NavigationCoordinator<TestDestination>(
            type: .root,
            presentationMode: .root,
            route: [],
            didConsumeRoute: {},
            dismissParent: { false }
        )
        
        var hasher1 = Hasher()
        coordinator.hash(into: &hasher1)
        let hash1 = hasher1.finalize()
        
        var hasher2 = Hasher()
        coordinator.hash(into: &hasher2)
        let hash2 = hasher2.finalize()
        
        #expect(hash1 == hash2)
    }
    
    // MARK: - Dismiss for Mode Tests
    
    @Test("Dismiss for push mode pops navigation")
    func testDismissForPushMode() async throws {
        var path = NavigationPath()
        let pathBinding = Binding<NavigationPath>(
            get: { path },
            set: { path = $0 }
        )
        
        let coordinator = NavigationCoordinator<TestDestination>(
            type: .root,
            presentationMode: .root,
            route: [],
            didConsumeRoute: {},
            dismissParent: { false }
        )
        coordinator.rootPath = pathBinding
        
        coordinator.present(.home, mode: .push)
        
        #expect(path.count == 1)
        
        coordinator.dismiss(for: .push)
        
        #expect(path.isEmpty == true)
    }
    
    @Test("Dismiss for sheet mode dismisses sheet")
    func testDismissForSheetMode() async throws {
        var presentation = PresentationBindings<TestDestination>()
        let presentationBinding = Binding<PresentationBindings<TestDestination>>(
            get: { presentation },
            set: { presentation = $0 }
        )

        let coordinator = NavigationCoordinator<TestDestination>(
            type: .root,
            presentationMode: .root,
            route: [],
            didConsumeRoute: {},
            dismissParent: { false }
        )
        
        coordinator.presentationBindings = presentationBinding
        
        coordinator.present(.settings, mode: .sheet)
        
        #expect(coordinator.presentationBindings?.sheet.wrappedValue?.value != nil)
        
        coordinator.dismiss(for: .sheet)
        
        #expect(coordinator.presentationBindings?.sheet.wrappedValue?.value == nil)
    }
    
    @Test("Dismiss for cover mode dismisses cover")
    func testDismissForCoverMode() async throws {
        var presentation = PresentationBindings<TestDestination>()
        let presentationBinding = Binding<PresentationBindings<TestDestination>>(
            get: { presentation },
            set: { presentation = $0 }
        )

        let coordinator = NavigationCoordinator<TestDestination>(
            type: .root,
            presentationMode: .root,
            route: [],
            didConsumeRoute: {},
            dismissParent: { false }
        )
        
        coordinator.presentationBindings = presentationBinding
        
        coordinator.present(.settings, mode: .cover)
        
        #expect(coordinator.presentationBindings?.fullScreenCover.wrappedValue?.value != nil)
        
        coordinator.dismiss(for: .cover)
        
        #expect(coordinator.presentationBindings?.fullScreenCover.wrappedValue?.value == nil)
    }
    
    @Test("Dismiss for root mode does nothing")
    func testDismissForRootMode() {
        var dismissParentCalled = false
        
        let coordinator = NavigationCoordinator<TestDestination>(
            type: .root,
            presentationMode: .root,
            route: [],
            didConsumeRoute: {},
            dismissParent: {
                dismissParentCalled = true
                return false
            }
        )
        
        coordinator.dismiss(for: .root)
        
        #expect(dismissParentCalled == false)
    }
    
    // MARK: - Test Nested Path
    
    @Test("Multiple coordinators push to the same path")
    func testMultipleCoordinatorsPushToTheSamePath() {
        var path = NavigationPath()
        let pathBinding = Binding<NavigationPath>(
            get: { path },
            set: { path = $0 }
        )
        
        let coordinator = NavigationCoordinator<TestDestination>(
            type: .nested(path: nil),
            presentationMode: .root,
            route: [],
            didConsumeRoute: {},
            dismissParent: { false }
        )
        
        coordinator.rootPath = pathBinding
    
        let childCoordinator: NavigationCoordinator<ChildDestination> = coordinator.newCoordinator(monitor: DestinationMonitor(mode: .push))
        
        #expect(path.isEmpty)
        
        coordinator.present(.home, mode: .push)
        
        #expect(path.count == 1)
        
        childCoordinator.present(.childDetail, mode: .push)
        
        #expect(path.count == 2)
    }
    
    @Test("Multiple coordinators push to the same chained path")
    func testMultipleCoordinatorsPushToTheSameChainedPath() {
        var path = NavigationPath()
        let pathBinding = Binding<NavigationPath>(
            get: { path },
            set: { path = $0 }
        )

        let coordinator = NavigationCoordinator<TestDestination>(
            type: .nested(path: pathBinding),
            presentationMode: .root,
            route: [],
            didConsumeRoute: {},
            dismissParent: { false }
        )
        
        let childCoordinator: NavigationCoordinator<ChildDestination> = coordinator.newCoordinator(monitor: DestinationMonitor(mode: .push))
        
        #expect(path.isEmpty)

        coordinator.present(.home, mode: .push)

        #expect(path.count == 1)

        childCoordinator.present(.childDetail, mode: .push)

        #expect(path.count == 2)
    }

    // MARK: - Process Initial Route Tests

    @Test("processInitialRoute calls didConsumeRoute and appends steps")
    func testProcessInitialRouteCallsDidConsumeRoute() {
        var path = NavigationPath()
        let pathBinding = Binding<NavigationPath>(
            get: { path },
            set: { path = $0 }
        )

        var didConsumeRouteCalled = false

        let steps = [
            NavigationStep(destination: TestDestination.home, mode: .push),
            NavigationStep(destination: TestDestination.detail(id: "123"), mode: .push)
        ]
        let route: AnyRoute = [steps.anySteps()]

        let coordinator = NavigationCoordinator<TestDestination>(
            type: .nested(path: nil),
            presentationMode: .push,
            route: route,
            didConsumeRoute: { didConsumeRouteCalled = true },
            dismissParent: { false }
        )
        coordinator.rootPath = pathBinding

        #expect(coordinator.deepLinkRoute.initialSteps.count == 2)

        coordinator.processInitialRoute()

        #expect(didConsumeRouteCalled == true)
        #expect(coordinator.deepLinkRoute.initialSteps.isEmpty == true)
        #expect(path.count == 2)
    }

    @Test("processInitialRoute does nothing when no initial steps")
    func testProcessInitialRouteNoOpWhenEmpty() {
        var didConsumeRouteCalled = false

        let coordinator = NavigationCoordinator<TestDestination>(
            type: .nested(path: nil),
            presentationMode: .push,
            route: [],
            didConsumeRoute: { didConsumeRouteCalled = true },
            dismissParent: { false }
        )

        coordinator.processInitialRoute()

        #expect(didConsumeRouteCalled == false)
    }

    @Test("newCoordinator chains didConsumeRoute to clear parent handoff")
    func testNewCoordinatorChainsDidConsumeRoute() {
        var parentConsumeRouteCalled = false

        let firstSteps = [
            NavigationStep(destination: TestDestination.home, mode: .push)
        ]
        let secondSteps = [
            NavigationStep(destination: ChildDestination.childHome, mode: .push)
        ]
        let route: AnyRoute = [firstSteps.anySteps(), secondSteps.anySteps()]

        var path = NavigationPath()
        let pathBinding = Binding<NavigationPath>(
            get: { path },
            set: { path = $0 }
        )

        let parentCoordinator = NavigationCoordinator<TestDestination>(
            type: .nested(path: nil),
            presentationMode: .root,
            route: route,
            didConsumeRoute: { parentConsumeRouteCalled = true },
            dismissParent: { false }
        )
        parentCoordinator.rootPath = pathBinding

        // Parent has handoff route before child consumes it
        #expect(parentCoordinator.deepLinkRoute.handoffRoute.count == 1)

        let childCoordinator: NavigationCoordinator<ChildDestination> = parentCoordinator.newCoordinator(monitor: DestinationMonitor(mode: .push))
        childCoordinator.rootPath = pathBinding

        // Child consumed the route, but parent handoff not yet cleared
        #expect(childCoordinator.deepLinkRoute.initialSteps.count == 1)

        // Processing the child route triggers the chain
        childCoordinator.processInitialRoute()

        // Parent's handoff route should be cleared
        #expect(parentCoordinator.deepLinkRoute.handoffRoute.isEmpty == true)
        #expect(parentConsumeRouteCalled == true)
    }

    // MARK: - Deep Link Destination Factory Tests

    @Test("deepLinkDestination creates step with animated false")
    func testDeepLinkDestinationFactory() {
        let step = NavigationStep<TestDestination>.deepLinkDestination(.settings, as: .push)

        #expect(step.destination == .settings)
        #expect(step.mode == .push)
        #expect(step.animated == false)
    }

    // MARK: - Entry Monitor Tests

    @Test("EntryMonitor initializes with all flags false")
    func testEntryMonitorInitialization() {
        let monitor = EntryMonitor()

        #expect(monitor.isCurrentlyInSameModule == false)
        #expect(monitor.isNavigatingToExternal == false)
        #expect(monitor.manuallyDisableNavStack == false)
        #expect(monitor.shouldSuppressPushNavigation == false)
    }

    @Test("EntryMonitor suppresses navigation when both module flags are true")
    func testEntryMonitorshouldSuppressPushNavigation() {
        let monitor = EntryMonitor()

        monitor.isCurrentlyInSameModule = true
        monitor.isNavigatingToExternal = false
        #expect(monitor.shouldSuppressPushNavigation == false)

        monitor.isCurrentlyInSameModule = false
        monitor.isNavigatingToExternal = true
        #expect(monitor.shouldSuppressPushNavigation == false)

        monitor.isCurrentlyInSameModule = true
        monitor.isNavigatingToExternal = true
        #expect(monitor.shouldSuppressPushNavigation == true)
    }

    @Test("EntryMonitor suppresses navigation when manuallyDisableNavStack is true")
    func testEntryMonitorManuallyDisableNavStack() {
        let monitor = EntryMonitor()

        monitor.manuallyDisableNavStack = true
        #expect(monitor.shouldSuppressPushNavigation == true)
    }

    @Test("EntryMonitor suppresses navigation when manuallyDisableNavStack is true regardless of module flags")
    func testEntryMonitorManuallyDisableNavStackIndependentOfModuleFlags() {
        let monitor = EntryMonitor()

        // manuallyDisableNavStack alone is sufficient
        monitor.isCurrentlyInSameModule = false
        monitor.isNavigatingToExternal = false
        monitor.manuallyDisableNavStack = true
        #expect(monitor.shouldSuppressPushNavigation == true)

        // Also true when combined with module flags
        monitor.isCurrentlyInSameModule = true
        monitor.isNavigatingToExternal = true
        #expect(monitor.shouldSuppressPushNavigation == true)
    }

    // MARK: - Destination Monitor Tests

    @Test("DestinationMonitor stores mode and creates entry configs")
    func testDestinationMonitorEntryConfig() {
        let monitor = DestinationMonitor(mode: .sheet)

        #expect(monitor.mode == .sheet)

        let config = monitor.entryConfig(for: TestDestination.home)

        #expect(config.destination == .home)
        #expect(config.monitor.entryMonitor === monitor.entryMonitor)
    }

    @Test("DestinationMonitor disableNavigationStack sets manuallyDisableNavStack")
    func testDestinationMonitorDisableNavigationStack() {
        let monitor = DestinationMonitor(mode: .sheet)

        #expect(monitor.entryMonitor.manuallyDisableNavStack == false)

        monitor.disableNavigationStack()

        #expect(monitor.entryMonitor.manuallyDisableNavStack == true)
        #expect(monitor.entryMonitor.shouldSuppressPushNavigation == true)
    }

    @Test("DestinationMonitor setPreferredDetents stores detents")
    func testDestinationMonitorSetPreferredDetents() {
        let monitor = DestinationMonitor(mode: .sheet)

        #expect(monitor.preferredDetents == nil)

        monitor.setPreferredDetents([.medium, .large])

        #expect(monitor.preferredDetents == [.medium, .large])
    }

    @Test("DestinationMonitor setPreferredDetents overwrites previous detents")
    func testDestinationMonitorSetPreferredDetentsOverwrites() {
        let monitor = DestinationMonitor(mode: .sheet)

        monitor.setPreferredDetents([.medium])
        #expect(monitor.preferredDetents == [.medium])

        monitor.setPreferredDetents([.large])
        #expect(monitor.preferredDetents == [.large])
    }

    @Test("DestinationMonitor disableNavigationStack does not affect preferredDetents")
    func testDisableNavigationStackDoesNotAffectDetents() {
        let monitor = DestinationMonitor(mode: .sheet)

        monitor.setPreferredDetents([.medium])
        monitor.disableNavigationStack()

        #expect(monitor.preferredDetents == [.medium])
        #expect(monitor.entryMonitor.manuallyDisableNavStack == true)
    }

    // MARK: - Module Entry Tests

    @Test("ModuleEntry sets isNavigatingToExternal on creation")
    func testModuleEntryMarksNavigatingToExternal() {
        let monitor = DestinationMonitor(mode: .push)
        let config = monitor.entryConfig(for: TestDestination.settings)

        #expect(monitor.entryMonitor.isNavigatingToExternal == false)

        _ = ModuleEntry(
            configuration: config,
            builder: { _, _, _ in
                EmptyView()
            }
        )

        #expect(monitor.entryMonitor.isNavigatingToExternal == true)
    }

    // MARK: - New Coordinator Monitor Tests

    @Test("newCoordinator sets isCurrentlyInSameModule true for same destination type")
    func testNewCoordinatorSameModuleFlag() {
        let coordinator = NavigationCoordinator<TestDestination>(
            type: .nested(path: nil),
            presentationMode: .root,
            route: [],
            didConsumeRoute: {},
            dismissParent: { false }
        )

        let monitor = DestinationMonitor(mode: .push)
        let _: NavigationCoordinator<TestDestination> = coordinator.newCoordinator(monitor: monitor)

        #expect(monitor.entryMonitor.isCurrentlyInSameModule == true)
    }

    @Test("newCoordinator sets isCurrentlyInSameModule false for different destination type")
    func testNewCoordinatorDifferentModuleFlag() {
        let coordinator = NavigationCoordinator<TestDestination>(
            type: .nested(path: nil),
            presentationMode: .root,
            route: [],
            didConsumeRoute: {},
            dismissParent: { false }
        )

        let monitor = DestinationMonitor(mode: .push)
        let _: NavigationCoordinator<ChildDestination> = coordinator.newCoordinator(monitor: monitor)

        #expect(monitor.entryMonitor.isCurrentlyInSameModule == false)
    }
}
