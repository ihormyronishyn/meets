//
//  LoginViewModel.swift
//  Login
//

import Foundation
import Observation
import Services

@MainActor
@Observable
public final class LoginViewModel {

    // MARK: - Properties

    var usernameText: String = ""
    var roomIdText: String = ""

    private var username: String {
        usernameText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var roomId: Int? {
        guard let roomId = Int(roomIdText), roomId >= .zero else { return nil }
        return roomId
    }

    var isLoginAllowed: Bool {
        !username.isEmpty && roomId != nil
    }

    @ObservationIgnored public weak var router: LoginRouting?

    private let userAuthenticationService: UserAuthenticationServiceProtocol

    // MARK: - Init

    public init(userAuthenticationService: UserAuthenticationServiceProtocol) {
        self.userAuthenticationService = userAuthenticationService
    }

    // MARK: - Login

    func login() {
        guard isLoginAllowed, let roomId else { return }
        userAuthenticationService.login(username: username, roomId: roomId)
        router?.didLogin()
    }
}
