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
    func `empty store is not authenticated`() {
        // Arrange
        let service = UserAuthenticationService(store: store)

        // Assert
        #expect(service.isAuthenticated == false)
        #expect(service.username == nil)
        #expect(service.roomId == nil)
    }

    @Test
    func `zero is valid room id`() {
        // Arrange
        let service = UserAuthenticationService(store: store)

        // Act
        service.login(username: User.john.username, roomId: .zero)

        // Assert
        #expect(service.isAuthenticated == true)
        #expect(service.roomId == .zero)
    }

    @Test
    func `username without room not authenticated`() {
        // Arrange
        store.set(User.john.username, forKey: "username")
        let service = UserAuthenticationService(store: store)

        // Assert
        #expect(service.isAuthenticated == false)
        #expect(service.username == User.john.username)
        #expect(service.roomId == nil)
    }

    @Test
    func `room without username not authenticated`() {
        // Arrange
        store.set(User.john.roomId, forKey: "roomId")
        let service = UserAuthenticationService(store: store)

        // Assert
        #expect(service.isAuthenticated == false)
        #expect(service.username == nil)
        #expect(service.roomId == User.john.roomId)
    }

    @Test
    func `login holds credentials`() {
        // Arrange
        let service = UserAuthenticationService(store: store)

        // Act
        service.login(username: User.alex.username, roomId: User.alex.roomId)

        // Assert
        #expect(service.isAuthenticated == true)
        #expect(service.username == User.alex.username)
        #expect(service.roomId == User.alex.roomId)
    }

    @Test
    func `repeated login replaces credentials`() {
        // Arrange
        let service = UserAuthenticationService(store: store)
        service.login(username: User.john.username, roomId: User.john.roomId)

        // Act
        service.login(username: User.alex.username, roomId: User.alex.roomId)

        // Assert
        #expect(service.isAuthenticated == true)
        #expect(service.username == User.alex.username)
        #expect(service.roomId == User.alex.roomId)
    }

    @Test
    func `logout drops credentials`() {
        // Arrange
        let service = UserAuthenticationService(store: store)
        service.login(username: User.john.username, roomId: User.john.roomId)

        // Act
        service.logout()

        // Assert
        #expect(service.isAuthenticated == false)
        #expect(service.username == nil)
        #expect(service.roomId == nil)
    }

    @Test
    func `logout leaves no key in the store`() {
        // Arrange
        let service = UserAuthenticationService(store: store)
        service.login(username: User.john.username, roomId: User.john.roomId)

        // Act
        service.logout()

        // Assert
        #expect(store.object(forKey: "username") == nil)
        #expect(store.object(forKey: "roomId") == nil)
    }

    @Test
    func `login carries across instances`() {
        // Arrange
        let service = UserAuthenticationService(store: store)

        // Act
        service.login(username: User.john.username, roomId: User.john.roomId)
        let restored = UserAuthenticationService(store: store)

        // Assert
        #expect(restored.isAuthenticated == true)
        #expect(restored.username == User.john.username)
        #expect(restored.roomId == User.john.roomId)
    }

    @Test
    func `logout carries across instances`() {
        // Arrange
        let service = UserAuthenticationService(store: store)
        service.login(username: User.john.username, roomId: User.john.roomId)

        // Act
        service.logout()
        let restored = UserAuthenticationService(store: store)

        // Assert
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
