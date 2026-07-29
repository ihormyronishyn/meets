//
//  UserAuthenticationServiceTests.swift
//  Services
//

import Foundation
import Testing
@testable import Services

@MainActor
final class UserAuthenticationServiceTests {

    // MARK: - Properties

    private let name: String
    private let store: UserDefaults

    // MARK: - Setup

    init() throws {
        // Every test owns a suite of its own, so no test observes what another
        // one wrote and the order they run in cannot matter.
        name = UUID().uuidString
        store = try #require(UserDefaults(suiteName: name))
    }

    // MARK: - Teardown

    deinit {
        UserDefaults.standard.removePersistentDomain(forName: name)
    }

    // MARK: - Tests

    @Test
    func emptyStoreIsNotAuthenticated() {
        // Arrange.
        let service = UserAuthenticationService(store: store)

        // Assert.
        #expect(service.isAuthenticated == false)
        #expect(service.username == nil)
        #expect(service.roomId == nil)
    }

    @Test
    func zeroIsValidRoomId() {
        // Arrange.
        let service = UserAuthenticationService(store: store)

        // Act.
        service.login(username: User.john.username, roomId: .zero)

        // Assert.
        #expect(service.isAuthenticated == true)
        #expect(service.roomId == .zero)
    }

    @Test
    func usernameWithoutRoomNotAuthenticated() {
        // Arrange.
        store.set(User.john.username, forKey: "username")
        let service = UserAuthenticationService(store: store)

        // Assert.
        #expect(service.isAuthenticated == false)
        #expect(service.username == User.john.username)
        #expect(service.roomId == nil)
    }

    @Test
    func roomWithoutUsernameNotAuthenticated() {
        // Arrange.
        store.set(User.john.roomId, forKey: "roomId")
        let service = UserAuthenticationService(store: store)

        // Assert.
        #expect(service.isAuthenticated == false)
        #expect(service.username == nil)
        #expect(service.roomId == User.john.roomId)
    }

    @Test
    func loginHoldsCredentials() {
        // Arrange.
        let service = UserAuthenticationService(store: store)

        // Act.
        service.login(username: User.alex.username, roomId: User.alex.roomId)

        // Assert.
        #expect(service.isAuthenticated == true)
        #expect(service.username == User.alex.username)
        #expect(service.roomId == User.alex.roomId)
    }

    @Test
    func repeatedLoginReplacesCredentials() {
        // Arrange.
        let service = UserAuthenticationService(store: store)
        service.login(username: User.john.username, roomId: User.john.roomId)

        // Act.
        service.login(username: User.alex.username, roomId: User.alex.roomId)

        // Assert.
        #expect(service.isAuthenticated == true)
        #expect(service.username == User.alex.username)
        #expect(service.roomId == User.alex.roomId)
    }

    @Test
    func logoutDropsCredentials() {
        // Arrange.
        let service = UserAuthenticationService(store: store)
        service.login(username: User.john.username, roomId: User.john.roomId)

        // Act.
        service.logout()

        // Assert.
        #expect(service.isAuthenticated == false)
        #expect(service.username == nil)
        #expect(service.roomId == nil)
    }

    @Test
    func logoutLeavesNoKeyInTheStore() {
        // Arrange.
        let service = UserAuthenticationService(store: store)
        service.login(username: User.john.username, roomId: User.john.roomId)

        // Act.
        service.logout()

        // Assert.
        #expect(store.object(forKey: "username") == nil)
        #expect(store.object(forKey: "roomId") == nil)
    }

    @Test
    func loginCarriesAcrossInstances() {
        // Arrange.
        let service = UserAuthenticationService(store: store)

        // Act.
        service.login(username: User.john.username, roomId: User.john.roomId)
        let restored = UserAuthenticationService(store: store)

        // Assert.
        #expect(restored.isAuthenticated == true)
        #expect(restored.username == User.john.username)
        #expect(restored.roomId == User.john.roomId)
    }

    @Test
    func logoutCarriesAcrossInstances() {
        // Arrange.
        let service = UserAuthenticationService(store: store)
        service.login(username: User.john.username, roomId: User.john.roomId)

        // Act.
        service.logout()
        let restored = UserAuthenticationService(store: store)

        // Assert.
        #expect(restored.isAuthenticated == false)
        #expect(restored.username == nil)
        #expect(restored.roomId == nil)
    }
}

// MARK: - User

private extension UserAuthenticationServiceTests {

    struct User {

        // MARK: - Properties

        let username: String
        let roomId: Int

        // MARK: - Fixtures

        static let john = User(username: "John", roomId: 1)
        static let alex = User(username: "Alex", roomId: 2)
    }
}
