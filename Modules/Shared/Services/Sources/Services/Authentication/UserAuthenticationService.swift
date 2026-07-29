//
//  UserAuthenticationService.swift
//  Services
//

import Foundation

@MainActor
public final class UserAuthenticationService: UserAuthenticationServiceProtocol {

    // MARK: - Properties

    public private(set) var username: String? {
        get { store.string(forKey: Keys.username.rawValue) }
        set { write(newValue, forKey: .username) }
    }

    public private(set) var roomId: Int? {
        get { store.object(forKey: Keys.roomId.rawValue) as? Int }
        set { write(newValue, forKey: .roomId) }
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

    // MARK: - Write

    private func write(_ value: Any?, forKey key: Keys) {
        guard let value else {
            return store.removeObject(forKey: key.rawValue)
        }

        store.set(value, forKey: key.rawValue)
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
