//
//  UserAuthenticationService.swift
//  Services
//

import Foundation
import Utilities

@MainActor
public final class UserAuthenticationService: UserAuthenticationServiceProtocol {

    // MARK: - Properties

    public private(set) var username: String? {
        get { store.string(forKey: Keys.username.rawValue) }
        set { store.write(newValue, forKey: Keys.username.rawValue) }
    }

    public private(set) var roomId: Int? {
        get { store.object(forKey: Keys.roomId.rawValue) as? Int }
        set { store.write(newValue, forKey: Keys.roomId.rawValue) }
    }

    public var isAuthenticated: Bool {
        username != nil && roomId != nil
    }

    private let store: UserDefaults

    // MARK: - Init

    public init(store: UserDefaults = .standard) {
        self.store = store
    }

    // MARK: - Login

    public func login(username: String, roomId: Int) {
        self.username = username
        self.roomId = roomId
    }

    // MARK: - Logout

    public func logout() {
        username = nil
        roomId = nil
    }
}

// MARK: - Extension

extension UserAuthenticationService {

    // MARK: - Keys

    private enum Keys: String {
        case username
        case roomId
    }
}
