//
//  NavigationCoordinatorTests.swift
//  HatchModularNavigationTests
//
//  Created by Stephane Magne on 2025-11-06.
//  Copyright hatch.co, 2025.
//

@testable import HatchModularNavigation
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
            dismissParent: { false }
        )
        
        // Parent consumes first segment
        #expect(parentCoordinator.deepLinkRoute.initialSteps.count == 1)
        #expect(parentCoordinator.deepLinkRoute.handoffRoute.count == 1)
        
        // Create child coordinator
        let childCoordinator: NavigationCoordinator<ChildDestination> = parentCoordinator.newCoordinator(mode: .push)
        
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
            dismissParent: { false }
        )
        
        let coordinator2 = NavigationCoordinator<TestDestination>(
            type: .root,
            presentationMode: .root,
            route: [],
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
            dismissParent: { false }
        )
        
        coordinator.rootPath = pathBinding
    
        let childCoordinator: NavigationCoordinator<ChildDestination> = coordinator.newCoordinator(mode: .push)
        
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
            dismissParent: { false }
        )
        
        let childCoordinator: NavigationCoordinator<ChildDestination> = coordinator.newCoordinator(mode: .push)
        
        #expect(path.isEmpty)

        coordinator.present(.home, mode: .push)

        #expect(path.count == 1)

        childCoordinator.present(.childDetail, mode: .push)

        #expect(path.count == 2)
    }
}
