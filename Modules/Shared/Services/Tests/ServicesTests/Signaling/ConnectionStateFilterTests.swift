//
//  ConnectionStateFilterTests.swift
//  Services
//

import Foundation
import Testing
@testable import Services

@Suite
struct ConnectionStateFilterTests {

    // MARK: - Tests

    @Test
    func passesAnOrdinaryDisconnection() {
        // Arrange.
        var filter = ConnectionStateFilter()
        _ = filter.allows(.connected)

        // Act.
        let allowed = filter.allows(.disconnected)

        // Assert.
        #expect(allowed)
    }

    @Test
    func passesARefusal() {
        // Arrange.
        var filter = ConnectionStateFilter()
        _ = filter.allows(.connecting)

        // Act.
        let allowed = filter.allows(.roomIsFull)

        // Assert.
        #expect(allowed)
    }

    @Test
    func swallowsTheDisconnectionCausedByARefusal() {
        // Arrange.
        // The server announces the refusal and closes the socket at once, so
        // the disconnection arrives last and would leave a reader with a state
        // that says nothing about why the room was not reached.
        var filter = ConnectionStateFilter()
        _ = filter.allows(.roomIsFull)

        // Act.
        let allowed = filter.allows(.disconnected)

        // Assert.
        #expect(allowed == false)
    }

    @Test
    func swallowsOnlyTheFirstDisconnectionAfterARefusal() {
        // Arrange.
        var filter = ConnectionStateFilter()
        _ = filter.allows(.roomIsFull)
        _ = filter.allows(.disconnected)

        // Act.
        let allowed = filter.allows(.disconnected)

        // Assert.
        // The next one belongs to a later connection and means what it says.
        #expect(allowed)
    }

    @Test
    func forgetsARefusalOnceSomethingElseHappens() {
        // Arrange.
        // Trying again reaches the server before it reaches the room, so the
        // disconnection that ends that attempt is an ordinary one.
        var filter = ConnectionStateFilter()
        _ = filter.allows(.roomIsFull)
        _ = filter.allows(.connecting)

        // Act.
        let allowed = filter.allows(.disconnected)

        // Assert.
        #expect(allowed)
    }
}
