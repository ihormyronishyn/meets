//
//  AppCoordinator.swift
//  Meets
//

import Combine
import Entities
import Login
import Room
import Services
import Stinsen
import SwiftUI

@MainActor
final class AppCoordinator: NavigationCoordinatable {

    // MARK: - Properties

    @Root private var login = makeLogin
    @Root private var room = makeRoom

    var stack = NavigationStack(initial: \AppCoordinator.login)

    private let signalingService: SignalingServiceProtocol
    private let userAuthenticationService: UserAuthenticationServiceProtocol

    // MARK: - Init

    init(server: Server) {
        signalingService = SignalingService(url: server.signalingURL)
        userAuthenticationService = UserAuthenticationService()

        if userAuthenticationService.isAuthenticated {
            stack = NavigationStack(initial: \AppCoordinator.room)
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
        root(\.room)
    }
}

// MARK: - Room

extension AppCoordinator: RoomRouting {
    func makeRoom() -> some View {
        let roomViewModel = RoomViewModel(
            signalingService: signalingService,
            userAuthenticationService: userAuthenticationService,
        )
        roomViewModel.router = self
        return RoomView(viewModel: roomViewModel)
    }

    func didLeaveRoom() {
        root(\.login)
    }

    func didStartMeet(_ meet: Meet) {
        // Push meet screen.
    }
}
