//
//  AppCoordinator.swift
//  Meets
//

import Combine
import Login
import Services
import Stinsen
import SwiftUI

@MainActor
final class AppCoordinator: NavigationCoordinatable {

    // MARK: - Properties

    @Root private var login = makeLogin

    var stack = NavigationStack(initial: \AppCoordinator.login)

    private let userAuthenticationService: UserAuthenticationServiceProtocol

    // MARK: - Init

    init() {
        userAuthenticationService = UserAuthenticationService()

        if userAuthenticationService.isAuthenticated {
            // Set room as initial screen in navigation stack.
        }
    }
}

// MARK: - Login

extension AppCoordinator: LoginRouting {

    // MARK: - Factory

    func makeLogin() -> some View {
        let loginViewModel = LoginViewModel(userAuthenticationService: userAuthenticationService)
        loginViewModel.router = self
        return LoginView(viewModel: loginViewModel)
    }

    // MARK: - Routing

    func didLogin() {
        // Push room screen.
    }
}
