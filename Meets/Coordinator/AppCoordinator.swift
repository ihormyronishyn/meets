//
//  AppCoordinator.swift
//  Meets
//

import Combine
import Entities
import Login
import Meet
import Room
import Services
import Stinsen
import SwiftUI

@MainActor
final class AppCoordinator: NavigationCoordinatable {

    // MARK: - Properties

    @Root private var login = makeLogin
    @Root private var room = makeRoom
    @Route(.push) private var meet = makeMeet

    var stack = NavigationStack(initial: \AppCoordinator.login)

    /// A meeting builds its own connection, so the addresses of the discovery
    /// servers wait here until a meeting starts.
    private let iceURLs: [String]

    private let signalingService: SignalingServiceProtocol
    private let userAuthenticationService: UserAuthenticationServiceProtocol

    // MARK: - Init

    init(server: Server) {
        iceURLs = server.iceURLs
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

    // MARK: - Factory

    func makeRoom() -> some View {
        let roomViewModel = RoomViewModel(
            signalingService: signalingService,
            userAuthenticationService: userAuthenticationService,
        )
        roomViewModel.router = self
        return RoomView(viewModel: roomViewModel)
    }

    // MARK: - Routing

    func didLeaveRoom() {
        root(\.login)
    }

    func didStartMeet(_ meet: Meet) {
        route(to: \.meet, meet)
    }
}

// MARK: - Meet

extension AppCoordinator: MeetRouting {

    // MARK: - Factory

    func makeMeet(_ meet: Meet) -> some View {
        let meetViewModel = MeetViewModel(
            meet: meet,
            signalingService: signalingService,
            webRTCService: WebRTCService(iceServers: iceURLs),
        )

        meetViewModel.router = self
        return MeetView(viewModel: meetViewModel)
    }

    // MARK: - Routing

    func didLeaveMeet() {
        popLast()
    }
}
