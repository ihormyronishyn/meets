//
//  Peer.swift
//  Entities
//

import Foundation

public struct Peer: Identifiable, Codable, Equatable, Sendable {

    // MARK: - Properties

    /// Peers are keyed by username throughout the signaling protocol,
    /// so username is the stable identity across decodes.
    public var id: String {
        username
    }

    public let roomId: Int?
    public let username: String
    public let isCaller: Bool?
    public var isCalling: Bool?

    // MARK: - Init

    public init(roomId: Int?, username: String, isCaller: Bool?) {
        self.roomId = roomId
        self.username = username
        self.isCaller = isCaller
    }

    // MARK: - Keys

    enum CodingKeys: String, CodingKey {
        case roomId, username, isCaller
    }
}

// MARK: - Preview

public extension Peer {
    static let preview = Peer(roomId: 1, username: "Jacob", isCaller: true)
}
