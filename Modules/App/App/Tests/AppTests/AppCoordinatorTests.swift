//
//  AppCoordinatorTests.swift
//  App
//

import Entities
import Foundation
import Services
import Testing
@testable import App

@Suite
@MainActor
struct AppCoordinatorTests {

    // MARK: - Tests

    @Test
    func aFreshCoordinatorHoldsNoMeet() {
        // Arrange.
        let coordinator = Self.coordinator()

        // Assert.
        // The baseline the two below are read against, without which either of
        // them could pass for having nothing to say.
        #expect(coordinator.stack.isInStack((\AppCoordinator.meet).hashValue) == false)
    }

    @Test
    func startingAMeetPutsItOnTheStack() {
        // Arrange.
        let coordinator = Self.coordinator()

        // Act.
        coordinator.didStartMeet(Self.meet)

        // Assert.
        #expect(coordinator.stack.isInStack((\AppCoordinator.meet).hashValue))
    }

    @Test
    func leavingAMeetTakesItOffTheStack() {
        // Arrange.
        let coordinator = Self.coordinator()
        coordinator.didStartMeet(Self.meet)

        // Act.
        coordinator.didLeaveMeet()

        // Assert.
        // The room is what a person comes back to, so the meeting has to leave
        // the stack rather than sit under whatever is shown next.
        #expect(coordinator.stack.isInStack((\AppCoordinator.meet).hashValue) == false)
    }

    // MARK: - Coordinator

    /// A coordinator wired to the services that speak to nobody, the ones the
    /// module of the services already publishes for a canvas. Nothing here
    /// counts a call, so a second pair of them would say nothing new.
    private static func coordinator() -> AppCoordinator {
        AppCoordinator(
            signalingService: .preview,
            userAuthenticationService: .preview,
            iceURLs: [],
        )
    }

    // MARK: - Meet

    private static var meet: Meet {
        Meet(localPeer: .Preview.local, remotePeer: .Preview.callee)
    }
}
