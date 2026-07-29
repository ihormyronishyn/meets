//
//  LoginViewModelTests.swift
//  Login
//

import Foundation
import Services
import Testing
@testable import Login

@MainActor
final class LoginViewModelTests {

    // MARK: - Properties

    private let userAuthenticationService: UserAuthenticationServiceSpy
    private let router: LoginRoutingSpy
    private let viewModel: LoginViewModel

    // MARK: - Setup

    init() {
        // The view model keeps the router weakly, so the suite is what holds
        // it alive for the length of a test.
        userAuthenticationService = UserAuthenticationServiceSpy()
        router = LoginRoutingSpy()
        viewModel = LoginViewModel(userAuthenticationService: userAuthenticationService)
        viewModel.router = router
    }

    // MARK: - Tests

    @Test
    func `empty fields are not allowed`() {
        // Assert
        #expect(viewModel.isLoginAllowed == false)
    }

    @Test
    func `blank username is not allowed`() {
        // Act
        viewModel.usernameText = "   "
        viewModel.roomIdText = "1"

        // Assert
        #expect(viewModel.isLoginAllowed == false)
    }

    @Test
    func `room that is not A number is refused`() {
        // Act
        viewModel.usernameText = "John"
        viewModel.roomIdText = "Seven"

        // Assert
        #expect(viewModel.isLoginAllowed == false)
    }

    @Test
    func `negative room is refused`() {
        // Act
        viewModel.usernameText = "John"
        viewModel.roomIdText = "-5"

        // Assert
        #expect(viewModel.isLoginAllowed == false)
    }

    @Test
    func `zero room is allowed`() {
        // Act
        viewModel.usernameText = "John"
        viewModel.roomIdText = "0"

        // Assert
        #expect(viewModel.isLoginAllowed == true)
    }

    @Test
    func `filled fields are allowed`() {
        // Act
        viewModel.usernameText = "John"
        viewModel.roomIdText = "1"

        // Assert
        #expect(viewModel.isLoginAllowed == true)
    }

    @Test
    func `login hands the credentials over`() {
        // Arrange
        viewModel.usernameText = "Alex"
        viewModel.roomIdText = "2"

        // Act
        viewModel.login()

        // Assert
        #expect(userAuthenticationService.loginCallCount == 1)
        #expect(userAuthenticationService.username == "Alex")
        #expect(userAuthenticationService.roomId == 2)
    }

    @Test
    func `login trims the username`() {
        // Arrange
        viewModel.usernameText = "  John  "
        viewModel.roomIdText = "1"

        // Act
        viewModel.login()

        // Assert
        #expect(userAuthenticationService.username == "John")
    }

    @Test
    func `login tells the router`() {
        // Arrange
        viewModel.usernameText = "John"
        viewModel.roomIdText = "1"

        // Act
        viewModel.login()

        // Assert
        #expect(router.didLoginCallCount == 1)
    }

    @Test
    func `login does nothing when not allowed`() {
        // Arrange
        viewModel.usernameText = "John"
        viewModel.roomIdText = "Seven"

        // Act
        viewModel.login()

        // Assert
        #expect(userAuthenticationService.loginCallCount == .zero)
        #expect(router.didLoginCallCount == .zero)
    }
}

// MARK: - User Authentication Service Spy

@MainActor
private final class UserAuthenticationServiceSpy: UserAuthenticationServiceProtocol {

    // MARK: - Properties

    private(set) var username: String?
    private(set) var roomId: Int?
    private(set) var loginCallCount: Int = .zero
    private(set) var logoutCallCount: Int = .zero

    var isAuthenticated: Bool {
        username != nil && roomId != nil
    }

    // MARK: - Methods

    func login(username: String, roomId: Int) {
        self.username = username
        self.roomId = roomId
        loginCallCount += 1
    }

    func logout() {
        username = nil
        roomId = nil
        logoutCallCount += 1
    }
}

// MARK: - Login Routing Spy

private final class LoginRoutingSpy: LoginRouting {

    // MARK: - Properties

    private(set) var didLoginCallCount: Int = .zero

    // MARK: - Methods

    func didLogin() {
        didLoginCallCount += 1
    }
}
