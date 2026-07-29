//
//  UserAuthenticationServiceProtocol.swift
//  Services
//

import Foundation

@MainActor
public protocol UserAuthenticationServiceProtocol {

    // MARK: - Properties

    var username: String? { get }
    var roomId: Int? { get }
    var isAuthenticated: Bool { get }

    // MARK: - Methods

    func login(username: String, roomId: Int)
    func logout()
}
